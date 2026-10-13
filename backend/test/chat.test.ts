import { beforeEach, describe, expect, it, vi } from 'vitest';
import { jalankanChat, resetKuotaModel, type EventSse } from '../src/ai/chat.js';
import { errorStatus, fakeLlm, panggil, teks } from './fakeLlm.js';

const konteks = { hariIni: '2026-10-02', favoritIds: ['d01'], rencana: [] };
const pesan = [{ role: 'user' as const, text: 'halo' }];

async function jalan(llm: ReturnType<typeof fakeLlm>, extra: Partial<Parameters<typeof jalankanChat>[0]> = {}) {
  const events: EventSse[] = [];
  const statuses: string[] = []; // event 'status' dipisah agar asersi urutan event lain tetap ringkas
  const tidur = vi.fn(async (_ms: number) => {});
  await jalankanChat({
    llm,
    pesan,
    konteks,
    emit: (e) => (e.type === 'status' ? statuses.push(e.text) : events.push(e)),
    tidur,
    ...extra,
  });
  return { events, statuses, tidur };
}

describe('jalankanChat', () => {
  beforeEach(() => resetKuotaModel());

  it('mengirim status Tripy saat tool berjalan dan saat menyusun jawaban', async () => {
    const llm = fakeLlm(
      [panggil('cari_destinasi', { kategori: 'Pantai', lokasi: 'Serdang Bedagai' }, 'a')],
      [teks('Ini pilihan pantai.')],
    );
    const { statuses } = await jalan(llm);
    expect(statuses).toEqual(['Tripy lagi nyari tempat…', 'Nyusun jawaban…']);
  });

  it('mengirim status antre sebelum mengulang karena limit', async () => {
    const { statuses } = await jalan(fakeLlm(errorStatus(429), [teks('berhasil')]));
    expect(statuses).toEqual(['Tripy lagi antre, nyoba lagi…']);
  });

  it('tanpa tool tidak ada status (indikator awal dibuat di app)', async () => {
    const { statuses } = await jalan(fakeLlm([teks('Halo')]));
    expect(statuses).toEqual([]);
  });

  it('menyiarkan teks bertahap lalu done', async () => {
    const { events } = await jalan(fakeLlm([teks('Halo '), teks('Traveler!')]));
    expect(events).toEqual([
      { type: 'delta', text: 'Halo ' },
      { type: 'delta', text: 'Traveler!' },
      { type: 'done' },
    ]);
  });

  it('system prompt memuat konteks pengguna dan aturan', async () => {
    const llm = fakeLlm([teks('ok')]);
    await jalan(llm);
    const sp = llm.permintaan[0]!.systemInstruction;
    expect(sp).toContain('Tripy');
    expect(sp).toContain('2026-10-02');
    expect(sp).toContain('Danau Toba'); // favorit dipetakan ke nama
  });

  it('loop function calling: tool dijalankan, hasil dikirim balik, kartu diteruskan', async () => {
    const llm = fakeLlm(
      [panggil('cari_destinasi', { kategori: 'Pantai', lokasi: 'Serdang Bedagai' }, 'a')],
      [teks('Ini pilihan pantai.')],
    );
    const { events } = await jalan(llm);

    expect(events).toEqual([
      { type: 'destinasi', ids: ['d12', 'd17'] },
      { type: 'delta', text: 'Ini pilihan pantai.' },
      { type: 'done' },
    ]);

    const req2 = llm.permintaan[1]!.contents;
    expect(req2.map((c) => c.role)).toEqual(['user', 'model', 'user']);
    expect(req2[1]!.parts![0]!.functionCall!.name).toBe('cari_destinasi');
    const fr = req2[2]!.parts![0]!.functionResponse!;
    expect(fr.id).toBe('a');
    expect(JSON.stringify(fr.response)).toContain('Pantai Cermin');
  });

  it('hemat kuota: teks + usulkan_rencana di putaran yang sama -> selesai tanpa panggilan model tambahan', async () => {
    const llm = fakeLlm(
      [panggil('cari_destinasi', { lokasi: 'toba', tampilkan: false }, 'a')],
      [teks('Hari 1 Toba, hari 2 Tomok.'), panggil('usulkan_rencana', { judul: 'Toba', destinasiIds: ['d01', 'd08'], jumlahHari: 2 }, 'b')],
      [teks('INI TIDAK BOLEH DIPANGGIL')],
    );
    const { events } = await jalan(llm);
    expect(llm.permintaan).toHaveLength(2);
    expect(events.map((e) => e.type)).toEqual(['delta', 'rencana', 'done']);
  });

  it('usulkan_rencana tanpa teks dulu tetap melanjutkan agar model menulis jawaban', async () => {
    const llm = fakeLlm(
      [panggil('usulkan_rencana', { judul: 'Toba', destinasiIds: ['d01'] }, 'b')],
      [teks('Ini draf rencananya.')],
    );
    const { events } = await jalan(llm);
    expect(llm.permintaan).toHaveLength(2);
    expect(events.map((e) => e.type)).toEqual(['rencana', 'delta', 'done']);
  });

  it('thought signature pada part model dikembalikan apa adanya', async () => {
    const llm = fakeLlm(
      [{ parts: [{ functionCall: { name: 'daftar_kategori', args: {}, id: 'x' }, thoughtSignature: 'SIG123' }] }],
      [teks('selesai')],
    );
    await jalan(llm);
    expect(llm.permintaan[1]!.contents[1]!.parts![0]!.thoughtSignature).toBe('SIG123');
  });

  it('part thought tidak disiarkan ke pengguna', async () => {
    const { events } = await jalan(fakeLlm([{ parts: [{ text: 'mikir...', thought: true }, { text: 'Jawaban' }] }]));
    expect(events).toEqual([{ type: 'delta', text: 'Jawaban' }, { type: 'done' }]);
  });

  it('tool tidak dikenal tidak menjatuhkan loop', async () => {
    const llm = fakeLlm([panggil('hapus_semua', {})], [teks('maaf')]);
    const { events } = await jalan(llm);
    expect(events.at(-1)).toEqual({ type: 'done' });
    expect(JSON.stringify(llm.permintaan[1]!.contents[2])).toContain('tidak dikenal');
  });

  it('429 sebelum ada output diulang dengan backoff lalu berhasil', async () => {
    const { events, tidur } = await jalan(fakeLlm(errorStatus(429), [teks('berhasil')]));
    expect(tidur).toHaveBeenCalledTimes(1);
    expect(events).toEqual([{ type: 'delta', text: 'berhasil' }, { type: 'done' }]);
  });

  it('429 terus-menerus -> event error ramah setelah 3 percobaan', async () => {
    const llm = fakeLlm(errorStatus(429));
    const { events, tidur } = await jalan(llm);
    expect(llm.permintaan).toHaveLength(3);
    expect(tidur).toHaveBeenCalledTimes(2);
    expect(events).toHaveLength(1);
    expect(events[0]).toMatchObject({ type: 'error' });
    expect((events[0] as { message: string }).message).toMatch(/sibuk/);
  });

  it('error lain (mis. 500) tidak diulang dan pesannya tidak membocorkan detail', async () => {
    const log = vi.fn();
    const llm = fakeLlm(errorStatus(500));
    const { events } = await jalan(llm, { log });
    expect(llm.permintaan).toHaveLength(1);
    expect(events).toEqual([{ type: 'error', message: expect.not.stringContaining('status 500') }]);
    expect(log).toHaveBeenCalled();
  });

  it('teks menjanjikan kartu rencana tapi tool tidak dipanggil -> ditegur sekali dan kartu muncul', async () => {
    const llm = fakeLlm(
      [panggil('cari_destinasi', { lokasi: 'medan', tampilkan: false }, 'a')],
      [teks('Rencana 1 hari. Tekan tombol **Simpan** pada kartu di bawah ini.')],
      [panggil('usulkan_rencana', { judul: 'Medan', destinasiIds: ['d05', 'd09'] }, 'b')],
    );
    const { events } = await jalan(llm);

    expect(llm.permintaan).toHaveLength(3);
    const tegur = llm.permintaan[2]!.contents.at(-1)!;
    expect(tegur.role).toBe('user');
    expect(tegur.parts![0]!.text).toContain('usulkan_rencana belum dipanggil');
    // Hanya putaran teguran yang memaksa pemanggilan tool.
    expect(llm.permintaan.map((r) => r.paksaTool)).toEqual([undefined, undefined, 'usulkan_rencana']);
    expect(events.map((e) => e.type)).toEqual(['delta', 'rencana', 'done']);
  });

  it('itinerary tanpa menyebut kartu: niat pengguna + bentuk jawaban cukup untuk memicu teguran', async () => {
    const llm = fakeLlm(
      [teks('Hari 1: Pagi: Museum Negeri. Siang: Istana Maimun.')],
      [panggil('usulkan_rencana', { judul: 'Medan', destinasiIds: ['d09', 'd05'] }, 'b')],
    );
    const { events } = await jalan(llm, { pesan: [{ role: 'user', text: 'Susun itinerary 1 hari di Medan' }] });
    expect(llm.permintaan.map((r) => r.paksaTool)).toEqual([undefined, 'usulkan_rencana']);
    expect(events.map((e) => e.type)).toEqual(['delta', 'rencana', 'done']);
  });

  it('pertanyaan cara pakai app yang menyebut "rencana" tidak memicu kartu rencana', async () => {
    const llm = fakeLlm([teks('Buka Profil lalu pilih Rencana Perjalanan Saya, geser kartu ke kiri untuk menghapus.')]);
    const { events } = await jalan(llm, { pesan: [{ role: 'user', text: 'Cara hapus rencana perjalanan gimana?' }] });
    expect(llm.permintaan).toHaveLength(1);
    expect(events.map((e) => e.type)).toEqual(['delta', 'done']);
  });

  it('niat rencana tetapi jawaban bukan itinerary (mis. pertanyaan balik) tidak ditegur', async () => {
    const llm = fakeLlm([teks('Mau berapa hari dan budget berapa?')]);
    await jalan(llm, { pesan: [{ role: 'user', text: 'Buatkan rencana liburan' }] });
    expect(llm.permintaan).toHaveLength(1);
  });

  it('kegagalan di putaran teguran tidak menampilkan error (jawaban sudah terkirim)', async () => {
    const llm = fakeLlm([teks('Tekan tombol Simpan pada kartu di bawah.')], new Error('Incomplete JSON segment at the end'));
    const { events } = await jalan(llm);
    expect(events.map((e) => e.type)).toEqual(['delta', 'done']);
  });

  it('teguran hanya sekali: jika model tetap tidak memanggil tool, giliran selesai', async () => {
    const llm = fakeLlm(
      [teks('Tekan tombol Simpan pada kartu di bawah.')],
      [teks('Maaf, kartunya tidak muncul. Tekan tombol Simpan pada kartu di bawah.')],
      [teks('INI TIDAK BOLEH DIPANGGIL')],
    );
    const { events } = await jalan(llm);
    expect(llm.permintaan).toHaveLength(2);
    expect(events.at(-1)).toEqual({ type: 'done' });
  });

  it('tanpa klaim kartu tidak ada teguran (tidak boros kuota)', async () => {
    const llm = fakeLlm([teks('Berikut tempat wisata di Medan: Istana Maimun.')]);
    await jalan(llm);
    expect(llm.permintaan).toHaveLength(1);
  });

  it('usulkan_rencana gagal (id salah) walau sudah ada teks -> model diberi kesempatan memperbaiki', async () => {
    const llm = fakeLlm(
      [teks('Ini rencananya.'), panggil('usulkan_rencana', { judul: 'X', destinasiIds: ['palsu'] }, 'b')],
      [panggil('usulkan_rencana', { judul: 'X', destinasiIds: ['d01'] }, 'c')],
    );
    const { events } = await jalan(llm);
    expect(llm.permintaan).toHaveLength(2);
    expect(JSON.stringify(llm.permintaan[1]!.contents.at(-1))).toContain('Tidak ada id destinasi yang dikenal');
    expect(events.map((e) => e.type)).toEqual(['delta', 'rencana', 'done']);
  });

  it('limit panjang di model utama -> pindah ke model cadangan seketika, tanpa menunggu', async () => {
    const limit = Object.assign(new Error('quota. Please retry in 46.9s.'), { status: 429 });
    const llm = fakeLlm(limit, [teks('dijawab cadangan')]);
    const { events, tidur } = await jalan(llm, { modelChain: ['utama', 'cadangan-1', 'cadangan-2'] });
    expect(llm.permintaan.map((r) => r.model)).toEqual(['utama', 'cadangan-1']);
    expect(tidur).not.toHaveBeenCalled();
    expect(events).toEqual([{ type: 'delta', text: 'dijawab cadangan' }, { type: 'done' }]);
  });

  it('semua model kena limit -> error dengan hitungan detik dari Gemini', async () => {
    const limit = Object.assign(new Error('quota. Please retry in 46.9s.'), { status: 429 });
    const llm = fakeLlm(limit);
    const { events } = await jalan(llm, { modelChain: ['a', 'b'] });
    expect(llm.permintaan.map((r) => r.model)).toEqual(['a', 'b']);
    expect(events).toEqual([{ type: 'error', message: expect.stringContaining('47 detik') }]);
  });

  it('limit singkat (<=6 detik) ditunggu sesuai petunjuk lalu diulang di model yang sama', async () => {
    const limit = Object.assign(new Error('Please retry in 2.2s'), { status: 429 });
    const llm = fakeLlm(limit, [teks('ok')]);
    const { events, tidur } = await jalan(llm, { modelChain: ['a', 'b'] });
    expect(tidur).toHaveBeenCalledWith(2200);
    expect(llm.permintaan.map((r) => r.model)).toEqual(['a', 'a']);
    expect(events.at(-1)).toEqual({ type: 'done' });
  });

  it('limit panjang di tengah giliran sebelum ada teks -> giliran diulang dari awal di model berikutnya', async () => {
    const limit = Object.assign(new Error('Please retry in 46s'), { status: 429 });
    const llm = fakeLlm(
      [panggil('cari_destinasi', { kategori: 'Pantai', lokasi: 'Serdang Bedagai' })], // a, putaran 0
      limit, //                                              a, putaran 1 -> habis
      [panggil('cari_destinasi', { kategori: 'Pantai', lokasi: 'Serdang Bedagai' })], // b, diulang dari awal
      [teks('Pantai terbaik: Cermin.')],
    );
    const { events } = await jalan(llm, { modelChain: ['a', 'b'] });

    expect(llm.permintaan.map((r) => r.model)).toEqual(['a', 'a', 'b', 'b']);
    expect(llm.permintaan[2]!.contents).toHaveLength(1); // riwayat tool dibuang
    expect(events.filter((e) => e.type === 'delta')).toHaveLength(1);
    expect(events.at(-1)).toEqual({ type: 'done' });
  });

  it('limit panjang setelah teks terkirim tidak diulang dari awal (hindari teks ganda)', async () => {
    const limit = Object.assign(new Error('Please retry in 46s'), { status: 429 });
    const llm = fakeLlm([teks('Hari 1 ...'), panggil('daftar_kategori', {})], limit);
    const { events } = await jalan(llm, { modelChain: ['a', 'b'] });
    expect(llm.permintaan.map((r) => r.model)).toEqual(['a', 'a']);
    expect(events.at(-1)).toMatchObject({ type: 'error' });
  });

  it('model yang baru kena limit panjang dilewati pada chat berikutnya', async () => {
    const limit = Object.assign(new Error('Please retry in 46s'), { status: 429 });
    await jalan(fakeLlm(limit, [teks('ok')]), { modelChain: ['a', 'b'] });

    const llm2 = fakeLlm([teks('langsung b')]);
    await jalan(llm2, { modelChain: ['a', 'b'] });
    expect(llm2.permintaan.map((r) => r.model)).toEqual(['b']);

    resetKuotaModel();
    const llm3 = fakeLlm([teks('a lagi')]);
    await jalan(llm3, { modelChain: ['a', 'b'] });
    expect(llm3.permintaan.map((r) => r.model)).toEqual(['a']);
  });

  it('anggaran tunggu total dibatasi: tidak menumpuk lintas percobaan/model', async () => {
    const limit = Object.assign(new Error('Please retry in 5s'), { status: 429 });
    const llm = fakeLlm(limit); // semua percobaan kena limit 5 detik
    const { events, tidur } = await jalan(llm, { modelChain: ['a', 'b', 'c'] });

    const total = tidur.mock.calls.reduce((n, [ms]) => n + ms, 0);
    expect(total).toBeLessThanOrEqual(10_000);
    expect(events.at(-1)).toMatchObject({ type: 'error' });
  });

  it('riwayat tool (dengan thought signature) tidak pernah dibawa ke model lain', async () => {
    const limit = Object.assign(new Error('Please retry in 46s'), { status: 429 });
    const llm = fakeLlm([panggil('daftar_kategori', {})], limit); // semua model kena limit setelah putaran tool
    const { events } = await jalan(llm, { modelChain: ['a', 'b'] });

    expect(llm.permintaan.map((r) => r.model)).toEqual(['a', 'a', 'b']);
    // Permintaan ke model b hanya membawa pesan awal, bukan functionCall milik model a.
    expect(llm.permintaan[2]!.contents).toHaveLength(1);
    expect(events.at(-1)).toMatchObject({ type: 'error' });
  });

  it('error stream sementara tanpa status ("Incomplete JSON") diulang', async () => {
    const llm = fakeLlm(new Error('Incomplete JSON segment at the end'), [teks('pulih')]);
    const { events, tidur } = await jalan(llm);
    expect(tidur).toHaveBeenCalledTimes(1);
    expect(events).toEqual([{ type: 'delta', text: 'pulih' }, { type: 'done' }]);
  });

  it('error tak dikenal tanpa status (bug kode) tidak diulang', async () => {
    const llm = fakeLlm(new TypeError("Cannot read properties of undefined"));
    const { events } = await jalan(llm);
    expect(llm.permintaan).toHaveLength(1);
    expect(events).toEqual([{ type: 'error', message: expect.stringContaining('bermasalah') }]);
  });

  it('respons kosong/terblokir menghasilkan pesan fallback, bukan layar kosong', async () => {
    const kosong = await jalan(fakeLlm([{ parts: [] }]));
    expect(kosong.events[0]).toMatchObject({ type: 'delta' });
    expect(kosong.events.at(-1)).toEqual({ type: 'done' });

    const blok = await jalan(fakeLlm([{ parts: [], blokir: 'SAFETY' }]));
    expect((blok.events[0] as { text: string }).text).toMatch(/tidak bisa menjawab/);
  });

  it('putaran tool dibatasi (tidak looping selamanya)', async () => {
    const llm = fakeLlm([panggil('daftar_kategori', {})]); // selalu minta tool
    const { events } = await jalan(llm);
    expect(llm.permintaan).toHaveLength(5);
    expect(events.at(-1)).toEqual({ type: 'done' });
  });

  it('klien memutus koneksi -> tidak ada event error', async () => {
    const ac = new AbortController();
    ac.abort();
    const { events } = await jalan(fakeLlm(errorStatus(500)), { signal: ac.signal });
    expect(events).toEqual([]);
  });
});
