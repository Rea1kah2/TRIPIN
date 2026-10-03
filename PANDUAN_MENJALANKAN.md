# Panduan Menjalankan TRIPIN di Lokal

Untuk anggota tim yang ingin menjalankan aplikasi **beserta chatbot Tripy** di komputernya.
Ringkasan proyek ada di [`PROJECT_OVERVIEW.md`](PROJECT_OVERVIEW.md).

## 1. Yang perlu disiapkan

| Kebutuhan | Versi | Catatan |
|---|---|---|
| Flutter | **3.24.1** | Versi lain (terutama >= 3.27) bisa membuat build gagal. Lihat langkah 1.1 |
| JDK | **17** | JDK 21 tidak cocok dengan Gradle 7.6.3 proyek ini |
| Android Studio / SDK | terbaru | Untuk `adb`, emulator, dan build Android |
| Node.js | 18 atau lebih baru | Untuk backend chatbot |
| API key Gemini | gratis | https://aistudio.google.com/apikey |
| HP Android + kabel USB | | Atau emulator Android |

### 1.1 Memasang Flutter 3.24.1

```bash
git clone https://github.com/flutter/flutter.git -b 3.24.1 ~/develop/flutter
# tambahkan ~/develop/flutter/bin ke PATH, lalu:
flutter --version      # harus menampilkan Flutter 3.24.1 dan Dart 3.5.1
flutter doctor         # selesaikan masalah yang ditandai (SDK Android, lisensi, dll.)
```

Windows: sama, lalu tambahkan `C:\...\flutter\bin` ke Environment Variables > Path.

## 2. Ambil kode

Gunakan cabang **`main`** dari repo sementara `https://github.com/Rea1kah2/tripin-new.git`.
Cabang `master` repo tim memakai konfigurasi lain (Gradle 8.x, butuh Flutter >= 3.44) dan tidak cocok
dengan Flutter 3.24.1.

```bash
git clone https://github.com/Rea1kah2/tripin-new.git
cd tripin-new
```

## 3. Jalankan backend chatbot

```bash
cd backend
npm install
```

Salin `.env.example` menjadi `.env` (Mac/Linux: `cp .env.example .env`, Windows: `copy .env.example .env`),
lalu isi baris `GEMINI_API_KEY=` dengan API key. Baris lain biarkan default.

> `.env` berisi rahasia dan **tidak ikut di repo**. Jangan di-commit dan jangan dikirim ke grup.
> Minta key lewat pesan pribadi atau buat sendiri di AI Studio.

```bash
npm run dev
```

Cek di terminal lain: `curl localhost:3000/health` (Windows PowerShell: `curl.exe localhost:3000/health`,
atau buka di browser). Hasil yang benar:

```json
{"status":"ok","asisten":"siap", ...}
```

Bila `asisten` bukan `siap`, API key kosong atau salah: perbaiki `.env`, lalu restart backend.
Biarkan terminal ini tetap berjalan selama memakai aplikasi.

## 4. Jalankan aplikasi

Backend ada di laptop, sedangkan aplikasi berjalan di HP/emulator. Di Android, `localhost` berarti
**perangkat itu sendiri**, bukan laptop. Karena itu perangkat perlu dihubungkan ke backend. Pilih satu cara.

### Cara A: HP asli lewat kabel USB (paling mudah)

1. Di HP: aktifkan **USB debugging** (Opsi Pengembang), colok kabel, setujui dialog "Allow USB debugging".
2. Cek `adb devices`: HP harus muncul dengan status `device`.
   Bila `adb` tidak dikenali, pakai path lengkapnya:
   Mac `~/Library/Android/sdk/platform-tools/adb`, Windows `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`.
3. Pasang jembatan port: `adb reverse tcp:3000 tcp:3000`
4. Jalankan aplikasi dari folder root proyek:

```bash
flutter pub get
flutter run
```

Di Mac/Linux, langkah 3 dan 4 bisa diganti satu perintah: `./scripts/run_android.sh`.
Skrip itu berformat `.sh`, jadi di Windows jalankan perintah manualnya.

**Jembatan `adb reverse` hilang** setiap kabel dicabut/dicolok ulang, HP restart, atau `adb` dimulai ulang.
Ulangi langkah 3 bila chat kembali gagal. Cek dengan `adb reverse --list` (harus ada `tcp:3000 tcp:3000`).

### Cara B: HP asli lewat Wi-Fi (tanpa kabel)

1. HP dan laptop harus di Wi-Fi yang sama (jaringan publik/kampus sering memblokir antarperangkat).
2. Cari IP laptop: Windows `ipconfig` (IPv4 Address), Mac `ipconfig getifaddr en0`. Misalnya `192.168.1.10`.
3. Izinkan Node.js di firewall untuk jaringan privat (port 3000).
4. Tes dari browser HP: `http://192.168.1.10:3000/health` harus menampilkan JSON di atas.
5. Jalankan: `flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000`

Cara ini membuka backend ke jaringan lokal. Pakai hanya di jaringan yang dipercaya.

### Cara C: Emulator Android

Cara A juga berlaku di emulator. Alternatifnya tanpa `adb reverse`:
`flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000` (`10.0.2.2` = laptop dari dalam emulator).

### Catatan lain

- Bila `APP_KEY` diisi di `backend/.env`, tambahkan `--dart-define=APP_KEY=<nilai sama>` pada `flutter run`.
- Setelah mengubah paket, izin, atau konfigurasi: hentikan aplikasi dan jalankan ulang penuh (bukan hot reload).
- Fitur Peta meminta izin lokasi saat tab Peta dibuka. Tanpa izin, peta tetap jalan tetapi tanpa posisi dan jarak.

## 5. Bila chat menampilkan "Tidak bisa terhubung ke asisten"

Lihat log di konsol `flutter run`: baris `ChatService: gagal menghubungi <alamat> (...)` menunjukkan
alamat yang dicoba dan penyebabnya. Periksa berurutan:

| Cek | Cara | Bila gagal |
|---|---|---|
| Backend hidup | `curl localhost:3000/health` | Jalankan `npm run dev` di folder `backend` |
| API key terpasang | Respons berisi `"asisten":"siap"` | Isi `GEMINI_API_KEY`, restart backend |
| Jembatan USB | `adb reverse --list` memuat `tcp:3000` | Ulangi `adb reverse tcp:3000 tcp:3000` |
| Alamat cocok dengan cara yang dipakai | Log `gagal menghubungi ...` | `localhost` = Cara A, IP LAN = Cara B, `10.0.2.2` = Cara C |
| `Connection refused` | Tidak ada yang mendengarkan di alamat itu | Hampir selalu jembatan USB belum dipasang atau backend mati |
| Port bentrok | Program lain memakai port 3000 | Ganti `PORT` di `.env` dan sesuaikan semua alamat |
| `APP_KEY` | Diisi di `.env` tetapi tidak di aplikasi | Tambahkan `--dart-define=APP_KEY=...` atau kosongkan di `.env` |

Bila chat tersambung tetapi jawaban gagal atau lama: Gemini free tier dibatasi per menit. Backend
otomatis mencoba model cadangan (`GEMINI_FALLBACK_MODELS`); tunggu sebentar lalu coba lagi. Nama model
bisa berubah, jadi cek yang tersedia di Google AI Studio (halaman Rate limits) dan sesuaikan `.env`.
Penyebab galat dari Gemini tertulis di terminal tempat `npm run dev` berjalan.

## 6. Menjalankan tes (opsional)

```bash
flutter analyze
flutter test
cd backend && npm test && npm run typecheck
```
