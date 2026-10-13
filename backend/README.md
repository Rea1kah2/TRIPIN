# TRIPIN Backend (chatbot AI)

Backend kecil untuk Tripy (asisten AI TRIPIN): Fastify + TypeScript, memanggil Gemini (free tier)
dengan function calling ke katalog destinasi, dan menyiarkan jawaban lewat SSE.

## Menjalankan

```bash
cd TRIPIN/backend
npm install
cp .env.example .env        # lalu isi GEMINI_API_KEY (gratis: https://aistudio.google.com/apikey)
npm run dev                 # http://localhost:3000
curl localhost:3000/health  # {"status":"ok","asisten":"siap",...}
```

Uji manual (SSE):

```bash
curl -N -X POST localhost:3000/api/chat -H 'content-type: application/json' \
  -d '{"pesan":[{"role":"user","text":"wisata alam murah di Karo?"}]}'
```

## Menyambungkan app Flutter

Terminal 1: `cd backend && npm run dev`. Terminal 2 (root repo, HP dicolok USB dengan USB debugging aktif):

```bash
./scripts/run_android.sh
```

Skrip memasang `adb reverse tcp:3000 tcp:3000` lalu `flutter run`, sehingga `http://localhost:3000`
di HP/emulator menunjuk ke backend di laptop (tidak peduli IP Wi-Fi berubah). Ulangi skrip setiap
HP dicabut-colok, karena `adb reverse` hilang saat koneksi USB putus.

| Cara                       | Perintah                                                          |
|----------------------------|-------------------------------------------------------------------|
| HP asli/emulator via USB   | `./scripts/run_android.sh` (default `http://localhost:3000`)      |
| HP asli via Wi-Fi          | `flutter run --dart-define=API_BASE_URL=http://<IP LAN laptop>:3000` |
| iOS Simulator/macOS/Chrome | `flutter run` (default `http://localhost:3000`)                   |

Pesan "Tidak bisa terhubung ke asisten" hampir selalu berarti: backend belum jalan, `adb reverse`
belum dipasang (atau hilang), atau HP dan laptop beda jaringan Wi-Fi (cek firewall macOS untuk Node).
Log `ChatService: gagal menghubungi ...` di konsol `flutter run` menampilkan alamat yang dicoba.

Jika `APP_KEY` diisi di `.env`, jalankan app dengan `--dart-define=APP_KEY=<nilai yang sama>`.

## Konfigurasi (`.env`)

| Variabel | Fungsi |
|---|---|
| `GEMINI_API_KEY` | Wajib. Hanya ada di server, jangan pernah ke Flutter. |
| `GEMINI_MODEL` | Default `gemini-3.8-flash`. Free tier model ini terukur **5 permintaan/menit** (hasil uji, bisa berubah; cek di Google AI Studio). |
| `GEMINI_FALLBACK_MODELS` | Model cadangan berurutan saat model utama kena limit. Kuota free tier dihitung **per model**, jadi cadangan menambah kapasitas. Default `gemini-3.6-flash,gemini-3.5-flash,gemini-3.5-flash-lite,gemini-3.1-flash-lite`. |
| `RATE_LIMIT_PER_MINUTE` | Batas `/api/chat` per IP. Default 20. |
| `APP_KEY` | Opsional, header `x-app-key`. Hanya pengurang penyalahgunaan iseng, bukan autentikasi. |
| `TRUST_PROXY=true` | Set bila di belakang proxy (Render/Railway) agar rate limit memakai IP klien asli. |

## Kontrak API

`POST /api/chat` -> `text/event-stream`, satu JSON per event `data:`:
`delta` (potongan teks), `destinasi` (id kartu), `rencana` (draf rencana), `done`, `error`.
Detail body/konteks ada di `src/routes/chat.ts`. `konteks.posisi` (`lat`, `lng`) bersifat opsional dan hanya
dikirim app bila pengguna mengizinkan lokasi (dibulatkan kasar, sekitar 1 km); tanpa itu jarak tidak tersedia.

## Data

`src/data/destinasi.json` (32 destinasi, lengkap dengan `lat`/`lng`) disalin dari `TRIPIN/lib/data/dummy_destinasi.dart`. Jika katalog di app
berubah, perbarui juga file ini (rencana lanjutan: app mengambil katalog dari backend).

## Privasi

Free tier Gemini umumnya boleh dipakai Google untuk meningkatkan produknya. App hanya mengirim
id destinasi, judul rencana, dan teks chat; **tidak** mengirim nama/email/password. Baca syarat
free tier di AI Studio sebelum demo ke publik.

## Tes

```bash
npm test          # vitest (model Gemini dipalsukan, tanpa jaringan)
npm run typecheck
```
