import type { Content, FunctionCall, Part } from '@google/genai';
import { buatSystemPrompt, type KonteksPengguna } from './systemPrompt.js';
import { deklarasiTool, jalankanTool, type EventKlien } from './tools.js';
import type { LlmClient } from './llm.js';

export interface PesanMasuk {
  role: 'user' | 'model';
  text: string;
}

export type EventSse =
  | { type: 'delta'; text: string }
  | { type: 'status'; text: string }
  | EventKlien
  | { type: 'done' }
  | { type: 'error'; message: string };

export interface OpsiChat {
  llm: LlmClient;
  pesan: PesanMasuk[];
  konteks: KonteksPengguna;
  emit: (e: EventSse) => void;
  signal?: AbortSignal;
  log?: (msg: string, err?: unknown) => void;
  /**
   * Urutan model: yang pertama utama, sisanya cadangan bila kena limit.
   * Kuota free tier dihitung per model sehingga cadangan menambah kapasitas.
   * Kosong = pakai model default klien.
   */
  modelChain?: string[];
  /** Bisa diganti di test supaya backoff tidak menunggu sungguhan. */
  tidur?: (ms: number) => Promise<void>;
}

const MAKS_PUTARAN = 5; // batas bolak-balik model <-> tool
const MAKS_PERCOBAAN = 3; // 1 percobaan awal + 2 ulang untuk error sementara
const JEDA_DASAR_MS = 1500;
const TUNGGU_MAKS_MS = 6000; // limit yang menyuruh tunggu lebih lama dari ini tidak ditunggu di tempat
const ANGGARAN_TUNGGU_MS = 10_000; // total waktu tunggu (backoff) yang boleh dihabiskan satu chat, lintas model

/** Tool yang hanya menampilkan sesuatu; bila jawaban teks sudah ada, giliran bisa langsung selesai. */
const TOOL_AKHIR = new Set(['usulkan_rencana']);

/** Teks yang menjanjikan kartu/tombol rencana di layar pengguna. */
const KLAIM_KARTU_RENCANA =
  /tombol\s+\**simpan|kartu\s+(di\s+bawah|berikut|rencana|draf)|draf\s+(rencana\s+)?(di\s+bawah|berikut|ini\s+(bisa|dapat)|sudah)/i;

/** Permintaan pengguna yang bermaksud meminta rencana/itinerary. */
const NIAT_RENCANA = /rencana|itinerar|jadwal|susun|liburan|trip\b|\d+\s*hari/i;
/** Jawaban yang berbentuk itinerary (hari 1 / pagi: ... siang: ...). */
const BENTUK_ITINERARY = /hari\s*(ke-?\s?)?(1|satu|pertama)\b|\b(pagi|siang|sore)\b\s*[:\-\u2013]/i;

function perluKartuRencana(teks: string, pesanTerakhirUser: string): boolean {
  return KLAIM_KARTU_RENCANA.test(teks) || (NIAT_RENCANA.test(pesanTerakhirUser) && BENTUK_ITINERARY.test(teks));
}

const NUDGE_RENCANA =
  '[Pesan sistem] Jawabanmu berisi rencana/itinerary tetapi usulkan_rencana belum dipanggil sehingga ' +
  'pengguna tidak melihat kartu rencana dengan tombol Simpan. Panggil usulkan_rencana sekarang: judul singkat, ' +
  'jumlahHari sesuai jawabanmu, dan destinasiIds (id dari hasil pencarian) sesuai urutan kunjungan. ' +
  'Jangan menulis ulang jawabanmu.';

/** Status singkat yang ditampilkan app saat Tripy bekerja (bukan bagian jawaban). */
const STATUS_TOOL: Record<string, string> = {
  cari_destinasi: 'Tripy lagi nyari tempat…',
  detail_destinasi: 'Ngecek detail tempatnya…',
  usulkan_rencana: 'Nyusun rencana…',
};
const STATUS_TOOL_LAIN = 'Memproses…';
const STATUS_JAWAB = 'Nyusun jawaban…';
const STATUS_ANTRE = 'Tripy lagi antre, nyoba lagi…';

const PESAN_ERROR = 'Tripy lagi bermasalah. Coba lagi nanti ya.';
const PESAN_BLOKIR = 'Maaf, aku tidak bisa menjawab permintaan itu. Coba tanyakan hal lain seputar wisata Sumatera Utara.';
const PESAN_KOSONG = 'Maaf, aku belum bisa menjawab itu. Coba ulangi dengan kalimat lain.';

