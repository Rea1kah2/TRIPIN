import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';

const _labelBintang = ['', 'Buruk', 'Kurang', 'Cukup', 'Bagus', 'Luar biasa'];

/// Pemilih bintang 1-5. Tiap bintang punya area sentuh 48 px dan label teks
/// (status tidak hanya lewat warna).
class RatingPicker extends StatelessWidget {
  final int nilai; // 0 = belum dipilih
  final ValueChanged<int> onChanged;

  const RatingPicker({super.key, required this.nilai, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final bintang = context.tripin.ratingStar;
    final redup = context.colors.onSurface.withOpacity(0.28);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 1; i <= 5; i++)
              Semantics(
                button: true,
                selected: i == nilai,
                label: '$i dari 5 bintang',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onChanged(i);
                  },
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(
                      i <= nilai ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 38,
                      color: i <= nilai ? bintang : redup,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          nilai == 0 ? 'Ketuk bintang untuk menilai' : _labelBintang[nilai],
          style: TextStyle(
            fontSize: 14,
            fontWeight: nilai == 0 ? FontWeight.w400 : FontWeight.w600,
            color: nilai == 0 ? context.tripin.textSecondary : context.colors.onSurface,
          ),
        ),
      ],
    );
  }
}

/// Deretan bintang tampilan (tanpa interaksi).
class BintangTampil extends StatelessWidget {
  final int nilai;
  final double ukuran;

  const BintangTampil({super.key, required this.nilai, this.ukuran = 16});

  @override
  Widget build(BuildContext context) {
    final bintang = context.tripin.ratingStar;
    final redup = context.colors.onSurface.withOpacity(0.25);
    return Semantics(
      label: '$nilai dari 5 bintang',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 1; i <= 5; i++)
              Icon(i <= nilai ? Icons.star_rounded : Icons.star_outline_rounded, size: ukuran, color: i <= nilai ? bintang : redup),
          ],
        ),
      ),
    );
  }
}
