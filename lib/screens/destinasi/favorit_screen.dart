
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/destinasi_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/destinasi_card.dart';

class FavoritScreen extends StatelessWidget {
  const FavoritScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DestinasiProvider>();

    // Ambil destinasi yang sudah ditandai sebagai favorit.
    final daftarFavorit = provider.daftarDestinasi
        .where((destinasi) => destinasi.isFavorit)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Destinasi Favorit',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D6B),
        foregroundColor: Colors.white,
      ),
      body: daftarFavorit.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite_border,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'Belum Ada Destinasi Favorit',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Tekan ikon hati pada destinasi yang '
                    'kamu sukai untuk menyimpannya di sini.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.destinasiList,
                  );
                },
                icon: const Icon(Icons.explore),
                label: const Text('Jelajahi Destinasi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D6B),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: daftarFavorit.length,
        separatorBuilder: (_, __) =>
        const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final destinasi = daftarFavorit[index];

          return DestinasiCard(
            destinasi: destinasi,
            dense: true,
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.destinasiDetail,
                arguments: destinasi.id,
              );
            },
            onFavoriteTap: () {
              provider.toggleFavorit(destinasi.id);
            },
          );
        },
      ),
    );
  }
}