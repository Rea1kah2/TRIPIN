import destinasiJson from './destinasi.json' with { type: 'json' };
import kategoriJson from './kategori.json' with { type: 'json' };

export interface Destinasi {
  id: string;
  nama: string;
  lokasi: string;
  kategoriId: string;
  rating: number;
  hargaTiket: number; // rupiah, 0 = gratis
  lat: number;
  lng: number;
  deskripsi: string;
}

/** Posisi pengguna (WGS84). Hanya ada bila pengguna mengizinkan lokasi. */
export interface Posisi {
  lat: number;
  lng: number;
}

export interface Kategori {
  id: string;
  nama: string;
}

export const daftarDestinasi: Destinasi[] = destinasiJson;
export const daftarKategori: Kategori[] = kategoriJson;

export type Urutan = 'rating' | 'terdekat' | 'termurah';

export interface FilterDestinasi {
  kategori?: string; // nama atau id kategori
  lokasi?: string; // cocok ke lokasi atau nama
  kataKunci?: string; // cocok ke nama atau deskripsi
  hargaMaks?: number;
  ratingMin?: number;
  urut?: Urutan;
  limit?: number;
}

/** Jarak lingkaran besar (Haversine) dari posisi ke destinasi, dalam km. */
export function jarakKm(p: Posisi, d: Pick<Destinasi, 'lat' | 'lng'>): number {
  const rad = (x: number) => (x * Math.PI) / 180;
  const dLat = rad(d.lat - p.lat);
  const dLng = rad(d.lng - p.lng);
  const a = Math.sin(dLat / 2) ** 2 + Math.cos(rad(p.lat)) * Math.cos(rad(d.lat)) * Math.sin(dLng / 2) ** 2;
  return 2 * 6371.0088 * Math.asin(Math.min(1, Math.sqrt(a)));
}

export function getById(id: string): Destinasi | undefined {
  return daftarDestinasi.find((d) => d.id === id);
}

export function namaKategori(id: string): string {
  return daftarKategori.find((k) => k.id === id)?.nama ?? '';
}

function cocokKategori(d: Destinasi, kategori: string): boolean {
  const q = kategori.trim().toLowerCase();
  return daftarKategori.some(
    (k) => k.id === d.kategoriId && (k.id.toLowerCase() === q || k.nama.toLowerCase() === q),
  );
}

export function cari(filter: FilterDestinasi = {}, posisi?: Posisi): Destinasi[] {
  const limit = Math.min(Math.max(filter.limit ?? 5, 1), 10);
  const lokasi = filter.lokasi?.trim().toLowerCase();
  const kata = filter.kataKunci?.trim().toLowerCase();

  const hasil = daftarDestinasi.filter((d) => {
    if (filter.kategori && !cocokKategori(d, filter.kategori)) return false;
    if (lokasi && !(d.lokasi.toLowerCase().includes(lokasi) || d.nama.toLowerCase().includes(lokasi))) {
      return false;
    }
    if (kata && !(d.nama.toLowerCase().includes(kata) || d.deskripsi.toLowerCase().includes(kata))) {
      return false;
    }
    if (filter.hargaMaks !== undefined && d.hargaTiket > filter.hargaMaks) return false;
    if (filter.ratingMin !== undefined && d.rating < filter.ratingMin) return false;
    return true;
  });

  // 'terdekat' butuh posisi pengguna; tanpa itu, urutkan menurut rating (bukan jarak karangan).
  const urut = filter.urut === 'terdekat' && !posisi ? 'rating' : (filter.urut ?? 'rating');
  hasil.sort((a, b) => {
    if (urut === 'terdekat' && posisi) return jarakKm(posisi, a) - jarakKm(posisi, b);
    if (urut === 'termurah') return a.hargaTiket - b.hargaTiket || b.rating - a.rating;
    return b.rating - a.rating;
  });

  return hasil.slice(0, limit);
}

/** Bentuk ringkas yang dikirim ke model (tanpa URL gambar). */
export function untukModel(d: Destinasi, posisi?: Posisi) {
  return {
    id: d.id,
    nama: d.nama,
    lokasi: d.lokasi,
    kategori: namaKategori(d.kategoriId),
    rating: d.rating,
    hargaTiketRupiah: d.hargaTiket,
    // Jarak hanya disertakan bila posisi pengguna diketahui; tidak pernah dikarang.
    ...(posisi ? { jarakDariPenggunaKm: Math.round(jarakKm(posisi, d) * 10) / 10 } : {}),
    deskripsi: d.deskripsi,
  };
}
