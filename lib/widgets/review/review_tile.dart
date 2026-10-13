import 'package:flutter/material.dart';
import '../../models/review.dart';
import '../../theme/app_colors.dart';
import '../../theme/radii.dart';
import '../../utils/formatters.dart';
import '../glass_panel.dart';
import 'rating_picker.dart';

String waktuRelatif(DateTime t, [DateTime? sekarang]) {
  final selisih = (sekarang ?? DateTime.now()).difference(t);
  if (selisih.inMinutes < 1) return 'Baru saja';
  if (selisih.inMinutes < 60) return '${selisih.inMinutes} menit lalu';
  if (selisih.inHours < 24) return '${selisih.inHours} jam lalu';
  if (selisih.inDays < 7) return '${selisih.inDays} hari lalu';
  return formatTanggal(t);
}

class ReviewTile extends StatelessWidget {
  final Review review;
  final bool milikSaya;
  final VoidCallback? onUbah;
  final VoidCallback? onHapus;

  const ReviewTile({super.key, required this.review, this.milikSaya = false, this.onUbah, this.onHapus});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final tripin = context.tripin;
    final inisial = review.namaPenulis.trim().isEmpty ? '?' : review.namaPenulis.trim()[0].toUpperCase();

    return GlassPanel(
      radius: Radii.lg,
      padding: const EdgeInsets.all(14),
      rimColor: milikSaya ? scheme.primary.withOpacity(0.5) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: tripin.paleMint,
                child: Text(inisial, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            review.namaPenulis,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                        ),
                        if (milikSaya) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: scheme.primary.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text('Ulasanmu', style: TextStyle(fontSize: 11, color: scheme.primary, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${waktuRelatif(review.diubah)}${review.diedit ? ' · diedit' : ''}',
                      style: TextStyle(fontSize: 12, color: tripin.textSecondary),
                    ),
                  ],
                ),
              ),
              if (milikSaya) ...[
                IconButton(tooltip: 'Ubah ulasan', icon: const Icon(Icons.edit_outlined, size: 20), onPressed: onUbah),
                IconButton(tooltip: 'Hapus ulasan', icon: Icon(Icons.delete_outline, size: 20, color: scheme.error), onPressed: onHapus),
              ],
            ],
          ),
          const SizedBox(height: 10),
          BintangTampil(nilai: review.rating, ukuran: 18),
          if (review.komentar.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.komentar, style: const TextStyle(fontSize: 15, height: 1.45)),
          ],
        ],
      ),
    );
  }
}
