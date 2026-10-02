# TRIPIN: Ringkasan Proyek

Dokumen ini merangkum seluruh isi proyek TRIPIN per Oktober 2026: tujuan, teknologi dan dependensi,
arsitektur, desain/styling, riwayat pekerjaan, cara menjalankan, serta hal yang belum selesai.
Ditulis untuk seluruh anggota kelompok (terutama yang akan me-review dan me-merge pull request).

---

## 1. Gambaran umum

**TRIPIN** adalah aplikasi mobile (Flutter) untuk menjelajahi dan merencanakan wisata di **Sumatera Utara**.
Pengguna bisa mencari destinasi, melihat detailnya, menyimpan favorit, menyusun rencana perjalanan,
bertanya kepada asisten AI bernama **Tripy**, memberi ulasan, dan melihat semua tempat di peta
berdasarkan posisi mereka saat ini.

| Aspek | Keterangan |
|---|---|
| Platform target | Android (diuji di HP asli). iOS belum dibangun/diuji (CocoaPods belum terpasang di mesin pengembang). |
| Bahasa UI | Indonesia |
| Konten | 32 destinasi nyata di Sumatera Utara, 5 kategori (Alam, Pantai, Budaya, Kuliner, Adventure) |
| Asisten AI | **Tripy** (Gemini lewat backend sendiri), persona santai ala Gen Z |
| Gaya desain | Liquid Glass dengan palet mint-hijau, terang dan gelap |
| Penyimpanan | Lokal di HP (`shared_preferences`); belum ada akun/cloud (lihat bagian 9) |

Repo berisi dua bagian:

```
TRIPIN/
├── lib/                 Aplikasi Flutter
├── test/                Tes Flutter (unit, widget, pratinjau visual)
├── assets/              Foto destinasi (Wikimedia Commons), kredit foto, font Inter
├── scripts/             run_android.sh, pengambil foto Commons
├── backend/             Backend chatbot Tripy (Fastify + TypeScript + Gemini)
├── android/ ios/ ...    Platform
└── PROJECT_OVERVIEW.md  Dokumen ini
```

---

## 2. Teknologi dan dependensi

### 2.1 Aplikasi (Flutter)

| Item | Versi | Catatan |
|---|---|---|
| Flutter | **3.24.1** (stable) | Cukup lama; semua pilihan paket disesuaikan dengan versi ini |
| Dart | 3.5.1 (`sdk: ^3.5.1`) | |
| Android Gradle Plugin / Gradle / Kotlin | 7.3.0 / 7.6.3 / 1.9.24 | Bawaan template proyek |

| Paket | Versi | Fungsi |
|---|---|---|
| `provider` | ^6.1.2 | State management (ChangeNotifier + MultiProvider) |
| `shared_preferences` | ^2.5.3 | Penyimpanan lokal: akun, sesi, favorit, rencana, riwayat chat, ulasan, tema, setelan kaca |
| `http` | ^1.2.2 | Klien HTTP untuk streaming SSE dari backend Tripy |
| `cached_network_image` | ^3.4.1 | Gambar jaringan (`SafeNetworkImage`, sisa komponen lama) |
| `flutter_map` | ^7.0.2 | Peta (OpenStreetMap, tanpa API key) |
| `latlong2` | ^0.9.1 | Tipe koordinat untuk flutter_map |
| `geolocator` | ^13.0.4 | Izin dan posisi GPS |
| `url_launcher` | ^6.3.1 | Membuka rute di Google Maps dan tautan atribusi |
| `cupertino_icons` | ^1.0.8 | Ikon |
| `flutter_lints` (dev) | ^5.0.0 | Aturan lint |

**Penting: `dependency_overrides: geolocator_android: 4.6.1`.** Versi 4.6.2 ke atas memakai
`flutter.compileSdkVersion` di Gradle perpustakaannya (butuh Flutter >= 3.27) dan membuat build Android
gagal di Flutter 3.24.1. Hapus override ini hanya setelah Flutter di-upgrade. Alasan yang sama membuat
`geolocator` dipatok ke ^13 (versi 14 memakai `Color.toARGB32` yang baru ada di Flutter 3.27).

Font **Inter** (Regular 400, Medium 500, SemiBold 600, Bold 700) dibundel di `assets/fonts/`
(lisensi SIL OFL, berkas lisensi ikut disimpan). Di iOS/macOS aplikasi memakai font sistem.

### 2.2 Backend (`backend/`)

