import { describe, expect, it } from 'vitest';
import { cari, daftarDestinasi, daftarKategori, getById, jarakKm, untukModel } from '../src/data/katalog.js';

describe('katalog', () => {
  it('memuat 32 destinasi dan 5 kategori', () => {
    expect(daftarDestinasi).toHaveLength(32);
    expect(daftarKategori.map((k) => k.nama)).toEqual(['Alam', 'Pantai', 'Budaya', 'Kuliner', 'Adventure']);
  });

  it('setiap destinasi punya kategori yang valid', () => {
    const idKategori = new Set(daftarKategori.map((k) => k.id));
    for (const d of daftarDestinasi) expect(idKategori.has(d.kategoriId), d.id).toBe(true);
  });

  it('filter kategori by nama (tidak peka huruf besar)', () => {
    const hasil = cari({ kategori: 'pantai' });
    expect(hasil.map((d) => d.nama).sort()).toEqual(['Pantai Cermin', 'Pantai Parbaba', 'Pantai Sorake', 'Pantai Sri Mersing']);
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
    const dekat = cari({ urut: 'terdekat', limit: 10 }, { lat: 3.5306, lng: 98.6596 }); // di Taman Cadika
    expect(dekat[0]?.id).toBe('d04');
    const jarak = dekat.map((d) => jarakKm({ lat: 3.5306, lng: 98.6596 }, d));
    expect(jarak).toEqual([...jarak].sort((a, b) => a - b));
    const murah = cari({ urut: 'termurah', limit: 10 });
    expect(murah[0]?.hargaTiket).toBe(0);
  });

  it('limit dibatasi 1..10 dan ratingMin berlaku', () => {
    expect(cari({ limit: 999 })).toHaveLength(10);
    expect(cari({ limit: 0 })).toHaveLength(1);
    expect(cari({ ratingMin: 4.7, limit: 10 }).every((d) => d.rating >= 4.7)).toBe(true);
  });

  it('semua destinasi punya koordinat yang berada di Sumatera Utara', () => {
    for (const d of daftarDestinasi) {
      expect(d.lat, d.id).toBeGreaterThan(0.4);
      expect(d.lat, d.id).toBeLessThan(4.3);
      expect(d.lng, d.id).toBeGreaterThan(97.0);
      expect(d.lng, d.id).toBeLessThan(100.5);
    }
    expect(new Set(daftarDestinasi.map((d) => d.id)).size).toBe(daftarDestinasi.length);
  });

  it('jarakKm: Haversine wajar (Medan - Parapat sekitar 108 km garis lurus) dan nol untuk titik sama', () => {
    const medan = { lat: 3.5952, lng: 98.6722 };
    const parapat = getById('d01')!;
    const km = jarakKm(medan, parapat);
    expect(km).toBeGreaterThan(95);
    expect(km).toBeLessThan(125);
    expect(jarakKm(medan, { lat: medan.lat, lng: medan.lng })).toBeCloseTo(0, 6);
  });

  it("urut 'terdekat' tanpa posisi jatuh ke rating dan jarak tidak dikarang", () => {
    const hasil = cari({ urut: 'terdekat', limit: 10 });
    expect(hasil.map((d) => d.rating)).toEqual([...hasil.map((d) => d.rating)].sort((a, b) => b - a));
    expect(untukModel(hasil[0]!)).not.toHaveProperty('jarakDariPenggunaKm');
    expect(untukModel(hasil[0]!, { lat: 3.59, lng: 98.67 })).toHaveProperty('jarakDariPenggunaKm');
  });

  it('getById', () => {
    expect(getById('d01')?.nama).toBe('Danau Toba');
    expect(getById('x')).toBeUndefined();
  });
});
