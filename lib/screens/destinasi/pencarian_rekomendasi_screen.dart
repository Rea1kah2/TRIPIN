
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/destinasi.dart';
import '../../providers/destinasi_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/safe_network_image.dart';
import '../../widgets/rating_stars.dart';
import 'detail_destinasi_screen.dart';

class PencarianRekomendasiScreen extends StatefulWidget {
  const PencarianRekomendasiScreen({super.key});

  @override
  State<PencarianRekomendasiScreen> createState() =>
      _PencarianRekomendasiScreenState();
}

class _PencarianRekomendasiScreenState
    extends State<PencarianRekomendasiScreen> {
  final TextEditingController _searchController =
  TextEditingController();

  String _kataKunci = '';
  String _kategoriTerpilih = 'Semua';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Destinasi> _filterDestinasi(
      DestinasiProvider provider,
      ) {
    // Ambil seluruh destinasi dari provider.
    final semuaDestinasi = provider.daftarDestinasi;

    // Filter berdasarkan nama, lokasi, dan kategori.
    final hasil = semuaDestinasi.where((destinasi) {
      final nama = destinasi.name.toLowerCase();
      final lokasi = destinasi.location.toLowerCase();
      final kataKunci = _kataKunci.toLowerCase().trim();

      final cocokKataKunci =
          nama.contains(kataKunci) ||
              lokasi.contains(kataKunci);

      final cocokKategori = _kategoriTerpilih == 'Semua' ||
          _labelKategori(
            provider,
            destinasi.kategoriId,
          ) ==
              _kategoriTerpilih;

      return cocokKataKunci && cocokKategori;
    }).toList();

    return hasil;
  }

  String _labelKategori(
      DestinasiProvider provider,
      String kategoriId,
      ) {
    for (final kategori in provider.daftarKategori) {
      if (kategori.id == kategoriId) {
        return kategori.nama;
      }
    }

    return 'Lainnya';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DestinasiProvider>();

    // Rekomendasi: urutkan destinasi berdasarkan rating tertinggi.
    final rekomendasi = List<Destinasi>.from(
      provider.daftarDestinasi,
    )..sort((a, b) => b.rating.compareTo(a.rating));

    // Tampilkan maksimal 5 rekomendasi.
    final limaRekomendasi = rekomendasi.take(5).toList();

    final hasilPencarian = _filterDestinasi(provider);

    final daftarKategori = [
      'Semua',
      ...provider.daftarKategori.map((kategori) => kategori.nama),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cari Wisata',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Kolom pencarian.
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _kataKunci = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Cari nama atau lokasi wisata...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _kataKunci.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _kataKunci = '';
                  });
                },
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Filter kategori.
          const Text(
            'Kategori Wisata',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: daftarKategori.length,
              separatorBuilder: (_, __) =>
              const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final kategori = daftarKategori[index];
                final terpilih =
                    _kategoriTerpilih == kategori;

                return ChoiceChip(
                  label: Text(kategori),
                  selected: terpilih,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: terpilih
                        ? Colors.white
                        : Colors.black87,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _kategoriTerpilih = kategori;
                    });
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Rekomendasi ditampilkan saat belum mencari.
          if (_kataKunci.isEmpty &&
              _kategoriTerpilih == 'Semua') ...[
            const Text(
              'Rekomendasi untuk Kamu',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 245,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: limaRekomendasi.length,
                separatorBuilder: (_, __) =>
                const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final destinasi = limaRekomendasi[index];

                  return SizedBox(
                    width: 210,
                    child: _KartuDestinasi(
                      destinasi: destinasi,
                      kategori: _labelKategori(
                        provider,
                        destinasi.kategoriId,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                DetailDestinasiScreen(
                                  destinasiId: destinasi.id,
                                ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),
          ],

          Text(
            _kataKunci.isEmpty
                ? 'Semua Destinasi'
                : 'Hasil Pencarian',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          if (hasilPencarian.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Destinasi tidak ditemukan.',
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Coba kata kunci atau kategori lain.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            ...hasilPencarian.map((destinasi) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _KartuDestinasi(
                  destinasi: destinasi,
                  kategori: _labelKategori(
                    provider,
                    destinasi.kategoriId,
                  ),
                  horizontal: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            DetailDestinasiScreen(
                              destinasiId: destinasi.id,
                            ),
                      ),
                    );
                  },
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _KartuDestinasi extends StatelessWidget {
  final Destinasi destinasi;
  final String kategori;
  final VoidCallback onTap;
  final bool horizontal;

  const _KartuDestinasi({
    required this.destinasi,
    required this.kategori,
    required this.onTap,
    this.horizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: onTap,
        child: horizontal
            ? Row(
          children: [
            SizedBox(
              width: 125,
              height: 145,
              child: SafeNetworkImage(
                url: destinasi.imageUrl,
                width: 125,
                height: 145,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _InformasiDestinasi(
                  destinasi: destinasi,
                  kategori: kategori,
                ),
              ),
            ),
          ],
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 125,
              width: double.infinity,
              child: SafeNetworkImage(
                url: destinasi.imageUrl,
                width: double.infinity,
                height: 125,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: _InformasiDestinasi(
                destinasi: destinasi,
                kategori: kategori,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InformasiDestinasi extends StatelessWidget {
  final Destinasi destinasi;
  final String kategori;

  const _InformasiDestinasi({
    required this.destinasi,
    required this.kategori,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          destinasi.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          destinasi.location,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          kategori,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 5),
        RatingStars(
          rating: destinasi.rating,
          size: 16,
        ),
      ],
    );
  }
}