| Item | Versi | Fungsi |
|---|---|---|
| Node.js + TypeScript | TS ^7.0.2, ESM | Bahasa dan runtime (dijalankan dengan `tsx`) |
| `fastify` | ^5.12.5 | Server HTTP |
| `@fastify/cors` | ^11.3.0 | CORS |
| `@fastify/rate-limit` | ^11.2.0 | Batas permintaan per IP (default 20/menit) |
| `@google/genai` | ^2.26.0 | Klien Gemini (streaming + function calling) |
| `zod` | ^4.6.5 | Validasi body permintaan dan argumen tool |
| `dotenv` | ^18.0.5 | Membaca `.env` |
| `vitest` (dev) | ^5.0.3 | Tes backend |

Variabel lingkungan (`backend/.env`, **jangan di-commit**; contoh di `backend/.env.example`):
`GEMINI_API_KEY`, `GEMINI_MODEL` (default `gemini-3.8-flash`), `GEMINI_FALLBACK_MODELS`,
`PORT`, `HOST`, `APP_KEY` (opsional), `RATE_LIMIT_PER_MINUTE`.

### 2.3 Layanan dan data eksternal

| Sumber | Dipakai untuk | Syarat |
|---|---|---|
| Google Gemini API (free tier) | Otak Tripy | Key hanya di backend, tidak pernah di app |
| OpenStreetMap (ubin `tile.openstreetmap.org`) | Peta | Atribusi "© OpenStreetMap" tampil di peta. Ubin publik cocok untuk demo, bukan trafik produksi. |
| OpenStreetMap Nominatim + geotag Wikimedia Commons | Koordinat destinasi (diambil sekali saat pengembangan) | |
| Wikimedia Commons | Foto destinasi (CC0 / CC BY / CC BY-SA) | Kredit fotografer wajib; ada di `assets/destinasi/kredit.json` dan layar Profil, Kredit Foto |
| Google Maps (tautan) | Tombol Rute | Hanya membuka tautan |

---

## 3. Arsitektur aplikasi

### 3.1 Struktur `lib/`

```
lib/
├── main.dart                 MultiProvider, tema, rute
├── config/app_config.dart    URL backend (default http://localhost:3000)
├── models/                   User, Destinasi, Kategori, RencanaPerjalanan, ChatMessage, Review
├── data/                     Data dummy: 32 destinasi, 5 kategori, rencana contoh
├── providers/                Auth, Destinasi, Rencana, Theme, Chat, Review, Lokasi
├── services/                 chat_service (SSE), local_storage, location_service,
│                             review_repository, rute, kredit_foto
├── routes/app_routes.dart    Rute bernama
├── screens/                  app_gate, auth, home, destinasi, peta, chat, rencana, profil
├── theme/                    Warna, tema Material, GlassTheme, motion, radius, tipografi
├── utils/                    formatters, geo (Haversine), mini_markdown
└── widgets/                  Komponen Liquid Glass + kartu + review + chat
```

### 3.2 State management

`provider` dengan `ChangeNotifier`. Di `main.dart`:

| Provider | Tanggung jawab |
|---|---|
| `AuthProvider` | Daftar, masuk, keluar, sesi (lokal) |
| `DestinasiProvider` | Daftar destinasi, favorit, pencarian dan filter |
| `RencanaProvider` | CRUD rencana perjalanan (tersimpan lokal) |
| `ThemeProvider` | Mode tema, intensitas kaca, "kurangi transparansi" |
| `ReviewProvider` | Ulasan (lewat `ReviewRepository`), ringkasan, rating tampil |
| `LokasiProvider` | Izin lokasi, posisi, pelacakan hanya saat tab Peta terlihat, jarak nyata |
| `ChatProvider` | Riwayat per pengguna, streaming, status Tripy (proxy dari `AuthProvider`) |

### 3.3 Navigasi

`AppGate` memilih Login atau `BottomNavShell`. Tab bawah (kaca melayang), lima tab:
**Beranda, Jelajah, Peta, Tripy, Profil**. Favorit dibuka dari Profil. Layar lain (detail destinasi,
rencana, ulasan, kredit foto) di-push lewat rute bernama atau `MaterialPageRoute`.

### 3.4 Penyimpanan lokal (`shared_preferences`)

Kunci: `tripin_users`, `tripin_session_user_id`, `tripin_favorit_ids`, `tripin_rencana`,
`tripin_chat_<userId>`, `tripin_reviews`, `tripin_theme_mode`, `tripin_glass_intensity`,
`tripin_reduce_transparency`. Data rusak dibaca aman (dilewati, tidak crash).

