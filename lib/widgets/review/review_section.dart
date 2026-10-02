import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/destinasi.dart';
import '../../models/review.dart';
import '../../providers/auth_provider.dart';
import '../../providers/review_provider.dart';
import '../../screens/destinasi/semua_ulasan_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/radii.dart';
import '../../theme/typography.dart';
import '../app_snackbar.dart';
import '../confirm_delete_dialog.dart';
import '../glass_button.dart';
import '../glass_panel.dart';
import 'rating_picker.dart';
import 'review_form_sheet.dart';
import 'review_tile.dart';

const _tampilDiDetail = 3;

/// Bagian "Ulasan" di halaman detail: ringkasan, tombol tulis/ubah, dan daftar ulasan.
class ReviewSection extends StatelessWidget {
  final Destinasi destinasi;

  const ReviewSection({super.key, required this.destinasi});

  @override
  Widget build(BuildContext context) {
    final reviews = context.watch<ReviewProvider>();
    final userId = context.watch<AuthProvider>().currentUser?.id;
    final ringkasan = reviews.ringkasan(destinasi.id);
    final daftar = reviews.untuk(destinasi.id, userId: userId);
    final punyaSaya = reviews.milik(destinasi.id, userId) != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Ulasan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            if (ringkasan.jumlah > 0)
              Text('(${ringkasan.jumlah})', style: angkaTabular.copyWith(color: context.tripin.textSecondary, fontSize: 15)),
          ],
        ),
        const SizedBox(height: 10),
        if (ringkasan.jumlah == 0)
          GlassPanel(
            radius: Radii.lg,
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Icon(Icons.rate_review_outlined, size: 30, color: context.colors.primary),
                const SizedBox(height: 8),
                const Text('Belum ada ulasan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  'Jadilah yang pertama membagikan pengalamanmu di sini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.tripin.textSecondary),
                ),
              ],
            ),
          )
        else
          _Ringkasan(ringkasan: ringkasan),
        if (ringkasan.jumlah > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Text(
              'Rating di atas memadukan nilai dasar TRIPIN dan ulasan pengguna.',
              style: TextStyle(fontSize: 12, color: context.tripin.textSecondary),
            ),
          ),
        const SizedBox(height: 12),
        GlassButton(
          label: punyaSaya ? 'Ubah ulasanmu' : 'Tulis ulasan',
          icon: punyaSaya ? Icons.edit_outlined : Icons.rate_review_outlined,
          melebar: true,
          onPressed: () => bukaFormUlasan(context, destinasi),
        ),
        if (daftar.isNotEmpty) const SizedBox(height: 12),
        for (final r in daftar.take(_tampilDiDetail))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TileUlasanDenganAksi(review: r, destinasi: destinasi),
          ),
        if (daftar.length > _tampilDiDetail)
          Center(
            child: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SemuaUlasanScreen(destinasi: destinasi)),
              ),
              child: Text('Lihat semua ${daftar.length} ulasan'),
            ),
          ),
      ],
    );
  }
}

/// Tile ulasan; bila milik pengguna yang sedang masuk, ada aksi ubah dan hapus.
class TileUlasanDenganAksi extends StatelessWidget {
  final Review review;
  final Destinasi destinasi;

  const TileUlasanDenganAksi({super.key, required this.review, required this.destinasi});

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().currentUser?.id;
    final milik = userId != null && review.userId == userId;
    return ReviewTile(
      review: review,
      milikSaya: milik,
      onUbah: () => bukaFormUlasan(context, destinasi),
      onHapus: () async {
        final provider = context.read<ReviewProvider>();
        final ya = await showConfirmDeleteDialog(context, judul: 'Ulasanmu untuk ${destinasi.name}');
        if (!ya || !context.mounted) return;
        final galat = await provider.hapus(destinasi.id, review.userId);
        if (!context.mounted) return;
        showAppSnackbar(context, galat ?? 'Ulasan dihapus', isError: galat != null);
      },
    );
  }
}

class _Ringkasan extends StatelessWidget {
  final RingkasanUlasan ringkasan;

  const _Ringkasan({required this.ringkasan});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final maks = ringkasan.sebaran.fold<int>(1, (a, b) => b > a ? b : a);
    return GlassPanel(
      radius: Radii.lg,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ringkasan.rataRata.toStringAsFixed(1),
                style: angkaTabular.copyWith(fontSize: 40, fontWeight: FontWeight.w700, height: 1.1),
              ),
              BintangTampil(nilai: ringkasan.rataRata.round(), ukuran: 16),
              const SizedBox(height: 4),
              Text('${ringkasan.jumlah} ulasan', style: TextStyle(fontSize: 12, color: context.tripin.textSecondary)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [
                for (var bintang = 5; bintang >= 1; bintang--)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.5),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 14,
                          child: Text('$bintang', style: angkaTabular.copyWith(fontSize: 12, color: context.tripin.textSecondary)),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: ringkasan.sebaran[bintang - 1] / maks,
                              minHeight: 7,
                              backgroundColor: scheme.onSurface.withOpacity(0.10),
                              color: context.tripin.ratingStar,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 22,
                          child: Text(
                            '${ringkasan.sebaran[bintang - 1]}',
                            textAlign: TextAlign.end,
                            style: angkaTabular.copyWith(fontSize: 12, color: context.tripin.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