function statusDari(err: unknown): number | undefined {
  if (typeof err === 'object' && err !== null && 'status' in err) {
    const s = (err as { status: unknown }).status;
    return typeof s === 'number' ? s : undefined;
  }
  return undefined;
}

function pesanDari(err: unknown): string {
  return err instanceof Error ? err.message : String(err);
}

/** Error sementara yang layak diulang: limit/overload, atau gangguan jaringan/stream tanpa status HTTP. */
function dapatDiulang(err: unknown): boolean {
  const s = statusDari(err);
  if (s !== undefined) return s === 429 || s === 503;
  return /incomplete json|fetch failed|econnreset|etimedout|socket|terminated|network/i.test(pesanDari(err));
}

/** Membaca "Please retry in 46.9s" dari pesan error Gemini (dalam milidetik). */
export function tundaDariError(err: unknown): number | undefined {
  const m = /retry in ([\d.]+)\s*s/i.exec(pesanDari(err));
  if (!m) return undefined;
  const detik = Number(m[1]);
  return Number.isFinite(detik) ? Math.ceil(detik * 1000) : undefined;
}

/**
 * Model yang baru saja kena limit panjang dilewati sampai waktunya habis,
 * supaya chat berikutnya tidak membuang satu permintaan gagal di model yang sama.
 */
const habisSampai = new Map<string, number>();

export function resetKuotaModel(): void {
  habisSampai.clear();
}

function tandaiHabis(model: string | undefined, tundaMs: number | undefined): void {
  if (model && tundaMs) habisSampai.set(model, Date.now() + tundaMs);
}

function modelAwal(chain: (string | undefined)[]): number {
  const sekarang = Date.now();
  const idx = chain.findIndex((m) => !m || (habisSampai.get(m) ?? 0) <= sekarang);
  return idx === -1 ? 0 : idx; // semua sedang habis: tetap coba yang utama
}

export function pesanSibuk(err: unknown): string {
  const tunda = tundaDariError(err);
  return tunda
    ? `Tripy lagi sibuk (batas penggunaan tercapai). Coba lagi dalam ${Math.ceil(tunda / 1000)} detik.`
    : 'Tripy lagi sibuk (batas penggunaan tercapai). Coba lagi sebentar ya.';
}

