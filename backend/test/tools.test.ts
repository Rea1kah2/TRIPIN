import { describe, expect, it } from 'vitest';
import { deklarasiTool, jalankanTool } from '../src/ai/tools.js';

const ctx = { hariIni: '2026-10-02' };

describe('tools', () => {
  it('semua deklarasi punya nama unik dan handler', () => {
    const nama = deklarasiTool.map((d) => d.name);
    expect(new Set(nama).size).toBe(nama.length);
    for (const n of nama) {
      const h = jalankanTool(n!, {}, ctx);
      expect(h.output.error ?? '').not.toMatch(/tidak dikenal/);
    }
  });

  it('cari_destinasi mengembalikan bentuk ringkas tanpa gambar', () => {
    const h = jalankanTool('cari_destinasi', { kategori: 'Pantai' }, ctx);
    expect(h.output.jumlah).toBe(2);
    expect(h.events).toEqual([{ type: 'destinasi', ids: ['d12', 'd17'] }]);
    const item = (h.output.hasil as Record<string, unknown>[])[0]!;
    expect(item).toHaveProperty('nama');
    expect(item).not.toHaveProperty('imageUrl');
  });

  it('cari_destinasi menolak tipe argumen yang salah tanpa melempar', () => {
    const h = jalankanTool('cari_destinasi', { hargaMaks: 'murah' }, ctx);
    expect(h.output.error).toBeDefined();
  });

  it('detail_destinasi: ada dan tidak ada', () => {
    expect((jalankanTool('detail_destinasi', { id: 'd01' }, ctx).output.destinasi as { nama: string }).nama).toBe('Danau Toba');
    expect(jalankanTool('detail_destinasi', { id: 'zzz' }, ctx).output.error).toMatch(/tidak ada/);
  });

  it('cari_destinasi otomatis menampilkan kartu (maks 6) kecuali tampilkan=false', () => {
    const h = jalankanTool('cari_destinasi', { limit: 10 }, ctx);
    expect(h.events).toHaveLength(1);
    expect((h.events[0] as { ids: string[] }).ids).toHaveLength(6);

    const diam = jalankanTool('cari_destinasi', { limit: 3, tampilkan: false }, ctx);
    expect(diam.events).toEqual([]);
    expect(diam.output.jumlah).toBe(3);
  });

  it('cari_destinasi tanpa hasil tidak memunculkan kartu kosong', () => {
    const h = jalankanTool('cari_destinasi', { kategori: 'Pantai', hargaMaks: 0 }, ctx);
    expect(h.output.jumlah).toBe(0);
    expect(h.events).toEqual([]);
  });

  it('tool tampilan lama sudah dihapus', () => {
    expect(deklarasiTool.map((d) => d.name)).not.toContain('tampilkan_destinasi');
    expect(jalankanTool('tampilkan_destinasi', { ids: ['d01'] }, ctx).output.error).toMatch(/tidak dikenal/);
  });

  it('usulkan_rencana: menormalkan draf', () => {
    const h = jalankanTool(
      'usulkan_rencana',
      { judul: '  Liburan Toba  ', destinasiIds: ['d01', 'd01', 'nope', 'd08'], jumlahHari: 99, tanggalMulai: '2026-10-10' },
      ctx,
    );
    expect(h.events).toEqual([
      {
        type: 'rencana',
        draft: { judul: 'Liburan Toba', tanggalMulai: '2026-10-10', jumlahHari: 14, destinasiIds: ['d01', 'd08'], catatan: '' },
      },
    ]);
    expect(h.output.catatan).toMatch(/Jangan klaim sudah disimpan/);
  });

  it('usulkan_rencana: tanggal tidak valid ditolak', () => {
    for (const t of ['besok', '2026-02-30', '10/10/2026']) {
      const h = jalankanTool('usulkan_rencana', { judul: 'x', destinasiIds: ['d01'], tanggalMulai: t }, ctx);
      expect(h.output.error, t).toBeDefined();
      expect(h.events).toEqual([]);
    }
  });

  it('tool tidak dikenal -> error, tidak melempar', () => {
    expect(jalankanTool('hapus_semua', {}, ctx).output.error).toMatch(/tidak dikenal/);
  });
});
