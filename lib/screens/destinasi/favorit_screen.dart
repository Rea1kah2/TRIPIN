import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/destinasi_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/destinasi_card.dart';
import '../../theme/app_colors.dart';

class FavoritScreen extends StatelessWidget {
  const FavoritScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DestinasiProvider>();
    final daftar = provider.daftarFavorit;

    return Scaffold(
      appBar: AppBar(title: const Text('Favorit')),
      body: daftar.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Belum ada destinasi favorit.\nTap ikon hati di kartu untuk menambahkan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.tripin.textSecondary),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: daftar.length,
              itemBuilder: (context, index) {
                final destinasi = daftar[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DestinasiCard(
                    destinasi: destinasi,
                    dense: true,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.destinasiDetail,
                      arguments: destinasi.id,
                    ),
                    onFavoriteTap: () => provider.toggleFavorit(destinasi.id),
                  ),
                );
              },
            ),
    );
  }
}
