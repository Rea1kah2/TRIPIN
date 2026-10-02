import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/destinasi.dart';
import '../../providers/destinasi_provider.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _pesan = [
    {
      'isUser': false,
      'text':
      'Halo! Selamat datang di TRIPIN. Aku siap membantu kamu mencari '
          'destinasi wisata, melihat harga tiket, mencari tempat terdekat, '
          'dan mendapatkan rekomendasi liburan. Ada yang ingin kamu tanyakan?',
    },
  ];

  // Daftar pertanyaan yang tersedia untuk pengguna.
  final List<String> _pertanyaanUmum = [
    // Pertanyaan umum
    'Halo, apa yang bisa kamu bantu?',
    'Apa itu aplikasi TRIPIN?',
    'Apa saja fitur yang tersedia di TRIPIN?',
    'Bagaimana cara menggunakan TRIPIN?',
    'Bagaimana cara mencari tempat wisata?',
    'Bagaimana cara memilih tempat wisata untuk liburan?',

    // Kategori destinasi
    'Rekomendasi wisata pantai',
    'Rekomendasi wisata gunung',
    'Rekomendasi wisata danau',
    'Rekomendasi wisata air terjun',
    'Rekomendasi wisata alam',
    'Rekomendasi wisata budaya',
    'Rekomendasi wisata sejarah',
    'Rekomendasi wisata religi',
    'Rekomendasi wisata taman',
    'Rekomendasi wisata rekreasi',
    'Rekomendasi wisata keluarga',
    'Rekomendasi wisata kuliner',
    'Rekomendasi tempat camping',
    'Rekomendasi tempat dengan pemandangan indah',
    'Tampilkan semua destinasi wisata',

    // Harga dan tiket
    'Wisata gratis',
    'Berapa harga tiket masuk tempat wisata?',
    'Rekomendasi wisata murah',
    'Wisata dengan tiket di bawah Rp50.000',
    'Wisata dengan tiket di bawah Rp100.000',
    'Tempat wisata dengan tiket paling mahal',
    'Bagaimana cara melihat harga tiket?',

    // Rating dan rekomendasi
    'Destinasi dengan rating tertinggi',
    'Rekomendasi tempat wisata terbaik berdasarkan rating',
    'Tempat wisata yang cocok untuk liburan',
    'Tempat wisata yang populer',
    'Bagaimana cara melihat rating destinasi?',
    'Bagaimana cara mendapatkan rekomendasi wisata?',

    // Lokasi dan peta
    'Tempat wisata terdekat',
    'Bagaimana cara melihat lokasi wisata di peta?',
    'Bagaimana cara mendapatkan rute ke tempat wisata?',
    'Bagaimana cara menggunakan GPS?',
    'Bagaimana cara mencari wisata berdasarkan kota atau provinsi?',

    // Favorit
    'Bagaimana cara melihat destinasi favorit?',
    'Bagaimana cara menambahkan destinasi ke favorit?',
    'Bagaimana cara menghapus destinasi dari favorit?',
    'Apa fungsi fitur favorit?',

    // Informasi destinasi
    'Bagaimana cara melihat detail destinasi?',
    'Bagaimana cara melihat deskripsi tempat wisata?',
    'Bagaimana cara mengetahui fasilitas wisata?',
    'Bagaimana cara mengetahui jam buka wisata?',
    'Bagaimana cara melihat foto destinasi?',
    'Bagaimana cara melihat alamat tempat wisata?',

    // Ulasan
    'Bagaimana cara memberikan rating dan ulasan?',
    'Bagaimana cara menambahkan foto pada ulasan?',
    'Bagaimana cara melihat ulasan pengunjung lain?',
    'Bagaimana cara mengetahui pengalaman pengunjung lain?',

    // Rencana perjalanan
    'Bagaimana cara membuat rencana perjalanan?',
    'Bagaimana cara menambahkan destinasi ke rencana perjalanan?',
    'Bagaimana cara melihat rencana perjalanan?',
    'Bagaimana cara menghapus rencana perjalanan?',

    // Akun
    'Bagaimana cara membuat akun?',
    'Bagaimana cara login ke TRIPIN?',
    'Bagaimana cara logout?',
    'Apakah fitur favorit membutuhkan akun?',
    'Apa yang harus dilakukan jika gagal login?',

    // Chatbot
    'Apa saja yang bisa ditanyakan kepada chatbot?',
    'Rekomendasi wisata berdasarkan anggaran',
    'Bantu aku memilih tempat liburan',
    'Kenapa destinasi yang dicari tidak ditemukan?',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _gulirKeBawah() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  String _normalisasi(String teks) {
    return teks
        .toLowerCase()
        .replaceAll(RegExp(r'[?!.,]'), '')
        .trim();
  }

  bool _mengandungSalahSatu(
      String teks,
      List<String> kataKunci,
      ) {
    return kataKunci.any((kata) => teks.contains(kata));
  }

  double? _angkaHarga(dynamic harga) {
    final teks = harga.toString().replaceAll('.', '').replaceAll(',', '');
    final angka = RegExp(r'\d+').firstMatch(teks);

    if (angka == null) return null;

    return double.tryParse(angka.group(0)!);
  }

  String _formatHarga(dynamic harga) {
    final angka = _angkaHarga(harga);

    if (angka == null) return harga.toString();
    if (angka == 0) return 'Gratis';

    return 'Rp${angka.toInt()}';
  }

  String _daftarNama(List<Destinasi> destinasi) {
    if (destinasi.isEmpty) {
      return 'Belum ada destinasi yang sesuai dengan kriteria tersebut '
          'di data aplikasi saat ini.';
    }

    return destinasi
        .take(8)
        .map((d) => '• ${d.name}')
        .join('\n');
  }

  String _jawabanDestinasi(List<Destinasi> destinasi) {
    if (destinasi.isEmpty) {
      return 'Maaf, belum ada destinasi yang cocok di data TRIPIN.';
    }

    return 'Berikut destinasi yang bisa kamu pertimbangkan:\n\n'
        '${_daftarNama(destinasi)}\n\n'
        'Pilih salah satu destinasi pada aplikasi untuk melihat '
        'informasi lengkapnya.';
  }

  List<Destinasi> _filterHarga(
      DestinasiProvider provider,
      double batas,
      ) {
    return provider.daftarDestinasi.where((destinasi) {
      final harga = _angkaHarga(destinasi.price);

      return harga != null && harga <= batas;
    }).toList();
  }

  String _buatJawaban(
      String pertanyaan,
      DestinasiProvider provider,
      ) {
    final teks = _normalisasi(pertanyaan);
    final semua = provider.daftarDestinasi;

    if (teks.isEmpty) {
      return 'Silakan tuliskan pertanyaan yang ingin kamu tanyakan.';
    }

    // Salam.
    if (_mengandungSalahSatu(teks, [
      'halo',
      'hai',
      'hello',
      'selamat pagi',
      'selamat siang',
      'selamat sore',
      'selamat malam',
    ])) {
      return 'Halo! Aku chatbot TRIPIN. Kamu bisa bertanya tentang '
          'kategori wisata, harga tiket, rating, lokasi, favorit, '
          'dan rekomendasi destinasi.';
    }

    // Informasi aplikasi.
    if (_mengandungSalahSatu(teks, [
      'apa itu aplikasi tripin',
      'tentang tripin',
    ])) {
      return 'TRIPIN adalah aplikasi perjalanan yang membantu pengguna '
          'menemukan destinasi wisata, melihat informasi tempat wisata, '
          'mencari lokasi melalui peta, menyimpan favorit, memberikan '
          'ulasan, dan menyusun rencana perjalanan.';
    }

    if (_mengandungSalahSatu(teks, [
      'fitur',
      'cara menggunakan tripin',
      'bisa kamu bantu',
      'bisa ditanyakan',
    ])) {
      return 'Fitur TRIPIN meliputi pencarian destinasi, kategori wisata, '
          'rekomendasi, informasi harga dan rating, peta dan lokasi, '
          'favorit, ulasan pengunjung, serta rencana perjalanan. '
          'Kamu juga bisa memilih pertanyaan yang tersedia di bawah.';
    }

    // Semua destinasi.
    if (_mengandungSalahSatu(teks, [
      'semua destinasi',
      'seluruh destinasi',
      'semua tempat wisata',
      'tampilkan destinasi',
    ])) {
      return _jawabanDestinasi(semua);
    }

    // Wisata gratis.
    if (_mengandungSalahSatu(teks, [
      'gratis',
      'tanpa tiket',
      'tidak berbayar',
    ])) {
      final gratis = semua.where((d) {
        return _angkaHarga(d.price) == 0;
      }).toList();

      return 'Berikut destinasi yang tercatat memiliki harga Rp0 '
          'di data aplikasi:\n\n${_daftarNama(gratis)}';
    }

    // Wisata di bawah Rp50.000.
    if (teks.contains('50.000') || teks.contains('50000')) {
      return 'Destinasi dengan harga tiket tercatat maksimal Rp50.000:\n\n'
          '${_daftarNama(_filterHarga(provider, 50000))}';
    }

    // Wisata di bawah Rp100.000.
    if (teks.contains('100.000') || teks.contains('100000')) {
      return 'Destinasi dengan harga tiket tercatat maksimal Rp100.000:\n\n'
          '${_daftarNama(_filterHarga(provider, 100000))}';
    }

    // Harga tiket paling mahal.
    if (_mengandungSalahSatu(teks, [
      'tiket paling mahal',
      'harga paling mahal',
      'termahal',
    ])) {
      final denganHarga = semua.where((d) {
        return _angkaHarga(d.price) != null;
      }).toList();

      if (denganHarga.isEmpty) {
        return 'Informasi harga tiket belum tersedia pada data destinasi.';
      }

      denganHarga.sort((a, b) =>
          _angkaHarga(b.price)!.compareTo(_angkaHarga(a.price)!));

      final d = denganHarga.first;

      return 'Destinasi dengan harga tiket tertinggi yang tercatat '
          'adalah ${d.name}, dengan harga ${_formatHarga(d.price)}.';
    }

    // Harga tiket dan wisata murah.
    if (_mengandungSalahSatu(teks, [
      'harga tiket',
      'harga masuk',
      'harga wisata',
      'tiket masuk',
      'harga destinasi',
      'lihat harga',
      'wisata murah',
      'anggaran',
      'budget',
    ])) {
      final murah = List<Destinasi>.from(semua)
        ..sort((a, b) {
          final hargaA = _angkaHarga(a.price) ?? double.infinity;
          final hargaB = _angkaHarga(b.price) ?? double.infinity;

          return hargaA.compareTo(hargaB);
        });

      if (murah.isEmpty) {
        return 'Belum ada data destinasi yang tersedia.';
      }

      return 'Berikut beberapa destinasi dengan harga tiket terendah '
          'berdasarkan data yang tersedia:\n\n'
          '${murah.take(5).map((d) => '• ${d.name} — '
          '${_formatHarga(d.price)}').join('\n')}\n\n'
          'Periksa kembali harga di detail destinasi karena harga '
          'dapat berubah.';
    }

    // Rating tertinggi.
    if (_mengandungSalahSatu(teks, [
      'rating tertinggi',
      'rating terbaik',
      'rating paling tinggi',
    ])) {
      final urut = List<Destinasi>.from(semua)
        ..sort((a, b) => b.rating.compareTo(a.rating));

      if (urut.isEmpty) {
        return 'Belum ada data destinasi.';
      }

      return 'Destinasi dengan rating tertinggi berdasarkan data '
          'aplikasi:\n\n'
          '${urut.take(5).map((d) =>
      '• ${d.name} — ${d.rating}').join('\n')}';
    }

    // Rekomendasi berdasarkan rating.
    if (_mengandungSalahSatu(teks, [
      'rekomendasi',
      'pilih tempat',
      'tempat liburan',
      'tempat wisata terbaik',
      'tempat wisata populer',
      'liburan',
    ])) {
      final urut = List<Destinasi>.from(semua)
        ..sort((a, b) => b.rating.compareTo(a.rating));

      return 'Kamu bisa mempertimbangkan destinasi dengan rating '
          'tertinggi berikut:\n\n${_daftarNama(urut)}\n\n'
          'Rating mengikuti data aplikasi dan belum tentu menjadi '
          'pilihan yang cocok untuk semua orang.';
    }

    // Destinasi terdekat.
    if (_mengandungSalahSatu(teks, [
      'terdekat',
      'paling dekat',
      'dekat dari sini',
    ])) {
      return 'Berikut destinasi dengan nilai jarak terkecil '
          'di data aplikasi:\n\n'
          '${_daftarNama(provider.destinasiTerdekat)}\n\n'
          'Untuk jarak dari posisi kamu saat ini, gunakan fitur '
          'peta atau GPS.';
    }

    // Peta dan GPS.
    if (_mengandungSalahSatu(teks, [
      'peta',
      'maps',
      'rute',
      'arah jalan',
      'gps',
      'lokasi wisata',
      'alamat',
    ])) {
      return 'Untuk melihat lokasi dan rute wisata, buka detail '
          'destinasi yang kamu pilih, lalu gunakan fitur peta atau '
          'Maps jika tersedia. Aktifkan izin lokasi perangkat jika '
          'fitur tersebut memerlukan GPS.';
    }

    // Favorit.
    if (_mengandungSalahSatu(teks, [
      'favorit',
      'favorite',
      'simpan tempat',
    ])) {
      return 'Untuk mengelola destinasi favorit, buka daftar destinasi '
          'dan tekan ikon hati pada tempat yang kamu inginkan. Tekan '
          'kembali ikon tersebut untuk menghapusnya dari favorit. '
          'Buka halaman Favorit untuk melihat tempat yang disimpan.';
    }

    // Ulasan dan rating.
    if (_mengandungSalahSatu(teks, [
      'ulasan',
      'review',
      'rating pengunjung',
      'pengalaman pengunjung',
      'foto pada ulasan',
    ])) {
      return 'Untuk memberi ulasan, buka detail destinasi dan cari '
          'fitur ulasan atau rating. Isi rating dan komentar, lalu '
          'tambahkan foto jika fitur tersebut tersedia. Kamu juga '
          'dapat melihat ulasan pengguna lain pada halaman destinasi.';
    }

    // Rencana perjalanan.
    if (_mengandungSalahSatu(teks, [
      'rencana perjalanan',
      'rencana liburan',
      'itinerary',
      'jadwal liburan',
    ])) {
      return 'Buka menu Rencana Perjalanan pada aplikasi TRIPIN. '
          'Gunakan fitur tambah rencana untuk menyusun perjalanan '
          'dan memilih destinasi yang ingin dikunjungi. Rencana yang '
          'sudah dibuat dapat dilihat kembali melalui menu tersebut.';
    }

    // Akun.
    if (_mengandungSalahSatu(teks, [
      'buat akun',
      'daftar akun',
      'registrasi',
      'login',
      'masuk akun',
      'gagal login',
      'logout',
      'keluar akun',
    ])) {
      return 'Untuk menggunakan fitur akun, buka halaman profil '
          'atau autentikasi. Pilih Daftar untuk membuat akun baru, '
          'atau Login jika sudah memiliki akun. Untuk keluar, gunakan '
          'fitur Logout. Jika gagal login, periksa kembali email '
          'dan kata sandi yang dimasukkan.';
    }

    // Cari kategori berdasarkan kategori yang tersimpan.
    final kategoriCocok = provider.daftarKategori.where((kategori) {
      final nama = kategori.nama.toLowerCase();
      return teks.contains(nama);
    }).toList();

    if (kategoriCocok.isNotEmpty) {
      final kategori = kategoriCocok.first;
      final hasil = semua
          .where((d) => d.kategoriId == kategori.id)
          .toList();

      return 'Berikut destinasi kategori ${kategori.nama} '
          'yang tersedia di TRIPIN:\n\n${_daftarNama(hasil)}';
    }

    // Cari nama destinasi.
    final destinasiCocok = semua.where((d) {
      return teks.contains(d.name.toLowerCase());
    }).toList();

    if (destinasiCocok.isNotEmpty) {
      return destinasiCocok.map((d) {
        return 'Nama: ${d.name}\n'
            'Lokasi: ${d.location}\n'
            'Harga tiket: ${_formatHarga(d.price)}\n'
            'Rating: ${d.rating}\n'
            'Jarak tercatat: ${d.distanceKm} km\n\n'
            'Buka detail destinasi di aplikasi untuk melihat '
            'informasi lainnya.';
      }).join('\n\n');
    }

    // Informasi detail destinasi.
    if (_mengandungSalahSatu(teks, [
      'jam buka',
      'jam operasional',
      'fasilitas',
      'deskripsi',
      'foto destinasi',
      'detail destinasi',
    ])) {
      return 'Informasi tersebut dapat dilihat pada halaman detail '
          'destinasi jika tersedia. Chatbot ini menggunakan data '
          'lokal TRIPIN, sehingga tidak bisa memastikan informasi '
          'yang belum tercatat di aplikasi.';
    }

    // Pencarian berdasarkan wilayah.
    if (_mengandungSalahSatu(teks, [
      'kota',
      'provinsi',
      'berdasarkan lokasi',
      'berdasarkan daerah',
    ])) {
      return 'Gunakan kolom pencarian destinasi untuk mencari tempat '
          'berdasarkan nama atau informasi lokasi yang tersedia. '
          'Hasilnya bergantung pada data yang tersimpan di TRIPIN.';
    }

    // Jawaban jika pertanyaan belum dikenali.
    return 'Maaf, aku belum memahami pertanyaan tersebut. Kamu bisa '
        'memilih pertanyaan yang tersedia di bawah, atau mencoba '
        'menanyakan kategori wisata, harga tiket, rating, lokasi, '
        'favorit, ulasan, dan rencana perjalanan.';
  }

  void _kirimPesan([String? pertanyaanPilihan]) {
    final pertanyaan =
    (pertanyaanPilihan ?? _controller.text).trim();

    if (pertanyaan.isEmpty) return;

    final provider = context.read<DestinasiProvider>();
    final jawaban = _buatJawaban(pertanyaan, provider);

    setState(() {
      _pesan.add({
        'isUser': true,
        'text': pertanyaan,
      });

      _pesan.add({
        'isUser': false,
        'text': jawaban,
      });

      _controller.clear();
    });

    _gulirKeBawah();
  }

  Widget _itemPesan(Map<String, dynamic> pesan) {
    final isUser = pesan['isUser'] as bool;
    final warna = Theme.of(context).colorScheme;

    return Align(
      alignment:
      isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 310),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: isUser
              ? warna.primary
              : warna.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          pesan['text'] as String,
          style: TextStyle(
            color: isUser ? warna.onPrimary : warna.onSurface,
            height: 1.45,
          ),
        ),
      ),
    );
  }

  Widget _daftarPertanyaan() {
    return SizedBox(
      height: 45,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _pertanyaanUmum.length,
        separatorBuilder: (_, __) =>
        const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ActionChip(
            label: Text(_pertanyaanUmum[index]),
            onPressed: () {
              _kirimPesan(_pertanyaanUmum[index]);
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              radius: 17,
              child: Icon(Icons.smart_toy_outlined),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chatbot TRIPIN',
                  style: TextStyle(fontSize: 17),
                ),
                Text(
                  'Asisten wisata',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _pesan.length,
                itemBuilder: (context, index) {
                  return _itemPesan(_pesan[index]);
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 19,
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Pilih pertanyaan atau ketik pesanmu',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            _daftarPertanyaan(),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _kirimPesan(),
                      decoration: InputDecoration(
                        hintText: 'Tanyakan sesuatu...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding:
                        const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => _kirimPesan(),
                    icon: const Icon(Icons.send),
                    tooltip: 'Kirim pesan',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}