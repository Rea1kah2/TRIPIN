import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Foto destinasi dari aset. Bila belum ada foto asli, tampil penanda jujur
/// ("Foto belum tersedia") dan bukan foto asal yang menyesatkan.
class DestinasiImage extends StatelessWidget {
  final String? aset;
  final double? width;
  final double? height;
  final BoxFit fit;

  const DestinasiImage({super.key, required this.aset, this.width, this.height, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final path = aset;
    if (path == null) return _Kosong(width: width, height: height);

    // Dekode sesuai ukuran tampil agar hemat memori (foto sumber 1000 px).
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final lebar = width != null && width!.isFinite ? (width! * dpr).round() : null;
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: lebar,
      errorBuilder: (_, __, ___) => _Kosong(width: width, height: height),
    );
  }
}

class _Kosong extends StatelessWidget {
  final double? width;
  final double? height;

  const _Kosong({this.width, this.height});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Container(
      width: width,
      height: height,
      color: context.tripin.imagePlaceholder,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_not_supported_outlined, color: scheme.onSurface.withOpacity(0.5), size: 24),
          if ((height ?? 100) >= 90) ...[
            const SizedBox(height: 4),
            Text(
              'Foto belum tersedia',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: context.tripin.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
