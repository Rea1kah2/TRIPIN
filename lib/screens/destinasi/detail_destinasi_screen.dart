
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/destinasi_provider.dart';
import '../../providers/rencana_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/safe_network_image.dart';

class DetailDestinasiScreen extends StatelessWidget {
  final String destinasiId;

  const DetailDestinasiScreen({
    super.key,
    required this.destinasiId,
  });

  String _labelKategori(BuildContext context, String kategoriId) {
    final daftarKategori =
        context.watch<DestinasiProvider>().daftarKategori;

    for (final k in daftarKategori) {
      if (k.id == kategoriId) return k.nama;
    }

    return '';
  }

  // Membuka halaman peta destinasi.
  void _bukaPeta(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppRoutes.destinasiMaps,
      arguments: destinasiId,
    );
  }

  // Membuka halaman ulasan destinasi.
  void _bukaUlasan(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppRoutes.destinasiReview,
      arguments: destinasiId,
    );
  }

  // Menampilkan pilihan rencana perjalanan.
  void _bukaPilihRencana(BuildContext context) {
    final rencanaProvider = context.read<RencanaProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        final daftarRencana = rencanaProvider.daftarRencana;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tambah ke Rencana',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                if (daftarRencana.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Kamu belum punya rencana perjalanan. '
                          'Buat dulu satu.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: daftarRencana.length,
                      itemBuilder: (context, index) {
                        final rencana = daftarRencana[index];

                        final sudahAda = rencana
                            .daftarDestinasiId
                            .contains(destinasiId);

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(rencana.judul),
                          trailing: sudahAda
                              ? const Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                          )
                              : const Icon(
                            Icons.add_circle_outline,
                          ),
                          onTap: sudahAda
                              ? null
                              : () {
                            rencanaProvider
                                .tambahDestinasiKeRencana(
                              rencana.id,
                              destinasiId,
                            );

                            Navigator.pop(sheetContext);

                            showAppSnackbar(
                              context,
                              'Ditambahkan ke "${rencana.judul}"',
                            );
                          },
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);

                      Navigator.pushNamed(
                        context,
                        AppRoutes.rencanaTambah,
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Buat Rencana Baru'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DestinasiProvider>();
    final destinasi = provider.getById(destinasiId);

    if (destinasi == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.pop(context);
        }
      });

      return const SizedBox.shrink();
    }

    final labelKategori =
    _labelKategori(context, destinasi.kategoriId);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.primary,
            iconTheme: const IconThemeData(
              color: Colors.white,
            ),
            actions: [
              IconButton(
                onPressed: () {
                  provider.toggleFavorit(destinasi.id);
                },
                icon: Icon(
                  destinasi.isFavorit
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: destinasi.isFavorit
                      ? AppColors.favoriteActive
                      : Colors.white,
                ),
                tooltip: 'Favorit',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: SafeNetworkImage(
                url: destinasi.imageUrl,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama destinasi.
                  Text(
                    destinasi.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Kategori destinasi.
                  Text(
                    labelKategori,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Lokasi dan jarak.
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${destinasi.location} · '
                              '${destinasi.distanceKm.toStringAsFixed(1)} '
                              'km dari kamu',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Rating dan harga.
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      RatingStars(
                        rating: destinasi.rating,
                        size: 18,
                      ),
                      Text(
                        formatRupiah(destinasi.price),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Deskripsi destinasi.
                  const Text(
                    'Tentang Destinasi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    destinasi.description,
                    style: const TextStyle(
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Tombol peta dan GPS.
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => _bukaPeta(context),
                      icon: const Icon(
                        Icons.location_on_outlined,
                      ),
                      label: const Text('Lihat Peta dan GPS'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(
                          color: AppColors.primary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Tombol ulasan.
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => _bukaUlasan(context),
                      icon: const Icon(
                        Icons.rate_review_outlined,
                      ),
                      label: const Text('Lihat dan Tulis Ulasan'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(
                          color: AppColors.primary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Tombol lama: tambah ke rencana.
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _bukaPilihRencana(context);
                      },
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Tambah ke Rencana'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Informasi tambahan.
                  const Text(
                    'Informasi jam operasional dan fasilitas '
                        'perlu diperiksa melalui sumber resmi '
                        'masing-masing destinasi.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}