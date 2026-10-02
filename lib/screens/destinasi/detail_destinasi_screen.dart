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

  const DetailDestinasiScreen({super.key, required this.destinasiId});

  String _labelKategori(BuildContext context, String kategoriId) {
    final daftarKategori = context.watch<DestinasiProvider>().daftarKategori;
    for (final k in daftarKategori) {
      if (k.id == kategoriId) return k.nama;
    }
    return '';
  }

  void _bukaPilihRencana(BuildContext context) {
    final rencanaProvider = context.read<RencanaProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (daftarRencana.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Kamu belum punya rencana perjalanan. Buat dulu satu.',
                      style: TextStyle(color: context.tripin.textSecondary),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: daftarRencana.length,
                      itemBuilder: (context, index) {
                        final rencana = daftarRencana[index];
                        final sudahAda =
                            rencana.daftarDestinasiId.contains(destinasiId);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(rencana.judul),
                          trailing: sudahAda
                              ? Icon(Icons.check_circle, color: context.colors.primary)
                              : const Icon(Icons.add_circle_outline),
                          onTap: sudahAda
                              ? null
                              : () {
                                  rencanaProvider.tambahDestinasiKeRencana(
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
                      Navigator.pushNamed(context, AppRoutes.rencanaTambah);
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
      WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.pop(context));
      return const SizedBox.shrink();
    }

    final labelKategori = _labelKategori(context, destinasi.kategoriId);
    final primary = context.colors.primary;
    final tripin = context.tripin;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: context.colors.surface,
            iconTheme: IconThemeData(color: context.colors.onSurface),
            actions: [
              IconButton(
                onPressed: () => provider.toggleFavorit(destinasi.id),
                icon: Icon(
                  destinasi.isFavorit ? Icons.favorite : Icons.favorite_border,
                  color: destinasi.isFavorit ? tripin.favoriteActive : context.colors.onSurface,
                ),
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
                  Text(
                    destinasi.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    labelKategori,
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: tripin.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${destinasi.location} · ${destinasi.distanceKm.toStringAsFixed(1)} km dari kamu',
                        style: TextStyle(color: tripin.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RatingStars(rating: destinasi.rating, size: 18),
                      Text(
                        formatRupiah(destinasi.price),
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Tentang Destinasi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    destinasi.description,
                    style: TextStyle(color: context.colors.onSurface.withOpacity(0.87), height: 1.5),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () => _bukaPilihRencana(context),
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Tambah ke Rencana'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.chat,
                        arguments:
                            'Ceritakan tentang ${destinasi.name} dan apa yang bisa dilakukan di sana.',
                      ),
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: const Text('Tanya AI tentang tempat ini'),
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
