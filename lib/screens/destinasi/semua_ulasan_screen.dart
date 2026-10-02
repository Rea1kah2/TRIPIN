import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/destinasi.dart';
import '../../providers/auth_provider.dart';
import '../../providers/review_provider.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/glass_scaffold.dart';
import '../../widgets/keadaan_kosong.dart';
import '../../widgets/review/review_section.dart';

/// Semua ulasan satu destinasi (ulasan milikmu di paling atas).
class SemuaUlasanScreen extends StatelessWidget {
  final Destinasi destinasi;

  const SemuaUlasanScreen({super.key, required this.destinasi});

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().currentUser?.id;
    final daftar = context.watch<ReviewProvider>().untuk(destinasi.id, userId: userId);

    return GlassScaffold(
      appBar: GlassAppBar(judul: 'Ulasan ${destinasi.name}'),
      body: daftar.isEmpty
          ? const KeadaanKosong(
              ikon: Icons.rate_review_outlined,
              judul: 'Belum ada ulasan',
              pesan: 'Kembali ke halaman destinasi untuk menulis ulasan pertama.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: daftar.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => TileUlasanDenganAksi(review: daftar[i], destinasi: destinasi),
            ),
    );
  }
}