---

## 4. Fitur (per layar)

| Layar | Isi |
|---|---|
| **Login / Daftar** | Validasi form, satu kartu kaca di tengah, toast untuk galat |
| **Beranda** | Sapaan, pencarian kapsul, banner (foto Danau Toba), kartu sorotan "Tanya Tripy", filter kategori, rail rekomendasi, "Wisata di Sekitar Kamu" dengan jarak nyata (atau ajakan mengaktifkan lokasi) |
| **Jelajah** | Daftar semua destinasi, pencarian, filter, keadaan kosong dengan aksi "Hapus filter" |
| **Peta** | OpenStreetMap, penanda per kategori, titik posisi + lingkaran akurasi, filter kategori dan radius (10/25/50/100 km), pratinjau tempat (Detail, Rute), daftar Terdekat, tombol ke lokasiku, banner izin |
| **Tripy (Chat)** | Chat streaming, kartu destinasi di jawaban, kartu draf rencana (Simpan sebagai rencana), indikator status, saran awal, hapus percakapan |
| **Detail destinasi** | Foto, kartu info kaca, deskripsi, **ulasan** (ringkasan, tulis/ubah/hapus, daftar), Tambah ke Rencana, Tanya Tripy, kredit foto |
| **Ulasan** | Bintang 1-5 wajib, komentar opsional (maks. 500 karakter), satu ulasan per pengguna per tempat, rating tampil dicampur nilai dasar (bobot 10 suara) |
| **Favorit** | Daftar favorit (dari Profil) |
| **Rencana** | Daftar, tambah, detail/edit, hapus dengan konfirmasi, tambah destinasi lewat sheet kaca |
| **Profil** | Data akun, grup Tampilan (mode tema, slider Transparansi kaca dengan pratinjau, toggle Kurangi transparansi), menu Rencana/Favorit/Kredit Foto, Keluar |

---

## 5. Backend Tripy

### 5.1 API

`POST /api/chat` mengembalikan `text/event-stream`. Satu JSON per event `data:`:

| Event | Arti |
|---|---|
| `status` | Langkah yang sedang dikerjakan ("Tripy lagi nyari tempat…", "Nyusun rencana…", "Tripy lagi antre, nyoba lagi…") |
| `delta` | Potongan teks jawaban |
| `destinasi` | Id destinasi yang tampil sebagai kartu |
| `rencana` | Draf rencana (belum disimpan; menunggu tombol Simpan) |
| `done` / `error` | Selesai / galat berpesan ramah |

Body: `pesan` (riwayat 1-60 pesan, dipangkas ke 12 terakhir) dan `konteks` opsional:
`hariIni`, `favoritIds`, `rencana`, dan **`posisi {lat,lng}`** (opsional, hanya bila pengguna mengizinkan
lokasi; app membulatkan ke 2 desimal, sekitar 1 km). `GET /health` untuk pengecekan.

### 5.2 Cara kerja

- **Function calling** ke katalog nyata: tool `cari_destinasi`, `detail_destinasi`, `daftar_kategori`,
  `usulkan_rencana`. Tool tidak pernah melempar galat (argumen salah dikembalikan sebagai `{error}`).
- **Jarak tidak pernah dikarang.** `jarakDariPenggunaKm` hanya dihitung (Haversine) bila posisi diketahui;
  `urut: terdekat` tanpa posisi jatuh ke urutan rating dan model diberi catatan.
- **Ketahanan:** retry dengan backoff untuk 429/503, **rantai model cadangan** (kuota free tier per model),
  batas total waktu tunggu, teguran sekali bila jawaban menjanjikan kartu rencana tanpa memanggil tool,
  penanganan jawaban diblokir/kosong.
- **Persona Tripy** di `src/ai/systemPrompt.ts`: santai ala Gen Z tetapi sopan dan akurat, aturan data ketat
  (hanya destinasi dari katalog, jangan mengarang jam buka/cuaca/harga).
- **Keamanan:** key Gemini hanya di server, `APP_KEY` opsional (header `x-app-key`), rate limit per IP,
  validasi zod, body maksimal 64 KB. App tidak mengirim nama/email/password.

### 5.3 Katalog

`backend/src/data/destinasi.json` (32 destinasi dengan `lat`/`lng`) adalah salinan data
`lib/data/dummy_destinasi.dart`. **Keduanya harus diubah bersamaan.**

---

## 6. Desain dan styling

