import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/destinasi_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/destinasi_card.dart';
import '../../widgets/glass_scaffold.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/glass_insets.dart';
import '../../widgets/keadaan_kosong.dart';

class FavoritScreen extends StatelessWidget {
  const FavoritScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DestinasiProvider>();
    final daftar = provider.daftarFavorit;

    return GlassScaffold(
      appBar: const GlassAppBar(judul: 'Favorit'),
      body: daftar.isEmpty
          ? KeadaanKosong(
              ikon: Icons.favorite_border,
              judul: 'Belum ada favorit',
              pesan: 'Ketuk ikon hati di kartu destinasi untuk menyimpannya di sini.',
              labelAksi: 'Jelajahi destinasi',
              onAksi: () => Navigator.pushNamed(context, AppRoutes.destinasiList),
            )
          : ListView.builder(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + GlassInsets.bawahOf(context)),
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
