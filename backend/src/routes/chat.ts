import { timingSafeEqual } from 'node:crypto';
import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { jalankanChat, type EventSse } from '../ai/chat.js';
import type { LlmClient } from '../ai/llm.js';
import type { Config } from '../config.js';

const MAKS_RIWAYAT = 12;

const bodySchema = z.object({
  pesan: z
    .array(
      z.object({
        role: z.enum(['user', 'model']),
        text: z.string().trim().min(1).max(2000),
      }),
    )
    .min(1)
    .max(60),
  konteks: z
    .object({
      hariIni: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
      favoritIds: z.array(z.string().max(20)).max(60).default([]),
      // Posisi kasar pengguna (app membulatkan 2 desimal). Opsional: hanya bila lokasi diizinkan.
      posisi: z.object({ lat: z.number().min(-90).max(90), lng: z.number().min(-180).max(180) }).optional(),
      rencana: z
        .array(
          z.object({
            judul: z.string().max(200),
            tanggalMulai: z.string().max(40).optional(),
            tanggalSelesai: z.string().max(40).optional(),
            destinasiIds: z.array(z.string().max(20)).max(40).default([]),
          }),
        )
        .max(10)
        .default([]),
    })
    .optional(),
});

function sama(a: string, b: string): boolean {
  const ba = Buffer.from(a);
  const bb = Buffer.from(b);
  return ba.length === bb.length && timingSafeEqual(ba, bb);
}

function hariIniWib(): string {
  // Tanggal di zona waktu Sumatera Utara (WIB, UTC+7).
  return new Date(Date.now() + 7 * 3600_000).toISOString().slice(0, 10);
}

export function registerChatRoute(
  app: FastifyInstance,
  cfg: Config,
  llm: LlmClient | undefined,
  modelChain: string[] = [],
): void {
  app.post(
    '/api/chat',
    { config: { rateLimit: { max: cfg.rateLimitPerMinute, timeWindow: '1 minute' } } },
    async (req, reply) => {
      if (cfg.appKey) {
        const kunci = req.headers['x-app-key'];
        if (typeof kunci !== 'string' || !sama(kunci, cfg.appKey)) {
          return reply.code(401).send({ error: 'Tidak diizinkan.' });
        }
      }
      if (!llm) {
        return reply.code(503).send({ error: 'Tripy belum dikonfigurasi di server (GEMINI_API_KEY kosong).' });
      }

      const parsed = bodySchema.safeParse(req.body);
      if (!parsed.success) {
        return reply.code(400).send({ error: 'Permintaan tidak valid.', detail: parsed.error.issues.map((i) => i.message) });
      }

      // Ambil riwayat terakhir; Gemini harus diawali giliran user dan diakhiri user.
      let pesan = parsed.data.pesan.slice(-MAKS_RIWAYAT);
      while (pesan.length > 0 && pesan[0]!.role !== 'user') pesan = pesan.slice(1);
      if (pesan.length === 0 || pesan[pesan.length - 1]!.role !== 'user') {
        return reply.code(400).send({ error: 'Pesan terakhir harus dari pengguna.' });
      }

      const konteks = {
        hariIni: parsed.data.konteks?.hariIni ?? hariIniWib(),
        favoritIds: parsed.data.konteks?.favoritIds ?? [],
        posisi: parsed.data.konteks?.posisi,
        rencana: parsed.data.konteks?.rencana ?? [],
      };

      reply.hijack();
      const raw = reply.raw;
      raw.writeHead(200, {
        'Content-Type': 'text/event-stream; charset=utf-8',
        'Cache-Control': 'no-cache, no-transform',
        Connection: 'keep-alive',
        'X-Accel-Buffering': 'no',
      });

      const ac = new AbortController();
      raw.on('close', () => {
        if (!raw.writableFinished) ac.abort();
      });
      const detak = setInterval(() => {
        if (!raw.destroyed) raw.write(': ping\n\n');
      }, 15_000);

      const emit = (e: EventSse) => {
        if (!raw.destroyed && !raw.writableEnded) raw.write(`data: ${JSON.stringify(e)}\n\n`);
      };

      try {
        await jalankanChat({
          llm,
          pesan,
          konteks,
          emit,
          signal: ac.signal,
          modelChain,
          log: (msg, err) => req.log.warn({ err }, msg),
        });
      } finally {
        clearInterval(detak);
        if (!raw.writableEnded) raw.end();
      }
    },
  );
}