Desain mengikuti dokumen internal **Liquid Glass Design System** (`CLAUDE-liquid-glass.md` dan
`liquid-glass-design-system.md`) dengan penyesuaian di bawah. Palet mint-hijau yang sudah ada **tidak diubah**.

### 6.1 Palet dan tema

| Peran | Terang | Gelap |
|---|---|---|
| Seed / primary | `#2E7D6B` | `#7CCBB5` |
| Latar dasar | `#F7FAF8` | `#0F1512` |
| Surface | putih | `#17201C` |
| Teks sekunder | `#586761` | `#A8B8B0` (dua-duanya diuji >= 4,5:1) |
| Bintang | `#FFC107` | `#FFCA5C` |
| Favorit | `#F44336` | `#FF7B72` |

Warna penanda peta per kategori ada di `theme/kategori_warna.dart`. Warna tambahan di
`TripinColors` (ThemeExtension) dan `GlassTheme` (ThemeExtension kedua).

### 6.2 Sistem material kaca

| Konsep | Implementasi |
|---|---|
| **Satu kendali intensitas** | `GlassTheme.intensity` (0-1, default 0.5). Blur = 6 + i×24, alpha tint = 0.06 + i×0.34, rim, kilau, tepi gelap, dan bayangan semuanya diturunkan dari nilai ini. Tidak ada angka blur/alpha di komponen. |
| **Varian** | `bias` -0.25 (tipis), 0 (reguler), +0.25 (tebal) |
| **`GlassPanel`** | Tint + rim 1 px + kilau diagonal + tepi gelap tipis + bayangan lembut **hanya di luar bentuk** (bayangan yang tembus ke bawah isi membuat kartu abu-abu keruh) |
| **Blur sungguhan hanya untuk lapisan melayang** | Tab bar, composer chat, sheet, dialog, toast, tombol bulat di atas foto/peta. Kartu di dalam list memakai kaca ringan tanpa `BackdropFilter` (jauh lebih murah, hampir identik di atas latar mesh). Maksimal 3 layer blur besar bersamaan. |
| **Fallback aksesibilitas** | Setelan **Kurangi transparansi** (solid), High Contrast sistem (solid), Reduce Motion (animasi dimatikan; titik indikator tetap berkedip via opacity) |
| **Latar hidup** | `LiquidBackground`: mesh statis tiga blob mint (hemat baterai), dilukis di tiap layar lewat `GlassScaffold` agar transisi antar layar tetap opaque |
| **Tubuh teks** | Balasan Tripy memakai permukaan solid (bukan kaca) agar mudah dibaca |

### 6.3 Komponen utama

`GlassPanel`, `GlassScaffold`, `LiquidBackground`, `GlassAppBar` (kapsul melayang), `GlassTabBar`
(kapsul melayang + scrim + pil aktif bergeser + haptic), `GlassButton` (prominent / glass / plain /
destructive; satu prominent per layar), `showGlassSheet`, `showGlassAlert`, toast kaca (`showAppSnackbar`),
`KategoriChip`, `DestinasiCard` (foto di bingkai kaca, radius konsentris), `RatingPicker`, `KeadaanKosong`,
`AssistantStatus`, `PressableScale`.

### 6.4 Tipografi, bentuk, gerak

- **Font:** Inter (Android/web), font sistem di iOS/macOS. Angka (harga, jarak, rating) memakai tabular figures.
- **Radius** (`theme/radii.dart`): xs 8, sm 12, md 16, lg 20, xl 28, xxl 36, full kapsul. Radius elemen dalam =
  radius luar dikurangi padding (`konsentris()`, minimum 4).
- **Gerak** (`theme/motion.dart`): 150/250/400 ms, kurva `Cubic(0.32,0.72,0,1)`. Hanya transform dan opacity;
  tidak ada animasi blur. Tekan = skala 0.96/0.985.
- **Target sentuh:** minimal 44 px (ikon tampil 36-40 dengan area sentuh 44-48).

### 6.5 Penyimpangan sadar dari dokumen desain

- Accent memakai **mint yang sudah ada** (bukan biru iOS); tint kaca gelap `#17201C` (bukan `#1C1C1E`).
- Flutter 3.24.1: `Color.withValues` dan `BackdropGroup` belum ada, dipakai `withOpacity`.
- Bar atas dan composer berada di atas latar (bukan di atas isi yang bergulir); efek isi-tembus-kaca ada di tab bar.
- Layar data lokal tidak punya skeleton loading (data instan); keadaan kosong dan galat tetap ada.

---

## 7. Data dan foto

