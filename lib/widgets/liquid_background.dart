import 'package:flutter/material.dart';

/// Latar hidup untuk kaca: dasar polos + tiga blob radial berwarna palet aplikasi.
/// Statis (tidak beranimasi) supaya hemat baterai; dilukis sekali di RepaintBoundary.
class LiquidBackground extends StatelessWidget {
  const LiquidBackground({super.key});

  static const _terangDasar = Color(0xFFF7FAF8);
  static const _gelapDasar = Color(0xFF0F1512);

  /// Blob: (pusat, radius relatif lebar, warna). Warna turunan palet mint yang sudah ada.
  static List<_Blob> _blob(Brightness b) => b == Brightness.dark
      ? const [
          _Blob(Alignment(-0.9, -0.95), 0.9, Color(0x477CCBB5)), // mint, kiri atas
          _Blob(Alignment(1.0, -0.35), 0.8, Color(0x4D2E7D6B)), // hijau tua, kanan
          _Blob(Alignment(0.2, 1.05), 1.0, Color(0x661F3B33)), // paleMint gelap, bawah
        ]
      : const [
          _Blob(Alignment(-0.9, -0.95), 0.9, Color(0x597CCBB5)),
          _Blob(Alignment(1.0, -0.35), 0.8, Color(0x387CCBB5)), // mint (bukan hijau tua: di atas putih hijau tua tampak abu-abu)
          _Blob(Alignment(0.2, 1.05), 1.0, Color(0x80E1F1EC)),
        ];

  static Color dasar(Brightness b) => b == Brightness.dark ? _gelapDasar : _terangDasar;

  /// Warna latar terburuk yang mungkin berada di belakang kaca (dasar + puncak tiap blob),
  /// dipakai tes kontras.
  static List<Color> sampelTerburuk(Brightness b) => [
        dasar(b),
        for (final blob in _blob(b)) Color.alphaBlend(blob.warna, dasar(b)),
      ];

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: dasar(b)),
          for (final blob in _blob(b))
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: blob.pusat,
                  radius: blob.radius,
                  colors: [blob.warna, blob.warna.withOpacity(0)],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Blob {
  final Alignment pusat;
  final double radius;
  final Color warna;
  const _Blob(this.pusat, this.radius, this.warna);
}
