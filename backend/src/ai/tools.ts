import type { FunctionDeclaration } from '@google/genai';
import { z } from 'zod';
import { cari, daftarKategori, getById, untukModel } from '../data/katalog.js';

/** Event yang diteruskan ke app Flutter lewat SSE (selain teks). */
export type EventKlien =
  | { type: 'destinasi'; ids: string[] }
  | { type: 'rencana'; draft: DraftRencana };

export interface DraftRencana {
  judul: string;
  tanggalMulai?: string; // YYYY-MM-DD
  jumlahHari: number;
  destinasiIds: string[];
  catatan: string;
}

export interface KonteksTool {
  hariIni: string; // YYYY-MM-DD
}

export interface HasilTool {
  output: Record<string, unknown>;
  events: EventKlien[];
}

export const deklarasiTool: FunctionDeclaration[] = [
  {
    name: 'cari_destinasi',
    description:
      'Mencari destinasi wisata di katalog TRIPIN berdasarkan filter. Gunakan ini sebelum merekomendasikan tempat apa pun. ' +
      'Semua parameter opsional dan boleh dikombinasikan. Secara default hasilnya otomatis tampil sebagai kartu interaktif ' +
      'di layar pengguna, jadi atur limit sesuai jumlah yang benar-benar akan kamu rekomendasikan (biasanya 3-5).',
    parametersJsonSchema: {
      type: 'object',
      properties: {
        kategori: {
          type: 'string',
          description: 'Nama kategori: Alam, Pantai, Budaya, Kuliner, atau Adventure.',
        },
        lokasi: {
          type: 'string',
          description: 'Nama kabupaten/kota atau tempat, mis. Karo, Medan, Langkat, Toba, Samosir.',
        },
        kataKunci: {
          type: 'string',
          description: 'Kata yang dicari pada nama atau deskripsi, mis. air terjun, kopi, orangutan.',
        },
        hargaMaks: { type: 'integer', description: 'Harga tiket maksimum dalam rupiah. 0 = hanya yang gratis.' },
        ratingMin: { type: 'number', description: 'Rating minimum 0-5.' },
        urut: {
          type: 'string',
          enum: ['rating', 'terdekat', 'termurah'],
          description: 'Urutan hasil. Default rating tertinggi.',
        },
        limit: { type: 'integer', description: 'Jumlah hasil maksimum, 1-10. Default 5.' },
        tampilkan: {
          type: 'boolean',
          description:
            'Default true: hasil ditampilkan sebagai kartu. Isi false jika hanya mencari data untuk menyusun rencana ' +
            '(kartu draf rencana sudah cukup) atau untuk pencarian perantara.',
        },
      },
    },
  },
  {
    name: 'detail_destinasi',
    description: 'Mengambil detail lengkap satu destinasi berdasarkan id (mis. "d01").',
    parametersJsonSchema: {
      type: 'object',
      properties: { id: { type: 'string', description: 'Id destinasi dari hasil cari_destinasi.' } },
      required: ['id'],
    },
  },
  {
    name: 'daftar_kategori',
    description: 'Mengambil daftar kategori wisata yang ada di TRIPIN.',
    parametersJsonSchema: { type: 'object', properties: {} },
  },
  {
    name: 'usulkan_rencana',
    description:
      'Mengusulkan draf rencana perjalanan. Draf ditampilkan sebagai kartu dengan tombol "Simpan"; ' +
      'pengguna yang memutuskan menyimpannya. Panggil ini setelah kamu menyusun rencana dari destinasi hasil tool.',
    parametersJsonSchema: {
      type: 'object',
      properties: {
        judul: { type: 'string', description: 'Judul singkat rencana, mis. "Liburan 2 Hari di Danau Toba".' },
        destinasiIds: { type: 'array', items: { type: 'string' }, description: 'Id destinasi sesuai urutan kunjungan.' },
        jumlahHari: { type: 'integer', description: 'Lama perjalanan dalam hari, 1-14.' },
        tanggalMulai: { type: 'string', description: 'Format YYYY-MM-DD. Isi hanya jika pengguna menyebut tanggal.' },
        catatan: { type: 'string', description: 'Catatan singkat, mis. tips urutan atau waktu terbaik.' },
      },
      required: ['judul', 'destinasiIds'],
    },
  },
];