- **32 destinasi** (`d01`-`d32`): 20 awal + 12 tambahan Sumut (Tjong A Fie, Masjid Raya Al-Mashun, Rahmat Gallery,
  Merdeka Walk, Taman Alam Lumbini, Gunung Sibayak, Bukit Holbung, Pantai Parbaba, Air Terjun Efrata,
  Pantai Sorake, Tao Silalahi, Pusuk Buhit).
- **Koordinat** dari OpenStreetMap Nominatim dan geotag Commons. Titik yang mewakili area ditandai
  `lokasiPerkiraan: true` dan diberi keterangan "Titik perkiraan" di app: Danau Toba (Parapat),
  Berastagi, Mangrove Percut, Pantai Sri Mersing, Pasar Ikan Belawan, Kopi Sidikalang.
  Air Terjun Dua Warna dikoreksi ke Deli Serdang (Sibolangit).
- **Foto asli** dari Wikimedia Commons, dibundel di `assets/destinasi/<id>/1.jpg` (JPEG ~1000 px, total ~3,7 MB)
  beserta `kredit.json`. 29 dari 32 tempat punya foto. **Belum punya foto:** d16 Mangrove Percut,
  d17 Pantai Sri Mersing, d23 Rahmat Gallery (tampil "Foto belum tersedia", bukan foto asal).
  Foto Merdeka Walk (Lapangan Merdeka), Bukit Lawang (orangutan Gunung Leuser), Berastagi (Sinabung),
  Taman Simalem (Danau Toba dari Tongging) hanya kecocokan sedang.
- **Rating dan harga tiket** adalah angka awal (placeholder), terutama untuk 12 tempat baru. Perlu diverifikasi.
- **Skrip** `scripts/ambil_foto_commons.py` mencari kandidat paralel dan membuat lembar kontak;
  pemilihan dilakukan manual lewat `scripts/foto_pilihan.json`, lalu `unduh` mengompres dan menulis kredit.

---

## 8. Riwayat pekerjaan (progress)

### Fondasi aplikasi (sebelum sesi ini; ada di riwayat git)
Model dan data dummy; provider (Auth, Destinasi, Rencana); widget reusable; routing + bottom navigation;
Login/Daftar dengan validasi; Beranda, Jelajah, Detail, Favorit; Rencana (daftar, tambah, detail, edit, hapus);
persistensi lokal; **backend chatbot Tripy** (Fastify + Gemini); dark mode + layar chat di aplikasi.

### Pekerjaan pada pull request ini

| Tahap | Hasil |
|---|---|
| **1. Chatbot tersambung di HP asli** | Penyebab error "Tidak bisa terhubung": app memakai alamat emulator (`10.0.2.2`) dan backend belum jalan. Default diganti `localhost` + skrip `scripts/run_android.sh` (`adb reverse`), log diagnosis, panduan di `backend/README.md` |
| **2. Tripy + indikator AI** | Nama asisten **Tripy** (persona Gen Z). Event `status` dari backend; widget `AssistantStatus` (titik bergelombang, status berkilau, avatar berdenyut, baris "Menulis…" saat teks mengalir). Mode Reduce Motion tetap berkedip lewat opacity |
| **3. Fondasi Liquid Glass** | Token `GlassTheme`, `GlassPanel`, latar mesh, `GlassScaffold`, font Inter, setelan tersimpan |
| **4. Lapisan melayang** | Tab bar, bar atas, composer, tombol, sheet, dialog, toast, chip. Perbaikan padding bar atas Beranda |
| **5. Kartu dan chat** | `DestinasiCard` baru (bingkai kaca, radius konsentris), kartu rencana dan draf, bubble chat. **Bug ditemukan:** tint kaca tidak pernah terlukis karena `BoxDecoration` mengabaikan `color` bila ada `gradient`; kini dua lapisan terpisah. Bayangan kartu hanya di luar bentuk |
| **6. Seluruh layar + pengaturan** | Semua layar memakai `GlassScaffold`; Profil punya slider Transparansi + toggle Kurangi transparansi; Login/Daftar kartu kaca; Detail dirombak; keadaan kosong beraksi; warna teks sekunder lolos kontras 4,5:1 |
| **7. Foto destinasi asli** | Foto Commons dibundel untuk 29 tempat + banner; layar Kredit Foto; keterangan fotografer di Detail |
| **8. Review (bintang + komentar)** | Dibangun dari nol (sebelumnya tidak ada). Tanpa unggah foto (keputusan: terlalu berat untuk tahap ini). Repositori lokal yang bisa diganti Firestore |
| **9. Maps Sumatera Utara** | Peta OSM, posisi live, filter, pratinjau, rute, jarak nyata di seluruh app dan di Tripy; 12 destinasi baru; tab Favorit dipindah ke Profil |

