TRIPIN

Aplikasi Rekomendasi dan Informasi Destinasi Wisata Berbasis AI

1. Deskripsi Aplikasi

TRIPIN adalah aplikasi mobile yang dikembangkan untuk membantu pengguna mencari informasi dan rekomendasi destinasi wisata dengan lebih mudah. Aplikasi ini dibuat karena banyak orang masih bingung menentukan tempat wisata yang ingin dikunjungi dan harus mencari informasi dari berbagai sumber.

Melalui TRIPIN, pengguna dapat menjelajahi destinasi wisata berdasarkan beberapa kategori, seperti alam, pantai, budaya, kuliner, dan adventure. Aplikasi ini diharapkan dapat membantu pengguna menemukan tempat wisata yang sesuai dengan minat dan kebutuhan mereka.

2. Tujuan Aplikasi

Tujuan pengembangan aplikasi TRIPIN adalah:

1. Memudahkan pengguna dalam mencari informasi destinasi wisata.
2. Membantu pengguna menemukan pilihan wisata berdasarkan kategori.
3. Menyediakan informasi destinasi dalam satu aplikasi.
4. Memberikan pengalaman mencari informasi wisata yang lebih praktis dan mudah digunakan.

3. Teknologi yang Digunakan

Teknologi yang digunakan dalam pengembangan TRIPIN meliputi:

* Flutter: framework untuk membuat aplikasi mobile.
* Dart: bahasa pemrograman yang digunakan untuk mengembangkan aplikasi Flutter.
* Android Studio: aplikasi pengembangan untuk menulis kode, menjalankan, dan menguji aplikasi.
* Express.js: teknologi backend untuk menangani permintaan dari aplikasi, jika digunakan pada versi project ini.

4. Persyaratan Sistem

Sebelum menjalankan TRIPIN, pastikan perangkat pengembangan sudah memiliki:

1. Flutter SDK yang sudah terpasang.
2. Dart SDK yang sesuai dengan versi Flutter.
3. Android Studio atau editor kode yang mendukung Flutter.
4. Emulator Android atau perangkat Android untuk menjalankan aplikasi.
5. Node.js dan dependensi backend apabila project menggunakan server Express.

5. Cara Instalasi dan Menjalankan Aplikasi

Ikuti langkah-langkah berikut untuk menjalankan TRIPIN.

A. Menyiapkan Project

1. Ekstrak file ZIP source code TRIPIN.
2. Buka folder project menggunakan Android Studio.
3. Buka terminal pada folder utama project, yaitu folder yang berisi file pubspec.yaml.
4. Jalankan perintah berikut untuk mengunduh dependensi Flutter:

flutter pub get

Perintah tersebut digunakan untuk memasang paket yang dibutuhkan aplikasi.

B. Menjalankan Aplikasi

1. Jalankan emulator Android atau hubungkan perangkat Android.
2. Pastikan perangkat sudah terdeteksi oleh Flutter dengan perintah:

flutter devices

3. Jalankan aplikasi menggunakan perintah:

flutter run

4. Tunggu sampai proses build selesai dan aplikasi terbuka pada perangkat.

C. Menjalankan Backend

Jika TRIPIN menggunakan backend Express.js, ikuti petunjuk berikut:

1. Buka terminal pada folder backend.
2. Pasang dependensi backend menggunakan perintah:

npm install

3. Jalankan backend menggunakan perintah yang sesuai dengan konfigurasi project, misalnya:

npm run dev

Pastikan alamat server dan konfigurasi koneksi sudah sesuai. Jika aplikasi dijalankan menggunakan emulator Android, alamat server mungkin perlu disesuaikan dengan konfigurasi emulator.

Catatan: Langkah backend hanya diperlukan jika versi aplikasi yang dikumpulkan memang menggunakan backend. Sesuaikan perintah dengan konfigurasi project yang sebenarnya.

6. Data Dummy

Data dummy adalah data contoh yang digunakan untuk mencoba fitur aplikasi selama proses pengembangan dan pengujian.

Contoh data destinasi wisata:

