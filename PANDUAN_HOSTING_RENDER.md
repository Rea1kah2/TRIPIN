# Panduan Deploy Backend TRIPIN ke Render (100% Gratis)

Dokumen ini menjelaskan langkah mudah men-deploy backend AI chatbot Tripy ke layanan cloud gratis **Render** (https://render.com).

Dengan hosting ini, aplikasi Flutter TRIPIN dapat mengakses chatbot Tripy kapan saja di perangkat mobile fisik tanpa perlu menjalankan server di laptop atau menghubungkan kabel data (`adb reverse`).

---

## 1. Persiapan Awal

1. Buat akun gratis di [Render](https://render.com) (bisa langsung login menggunakan akun **GitHub** Anda).
2. Pastikan kode branch terbaru sudah di-push ke repositori GitHub Anda.
3. Siapkan **Google Gemini API Key** Anda dari [Google AI Studio](https://aistudio.google.com/).

---

## 2. Cara Deploy

Ada dua cara untuk men-deploy, Anda bisa memilih cara mana saja yang paling nyaman:

### Opsi A: Menggunakan Render Blueprint (Otomatis & Sangat Cepat) ⭐

Repositori ini sudah dilengkapi berkas `render.yaml`.
1. Di Dashboard Render, klik **New +** di pojok kanan atas, lalu pilih **Blueprint**.
2. Sambungkan ke repositori GitHub proyek `tripin`.
3. Render akan membaca `render.yaml` secara otomatis:
   - Name: `tripin-backend`
   - Root Directory: `backend`
   - Build Command: `npm install`
   - Start Command: `npm start`
   - Health Check: `/health`
4. Masukkan environment variable yang diminta:
   - `GEMINI_API_KEY`: Masukkan Google Gemini API Key Anda.
   - `APP_KEY`: *(Opsional / kosongkan jika tidak menggunakan kunci khusus)*.
5. Klik **Apply**. Render akan menginstal dependensi dan menyalakan server.

---

### Opsi B: Buat Web Service Manual

1. Di Dashboard Render, klik **New +** -> **Web Service**.
2. Pilih repositori GitHub `tripin`.
3. Konfigurasikan form sebagai berikut:
   - **Name**: `tripin-backend`
   - **Region**: Singapore (terdekat dan tercepat untuk Indonesia)
   - **Root Directory**: `backend`
   - **Runtime**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Instance Type**: `Free`
4. Tambahkan **Environment Variables**:
   - `HOST`: `0.0.0.0`
   - `GEMINI_API_KEY`: `<API_KEY_GEMINI_ANDA>`
   - `GEMINI_MODEL`: `gemini-2.5-flash`
   - `GEMINI_FALLBACK_MODELS`: `gemini-2.5-flash,gemini-2.0-flash,gemini-1.5-flash`
   - `RATE_LIMIT_PER_MINUTE`: `30`
5. Buka tab **Advanced**, masukkan Health Check Path: `/health`.
6. Klik **Create Web Service**.

---

## 3. Cek Status Server

Setelah proses deploy selesai (biasanya memakan waktu 1–2 menit), Render akan memberikan URL publik, misalnya:
`https://tripin-backend.onrender.com`

Uji di browser atau terminal:
```bash
curl https://tripin-backend.onrender.com/health
```
Output yang diharapkan:
```json
{"status":"ok"}
```

---

## 4. Menghubungkan ke Aplikasi Flutter

Setelah URL Render aktif, Anda dapat menghubungkan aplikasi Flutter dengan dua cara:

### Cara 1: Menggunakan parameter `--dart-define` saat build / run (Disarankan)
```bash
flutter run --dart-define=API_BASE_URL=https://tripin-backend.onrender.com
```
Atau saat membuat APK rilis:
```bash
flutter build apk --release --dart-define=API_BASE_URL=https://tripin-backend.onrender.com
```

### Cara 2: Menetapkan default URL di `lib/config/app_config.dart`
Ubah baris fallback di `lib/config/app_config.dart` dari `http://localhost:3000` menjadi URL Render Anda:
```dart
return 'https://tripin-backend.onrender.com';
```

---

## 5. Catatan Free Tier Render (Cold Start)
- Pada paket gratis Render, jika server tidak menerima permintaan selama 15 menit, server akan masuk ke mode *sleep*.
- Saat pertama kali diakses kembali oleh pengguna, server membutuhkan waktu sekitar 30–50 detik untuk bangun (*spin up*).
- Setelah bangun, koneksi streaming respons Tripy via Server-Sent Events (SSE) akan berjalan normal dan responsif.