### Pengujian

- **Flutter:** 101 tes lolos (+16 tes pratinjau visual yang dilewati kecuali `PRATINJAU_DIR` diisi).
- **Backend:** 65 tes lolos, `tsc --noEmit` bersih.
- `flutter analyze` bersih. APK debug berhasil dibangun (Android).
- Seluruh fitur diuji manual di HP asli oleh pemilik proyek.

---

## 9. Hal yang belum selesai dan catatan penting

| Hal | Status / catatan |
|---|---|
| **Akun masih lokal** | Akun disimpan di `shared_preferences` dan **password tersimpan polos**. Data hilang bila aplikasi di-uninstall. Rencana: Firebase Auth (Email/Password) + Firestore. Butuh proyek Firebase dan `google-services.json` dari pemilik repo, `minSdk 23`. |
| **Ulasan masih lokal** | Hanya terlihat di perangkat itu. `ReviewRepository` sudah disiapkan agar implementasi Firestore tinggal menggantikan `LocalReviewRepository`. |
| **Favorit, rencana, chat** | Lokal per perangkat |
| **Backend harus dijalankan manual** | `cd backend && npm run dev`. Belum ada deploy; HP harus sampai ke laptop (`adb reverse` atau IP LAN). Untuk dipakai di luar jaringan lokal perlu di-host (Render/Railway) dan `TRUST_PROXY=true`. |
| **Galeri 3 foto per tempat** | Belum; sekarang 1 foto per tempat |
| **3 tempat tanpa foto** | d16, d17, d23 |
| **Koordinat perlu verifikasi** | Lihat daftar titik perkiraan di bagian 7 |
| **iOS** | Izin lokasi di `Info.plist` sudah ditambahkan, tetapi belum pernah dibangun/diuji |
| **Ubin peta** | Server OSM publik; pertimbangkan penyedia ubin sendiri bila dipakai luas |
| **Marker menumpuk di pusat Medan** saat zoom jauh | Belum ada clustering |
| **Upgrade Flutter** | Setelah Flutter >= 3.27: hapus override `geolocator_android`, naikkan `geolocator`, tinjau AGP |

---

## 10. Cara menjalankan

### Prasyarat
Flutter 3.24.1, Android SDK (+ `adb`), Node.js (backend), HP Android dengan USB debugging.

### Backend

```bash
cd backend
npm install
cp .env.example .env          # isi GEMINI_API_KEY (gratis: https://aistudio.google.com/apikey)
npm run dev                   # http://localhost:3000
curl localhost:3000/health
npm test && npm run typecheck
```

### Aplikasi

```bash
flutter pub get
./scripts/run_android.sh      # adb reverse tcp:3000 tcp:3000 lalu flutter run (HP via USB / emulator)
```

Tanpa kabel (satu Wi-Fi): `flutter run --dart-define=API_BASE_URL=http://<IP-LAN-laptop>:3000`.
Bila `APP_KEY` diisi di backend: tambahkan `--dart-define=APP_KEY=<nilai sama>`.
Setelah mengubah paket, izin, atau aset: jalankan ulang penuh (bukan hot reload).

### Tes

```bash
flutter analyze
flutter test
# pratinjau visual (render komponen ke PNG dengan font asli):
PRATINJAU_DIR=/tmp/pratinjau flutter test test/visual/pratinjau_test.dart
```

### Memperbarui foto destinasi

```bash
python3 scripts/ambil_foto_commons.py cepat --kerja /tmp/foto --ids d23   # cari kandidat + lembar kontak
# pilih foto di scripts/foto_pilihan.json, lalu:
python3 scripts/ambil_foto_commons.py unduh --kerja /tmp/foto
```

---

## 11. Lisensi dan kredit

- Font **Inter**: SIL Open Font License 1.1 (`assets/fonts/Inter-LICENSE.txt`).
- Peta: © OpenStreetMap contributors (ODbL).
- Foto destinasi: Wikimedia Commons, lisensi per foto di `assets/destinasi/kredit.json`
  (CC0 / CC BY / CC BY-SA). Lisensi foto tidak berlaku untuk kode aplikasi.
- Proyek ini adalah tugas kelompok mata kuliah Pemrograman Mobile.