Nama Destinasi	Kategori	Lokasi
Danau Toba	Alam	Sumatera Utara
Pantai Kuta	Pantai	Bali
Istana Maimun	Budaya	Medan, Sumatera Utara

Data tersebut hanya contoh. Daftar data dummy yang sebenarnya harus disesuaikan dengan data yang tersedia di dalam project TRIPIN.

7. Fitur Aplikasi

Fitur TRIPIN disesuaikan dengan implementasi yang tersedia pada source code, antara lain:

* Login: membantu pengguna masuk ke aplikasi jika fitur autentikasi tersedia.
* Register: memungkinkan pengguna membuat akun jika fitur registrasi tersedia.
* Beranda: menampilkan halaman utama aplikasi.
* Kategori wisata: membantu pengguna menjelajahi destinasi berdasarkan kategori.
* Informasi destinasi: menampilkan informasi tempat wisata yang dipilih.
* Rekomendasi wisata: membantu pengguna menemukan pilihan destinasi jika fitur rekomendasi sudah diterapkan.

Fitur yang belum tersedia atau belum berfungsi tidak boleh dianggap sebagai fitur yang sudah selesai.

8. Skenario Simulasi Aplikasi

Skenario simulasi adalah langkah-langkah untuk menunjukkan cara menggunakan aplikasi.

Skenario 1: Masuk ke Aplikasi

1. Buka aplikasi TRIPIN.
2. Masukkan informasi login sesuai data pengujian.
3. Tekan tombol login.
4. Periksa apakah aplikasi berhasil membuka halaman utama.

Skenario 2: Mencari Destinasi Wisata

1. Buka halaman beranda.
2. Pilih kategori wisata yang tersedia.
3. Pilih salah satu destinasi.
4. Periksa apakah informasi destinasi ditampilkan dengan benar.

Skenario 3: Melihat Informasi Destinasi

1. Buka daftar destinasi wisata.
2. Pilih salah satu destinasi.
3. Periksa informasi yang ditampilkan, seperti nama, lokasi, gambar, dan deskripsi jika tersedia.

Skenario tersebut merupakan contoh dan perlu disesuaikan dengan alur aplikasi yang benar-benar berfungsi.

9. Pengujian Aplikasi

Pengujian dilakukan untuk memastikan setiap fitur aplikasi berjalan sesuai dengan yang diharapkan.

Pengujian dapat mencakup:

* Memeriksa apakah aplikasi dapat dibuka.
* Menguji proses login dan registrasi jika tersedia.
* Memeriksa navigasi antarhalaman.
* Memastikan kategori wisata dapat dipilih.
* Memastikan informasi destinasi ditampilkan dengan benar.
* Memeriksa pesan kesalahan ketika pengguna memasukkan data yang tidak sesuai.

Hasil pengujian secara lengkap dicatat dalam matriks pengujian yang dibuat secara terpisah sesuai ketentuan tugas UTS.

10. Struktur Project

Struktur folder utama Flutter umumnya terdiri dari:

* lib/: berisi kode program utama aplikasi.
* assets/: berisi gambar, ikon, atau aset lainnya jika digunakan.
* android/: berisi konfigurasi khusus untuk platform Android.
* test/: berisi file pengujian otomatis jika tersedia.
* pubspec.yaml: berisi informasi project, dependensi, dan konfigurasi aset.

Project juga dapat memiliki folder backend tersendiri jika aplikasi menggunakan server.

Struktur tersebut merupakan gambaran umum. Susunan folder final mengikuti source code TRIPIN yang dikumpulkan.

11. Anggota Kelompok

1. Indah Mutia Trigana
2. M. Ariel Afriza
3. Nazwa Tri Mifthah

Pembagian tugas setiap anggota dijelaskan lebih lengkap pada dokumen ringkas proyek.

12. Penutup

README ini dibuat sebagai panduan untuk memahami tujuan aplikasi TRIPIN, menyiapkan kebutuhan pengembangan, menjalankan aplikasi, dan mencoba fitur-fitur yang tersedia.

Dengan adanya panduan ini, pengguna atau dosen dapat memahami cara menjalankan project dan melakukan simulasi aplikasi dengan lebih mudah.