import { describe, expect, it } from 'vitest';
import { buatApp } from '../src/app.js';
import type { Config } from '../src/config.js';
import { fakeLlm, panggil, teks } from './fakeLlm.js';

const cfg: Config = { port: 0, host: '127.0.0.1', geminiApiKey: '', geminiModel: 'test', geminiFallbackModels: [], appKey: '', rateLimitPerMinute: 100 };
const body = { pesan: [{ role: 'user', text: 'wisata alam murah di Karo?' }] };

function parseSse(payload: string) {
  return payload
    .split('\n\n')
    .filter((b) => b.startsWith('data: '))
    .map((b) => JSON.parse(b.slice(6)));
}

describe('POST /api/chat', () => {
  it('menyiarkan SSE: delta, event destinasi, done', async () => {
    const llm = fakeLlm([panggil('cari_destinasi', { lokasi: 'berastagi', limit: 1 })], [teks('Coba Berastagi.')]);
    const app = await buatApp(cfg, llm);
    const res = await app.inject({ method: 'POST', url: '/api/chat', payload: body });
    expect(res.statusCode).toBe(200);
    expect(res.headers['content-type']).toContain('text/event-stream');
    expect(parseSse(res.payload)).toEqual([
      { type: 'destinasi', ids: ['d03'] },
      { type: 'delta', text: 'Coba Berastagi.' },
      { type: 'done' },
    ]);
  });

  it('riwayat dipangkas: dimulai dari giliran user dan maksimal 12', async () => {
    const llm = fakeLlm([teks('ok')]);
    const app = await buatApp(cfg, llm);
    const pesan = Array.from({ length: 30 }, (_, i) => ({ role: i % 2 === 0 ? 'user' : 'model', text: `p${i}` }));
    pesan.push({ role: 'user', text: 'terakhir' });
    await app.inject({ method: 'POST', url: '/api/chat', payload: { pesan } });
    const kirim = llm.permintaan[0]!.contents;
    expect(kirim.length).toBeLessThanOrEqual(12);
    expect(kirim[0]!.role).toBe('user');
    expect(kirim.at(-1)!.parts![0]!.text).toBe('terakhir');
  });

  it('400 untuk body tidak valid dan pesan terakhir dari model', async () => {
    const app = await buatApp(cfg, fakeLlm([teks('x')]));
    expect((await app.inject({ method: 'POST', url: '/api/chat', payload: {} })).statusCode).toBe(400);
    expect((await app.inject({ method: 'POST', url: '/api/chat', payload: { pesan: [{ role: 'user', text: 'a' }, { role: 'model', text: 'b' }] } })).statusCode).toBe(400);
    expect((await app.inject({ method: 'POST', url: '/api/chat', payload: { pesan: [{ role: 'user', text: 'x'.repeat(2001) }] } })).statusCode).toBe(400);
  });

  it('503 jika API key belum diisi, tetapi /health tetap hidup', async () => {
    const app = await buatApp(cfg);
    expect((await app.inject({ method: 'POST', url: '/api/chat', payload: body })).statusCode).toBe(503);
    const h = await app.inject({ method: 'GET', url: '/health' });
    expect(h.json()).toMatchObject({ status: 'ok', asisten: 'belum-dikonfigurasi' });
  });

  it('x-app-key diwajibkan bila APP_KEY diset', async () => {
    const app = await buatApp({ ...cfg, appKey: 'rahasia' }, fakeLlm([teks('ok')]));
    expect((await app.inject({ method: 'POST', url: '/api/chat', payload: body })).statusCode).toBe(401);
    expect((await app.inject({ method: 'POST', url: '/api/chat', payload: body, headers: { 'x-app-key': 'salah' } })).statusCode).toBe(401);
    expect((await app.inject({ method: 'POST', url: '/api/chat', payload: body, headers: { 'x-app-key': 'rahasia' } })).statusCode).toBe(200);
  });

  it('rate limit per IP -> 429 dengan pesan Indonesia', async () => {
    const app = await buatApp({ ...cfg, rateLimitPerMinute: 2 }, fakeLlm([teks('ok')]));
    const kirim = () => app.inject({ method: 'POST', url: '/api/chat', payload: body });
    expect((await kirim()).statusCode).toBe(200);
    expect((await kirim()).statusCode).toBe(200);
    const res = await kirim();
    expect(res.statusCode).toBe(429);
    expect(res.json().error).toMatch(/Terlalu banyak permintaan/);
  });
});
