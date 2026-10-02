import type { LlmClient, PermintaanLlm, StreamChunk } from '../src/ai/llm.js';

type Langkah = StreamChunk[] | Error;

/** Model palsu: tiap panggilan stream() memakai satu langkah dari skrip. */
export function fakeLlm(...skrip: Langkah[]): LlmClient & { permintaan: PermintaanLlm[] } {
  const permintaan: PermintaanLlm[] = [];
  let i = 0;
  return {
    permintaan,
    stream(req) {
      // Salin supaya mutasi `contents` oleh pemanggil tidak mengubah catatan.
      permintaan.push({ ...req, contents: structuredClone(req.contents) });
      const langkah = skrip[Math.min(i++, skrip.length - 1)];
      return (async function* () {
        if (langkah instanceof Error) throw langkah;
        for (const chunk of langkah ?? []) yield chunk;
      })();
    },
  };
}

export const teks = (text: string): StreamChunk => ({ parts: [{ text }] });
export const panggil = (name: string, args: Record<string, unknown>, id = 'fc1'): StreamChunk => ({
  parts: [{ functionCall: { name, args, id } }],
});

export function errorStatus(status: number): Error {
  return Object.assign(new Error(`status ${status}`), { status });
}
