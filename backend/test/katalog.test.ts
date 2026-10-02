import { describe, expect, it } from 'vitest';
import { cari, daftarDestinasi, daftarKategori, getById } from '../src/data/katalog.js';

describe('katalog', () => {
  it('memuat 20 destinasi dan 5 kategori', () => {
    expect(daftarDestinasi).toHaveLength(20);
    expect(daftarKategori.map((k) => k.nama)).toEqual(['Alam', 'Pantai', 'Budaya', 'Kuliner', 'Adventure']);
  });

  it('setiap destinasi punya kategori yang valid', () => {
    const idKategori = new Set(daftarKategori.map((k) => k.id));
    for (const d of daftarDestinasi) expect(idKategori.has(d.kategoriId), d.id).toBe(true);
  });

  it('filter kategori by nama (tidak peka huruf besar)', () => {
    const hasil = cari({ kategori: 'pantai' });
    expect(hasil.map((d) => d.nama).sort()).toEqual(['Pantai Cermin', 'Pantai Sri Mersing']);
  });

  it('filter lokasi cocok ke lokasi atau nama', () => {
    expect(cari({ lokasi: 'karo', limit: 10 }).every((d) => d.lokasi === 'Karo')).toBe(true);
    expect(cari({ lokasi: 'toba' }).map((d) => d.id)).toContain('d01');
  });

  it('hargaMaks 0 hanya mengembalikan yang gratis', () => {
    const hasil = cari({ hargaMaks: 0, limit: 10 });
    expect(hasil.length).toBeGreaterThan(0);
    expect(hasil.every((d) => d.hargaTiket === 0)).toBe(true);
  });

  it('urutan: rating menurun, terdekat naik, termurah naik', () => {
    const rating = cari({ limit: 10 });
    expect(rating.map((d) => d.rating)).toEqual([...rating.map((d) => d.rating)].sort((a, b) => b - a));
    const dekat = cari({ urut: 'terdekat', limit: 10 });
    expect(dekat[0]?.id).toBe('d04'); // Taman Cadika 3,2 km
    const murah = cari({ urut: 'termurah', limit: 10 });
    expect(murah[0]?.hargaTiket).toBe(0);
  });

  it('limit dibatasi 1..10 dan ratingMin berlaku', () => {
    expect(cari({ limit: 999 })).toHaveLength(10);
    expect(cari({ limit: 0 })).toHaveLength(1);
    expect(cari({ ratingMin: 4.7, limit: 10 }).every((d) => d.rating >= 4.7)).toBe(true);
  });

  it('getById', () => {
    expect(getById('d01')?.nama).toBe('Danau Toba');
    expect(getById('x')).toBeUndefined();
  });
});
