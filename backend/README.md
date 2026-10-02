# TRIPIN Backend (chatbot AI)

Backend kecil untuk Asisten TRIPIN: Fastify + TypeScript, memanggil Gemini (free tier)
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

```bash
cd TRIPIN        # root repo (folder yang berisi pubspec.yaml)
flutter run --dart-define=API_BASE_URL=http://<alamat-backend>:3000
```

| Perangkat            | API_BASE_URL                                   |
|----------------------|------------------------------------------------|
| Emulator Android     | `http://10.0.2.2:3000` (default, tak perlu diisi) |
| iOS Simulator/macOS  | `http://localhost:3000` (default)              |
| HP asli              | `http://<IP LAN laptop>:3000` (satu Wi-Fi)     |

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
Detail body/konteks ada di `src/routes/chat.ts`.

## Data

`src/data/destinasi.json` disalin dari `TRIPIN/lib/data/dummy_destinasi.dart`. Jika katalog di app
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