const cariArgs = z.object({
  kategori: z.string().optional(),
  lokasi: z.string().optional(),
  kataKunci: z.string().optional(),
  hargaMaks: z.number().optional(),
  ratingMin: z.number().optional(),
  urut: z.enum(['rating', 'terdekat', 'termurah']).optional(),
  limit: z.number().optional(),
  tampilkan: z.boolean().optional(),
});
const detailArgs = z.object({ id: z.string() });
const rencanaArgs = z.object({
  judul: z.string().min(1),
  destinasiIds: z.array(z.string()).min(1),
  jumlahHari: z.number().optional(),
  tanggalMulai: z.string().optional(),
  catatan: z.string().optional(),
});

const MAKS_KARTU = 6;

function idValid(ids: string[]): { valid: string[]; tidakDikenal: string[] } {
  const unik = [...new Set(ids)];
  return {
    valid: unik.filter((id) => getById(id)),
    tidakDikenal: unik.filter((id) => !getById(id)),
  };
}

function tanggalValid(s: string): boolean {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(s)) return false;
  const d = new Date(`${s}T00:00:00Z`);
  return !Number.isNaN(d.getTime()) && d.toISOString().startsWith(s);
}

/**
 * Menjalankan satu tool. Tidak pernah melempar: argumen salah dikembalikan
 * sebagai { error } agar model bisa memperbaiki panggilannya.
 */
export function jalankanTool(nama: string, args: unknown, konteks: KonteksTool): HasilTool {
  switch (nama) {
    case 'cari_destinasi': {
      const p = cariArgs.safeParse(args ?? {});
      if (!p.success) return galat('Argumen cari_destinasi tidak valid.');
      const { tampilkan, ...filter } = p.data;
      const ditemukan = cari(filter);
      const hasil = ditemukan.map(untukModel);
      const events: EventKlien[] =
        tampilkan === false || ditemukan.length === 0
          ? []
          : [{ type: 'destinasi', ids: ditemukan.slice(0, MAKS_KARTU).map((d) => d.id) }];
      return { output: { jumlah: hasil.length, hasil }, events };
    }
    case 'detail_destinasi': {
      const p = detailArgs.safeParse(args);
      if (!p.success) return galat('Argumen detail_destinasi tidak valid.');
      const d = getById(p.data.id);
      if (!d) return galat(`Destinasi dengan id "${p.data.id}" tidak ada di katalog.`);
      return { output: { destinasi: untukModel(d) }, events: [] };
    }
    case 'daftar_kategori':
      return { output: { kategori: daftarKategori.map((k) => k.nama) }, events: [] };
    case 'usulkan_rencana': {
      const p = rencanaArgs.safeParse(args);
      if (!p.success) return galat('Argumen usulkan_rencana tidak valid.');
      const { valid, tidakDikenal } = idValid(p.data.destinasiIds);
      if (valid.length === 0) return galat('Tidak ada id destinasi yang dikenal. Gunakan id dari hasil cari_destinasi.');
      if (p.data.tanggalMulai !== undefined && !tanggalValid(p.data.tanggalMulai)) {
        return galat('tanggalMulai harus berformat YYYY-MM-DD dan berupa tanggal yang benar.');
      }
      const draft: DraftRencana = {
        judul: p.data.judul.trim().slice(0, 100),
        tanggalMulai: p.data.tanggalMulai,
        jumlahHari: Math.min(Math.max(Math.round(p.data.jumlahHari ?? 1), 1), 14),
        destinasiIds: valid,
        catatan: (p.data.catatan ?? '').trim().slice(0, 400),
      };
      return {
        output: {
          ok: true,
          catatan: 'Draf sudah ditampilkan ke pengguna dengan tombol Simpan. Jangan klaim sudah disimpan.',
          idTidakDikenal: tidakDikenal,
          hariIni: konteks.hariIni,
        },
        events: [{ type: 'rencana', draft }],
      };
    }
    default:
      return galat(`Tool "${nama}" tidak dikenal.`);
  }
}

function galat(pesan: string): HasilTool {
  return { output: { error: pesan }, events: [] };
}