export async function jalankanChat(opsi: OpsiChat): Promise<void> {
  const { llm, emit, signal } = opsi;
  const tidur = opsi.tidur ?? ((ms: number) => new Promise<void>((r) => setTimeout(r, ms)));
  const systemInstruction = buatSystemPrompt(opsi.konteks);
  const chain = opsi.modelChain?.length ? opsi.modelChain : [undefined];
  let idxModel = modelAwal(chain);
  let sisaTunggu = ANGGARAN_TUNGGU_MS;

  const contents: Content[] = opsi.pesan.map((m) => ({ role: m.role, parts: [{ text: m.text }] }));
  const jumlahAwal = contents.length;
  let adaTeks = false;
  let teksTurn = '';
  let adaRencana = false;
  let sudahMenegur = false;
  let sedangMenegur = false;
  let paksaTool: string | undefined;
  const pesanTerakhirUser = [...opsi.pesan].reverse().find((m) => m.role === 'user')?.text ?? '';

  try {
    for (let putaran = 0; putaran < MAKS_PUTARAN; putaran++) {
      if (putaran > 0) emit({ type: 'status', text: STATUS_JAWAB });
      const partsModel: Part[] = [];
      let blokir: string | undefined;
      let ulangDariAwal = false;

      for (let percobaan = 1; ; percobaan++) {
        let sudahAdaOutput = false;
        try {
          for await (const chunk of llm.stream({
            contents,
            systemInstruction,
            tools: deklarasiTool,
            signal,
            model: chain[idxModel],
            paksaTool,
          })) {
            sudahAdaOutput = true;
            if (chunk.blokir) blokir = chunk.blokir;
            for (const part of chunk.parts) {
              partsModel.push(part);
              if (part.text && !part.thought) {
                adaTeks = true;
                teksTurn += part.text;
                emit({ type: 'delta', text: part.text });
              }
            }
          }
          break;
        } catch (err) {
          // Ulang/pindah hanya jika belum ada output pada percobaan ini, agar teks tidak dobel.
          if (sudahAdaOutput || !dapatDiulang(err) || signal?.aborted) throw err;

          const tunda = tundaDariError(err);
          const tundaEfektif = tunda ?? JEDA_DASAR_MS * 2 ** (percobaan - 1);
          const limitPanjang =
            statusDari(err) === 429 && tunda !== undefined && (tunda > TUNGGU_MAKS_MS || tunda > sisaTunggu);
          const menyerah = limitPanjang || percobaan >= MAKS_PERCOBAAN || tundaEfektif > sisaTunggu;
          const adaCadangan = idxModel < chain.length - 1;
          if (menyerah && statusDari(err) === 429) tandaiHabis(chain[idxModel], tunda ?? 15_000);

          // Putaran pertama: pindah model langsung. Putaran berikutnya: thought signature terikat ke
          // model, jadi tidak boleh ganti di tengah; bila belum ada teks yang terkirim, ulang giliran
          // dari awal di model berikutnya (kartu yang sudah terkirim digabung/dedup oleh klien).
          if (menyerah && adaCadangan && (putaran === 0 || !adaTeks)) {
            opsi.log?.(`Model ${chain[idxModel] ?? '(default)'} gagal, beralih ke ${chain[idxModel + 1]}`, err);
            idxModel++;
            emit({ type: 'status', text: STATUS_ANTRE });
            if (putaran === 0) {
              percobaan = 0; // percobaan baru untuk model baru
              continue;
            }
            ulangDariAwal = true;
            break;
          }
          if (menyerah) throw err;
          sisaTunggu -= tundaEfektif;
          emit({ type: 'status', text: STATUS_ANTRE });
          await tidur(tundaEfektif);
        }
      }

      paksaTool = undefined; // paksaan hanya berlaku untuk putaran teguran
      if (ulangDariAwal) {
        contents.length = jumlahAwal;
        putaran = -1; // for akan menaikkannya jadi 0
        continue;
      }

      const panggilan = partsModel
        .map((p) => p.functionCall)
        .filter((f): f is FunctionCall => !!f);

      if (panggilan.length === 0) {
        // Model menjanjikan kartu rencana tanpa memanggil tool-nya: tegur sekali.
        if (!sudahMenegur && !adaRencana && perluKartuRencana(teksTurn, pesanTerakhirUser) && putaran < MAKS_PUTARAN - 1) {
          sudahMenegur = true;
          sedangMenegur = true;
          paksaTool = 'usulkan_rencana'; // pada putaran teguran model wajib memanggil tool ini
          opsi.log?.('Jawaban berisi rencana tanpa usulkan_rencana; menegur sekali dengan panggilan wajib');
          contents.push({ role: 'model', parts: partsModel });
          contents.push({ role: 'user', parts: [{ text: NUDGE_RENCANA }] });
          continue;
        }
        if (!adaTeks) emit({ type: 'delta', text: blokir ? PESAN_BLOKIR : PESAN_KOSONG });
        emit({ type: 'done' });
        return;
      }

      // Kembalikan seluruh part model apa adanya (termasuk thought signature).
      contents.push({ role: 'model', parts: partsModel });

      let adaGalatTool = false;
      const responsParts: Part[] = panggilan.map((fc) => {
        emit({ type: 'status', text: STATUS_TOOL[fc.name ?? ''] ?? STATUS_TOOL_LAIN });
        const hasil = jalankanTool(fc.name ?? '', fc.args, { hariIni: opsi.konteks.hariIni, posisi: opsi.konteks.posisi });
        if (hasil.output.error !== undefined) adaGalatTool = true;
        for (const e of hasil.events) {
          if (e.type === 'rencana') adaRencana = true;
          emit(e);
        }
        return {
          functionResponse: { id: fc.id, name: fc.name, response: { output: hasil.output } },
        };
      });

      // Hemat satu panggilan model (kuota free tier kecil): jika jawaban teks sudah ada dan model
      // hanya memanggil tool tampilan yang berhasil, tidak ada lagi yang perlu dijawab.
      // Bila tool gagal, lanjutkan agar model melihat galatnya dan memperbaiki panggilan.
      if (adaTeks && !adaGalatTool && panggilan.every((f) => TOOL_AKHIR.has(f.name ?? ''))) {
        emit({ type: 'done' });
        return;
      }

      contents.push({ role: 'user', parts: responsParts });
    }

    // Terlalu banyak putaran tool tanpa jawaban akhir.
    if (!adaTeks) emit({ type: 'delta', text: PESAN_KOSONG });
    emit({ type: 'done' });
  } catch (err) {
    if (signal?.aborted) return; // klien memutus koneksi
    opsi.log?.('Gagal memanggil model', err);
    if (sedangMenegur && adaTeks) {
      // Jawaban teks sudah sampai ke pengguna; kegagalan di putaran teguran tidak perlu ditampilkan.
      emit({ type: 'done' });
      return;
    }
    emit({ type: 'error', message: statusDari(err) === 429 ? pesanSibuk(err) : PESAN_ERROR });
  }
}
