import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/glass_theme.dart';

/// Material kaca: tint + rim + kilau specular + tepi gelap tipis + bayangan lembut.
///
/// [blur] = true hanya untuk lapisan yang melayang di atas konten yang bergerak
/// (tab bar, bar atas, composer, sheet, dialog, toast). Card di dalam list memakai
/// false: tampilannya hampir sama di atas latar mesh yang halus, tetapi jauh lebih murah.
///
/// [bias]: -0.25 = tipis (kontrol kecil), 0 = reguler, +0.25 = tebal (sheet, menu).
/// [accent] = kaca bertint warna utama (satu tombol prominent per layar).
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double bias;
  final bool blur;
  final bool accent;

  /// Menimpa [radius] bila bentuknya tidak seragam (mis. sheet: hanya sudut atas).
  final BorderRadius? borderRadius;

  /// Menimpa warna rim (garis tepi dalam), mis. kartu sorotan bertepi warna utama.
  final Color? rimColor;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.bias = 0,
    this.blur = false,
    this.accent = false,
    this.borderRadius,
    this.rimColor,
  });

  @override
  Widget build(BuildContext context) {
    final g = context.glass.withBias(bias);
    final scheme = context.colors;
    final bentuk = borderRadius ?? BorderRadius.circular(radius);
    final solid = g.reduceTransparency || MediaQuery.highContrastOf(context);

    if (solid) {
      return RepaintBoundary(
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: accent ? scheme.primary : scheme.surface.withOpacity(0.96),
            borderRadius: bentuk,
            border: Border.all(color: scheme.outline),
          ),
          child: child,
        ),
      );
    }

    // Tanpa blur, tint perlu sedikit lebih padat supaya kartu tetap punya badan dan terbaca
    // di atas latar terang maupun foto; dengan blur, latar sudah dikaburkan jadi cukup tipis.
    final terang = Theme.of(context).brightness == Brightness.light;
    final tambahan = terang ? _tambahanTanpaBlurTerang : _tambahanTanpaBlurGelap;
    final alphaTint = blur ? g.tintAlpha : (g.tintAlpha + tambahan).clamp(0.0, 0.85);
    // Di atas badan yang sudah padat, kilau cukup tipis dan pendek supaya kartu tidak
    // terlihat dua-warna (kiri putih, kanan keabu-abuan) di mode terang.
    final kilau = blur ? 0.5 : (terang ? 0.28 : 0.4);
    final warnaDasar = accent ? scheme.primary.withOpacity(0.88) : g.tint.withOpacity(alphaTint);

    // Flutter mengabaikan `color` bila `gradient` diisi pada BoxDecoration yang sama, jadi
    // tint dan kilau specular dilukis sebagai dua lapisan terpisah.
    Widget isi = DecoratedBox(
      decoration: BoxDecoration(
        color: warnaDasar,
        borderRadius: bentuk,
        border: Border.all(color: rimColor ?? g.rim.withOpacity(g.rimAlpha), width: 1),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: bentuk,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [g.rim.withOpacity(g.specAlpha * kilau), g.rim.withOpacity(0)],
            stops: const [0, 0.38],
          ),
        ),
        child: Padding(padding: padding, child: child),
      ),
    );

    isi = ClipRRect(
      borderRadius: bentuk,
      child: blur
          ? BackdropFilter(filter: ImageFilter.blur(sigmaX: g.blur, sigmaY: g.blur), child: isi)
          : isi,
    );

    return RepaintBoundary(
      child: CustomPaint(
        // Bayangan hanya di luar bentuk kartu. Kalau tembus ke bawah isi yang transparan,
        // kartu tampak abu-abu keruh dengan pita ganda di tepinya.
        painter: _BayanganLuar(
          bentuk: bentuk,
          warna: Colors.black.withOpacity(g.shadowAlpha),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: bentuk,
            border: Border.all(color: Colors.black.withOpacity(g.edgeAlpha), width: 0.5),
          ),
          child: isi,
        ),
      ),
    );
  }
}

/// Tambahan alpha tint untuk kaca tanpa BackdropFilter (latar terang butuh badan lebih padat).
const _tambahanTanpaBlurTerang = 0.42;
const _tambahanTanpaBlurGelap = 0.30;

class _BayanganLuar extends CustomPainter {
  final BorderRadius bentuk;
  final Color warna;

  const _BayanganLuar({required this.bentuk, required this.warna});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = bentuk.toRRect(Offset.zero & size);
    final luar = Path()
      ..addRect((Offset.zero & size).inflate(80))
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.save();
    canvas.clipPath(luar); // hanya area di luar kartu
    canvas.drawRRect(
      rrect.shift(const Offset(0, 8)),
      Paint()
        ..color = warna
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BayanganLuar old) => old.bentuk != bentuk || old.warna != warna;
}
