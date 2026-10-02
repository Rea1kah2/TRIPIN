import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';

/// Parameter material kaca. Semua turunan dihitung dari [intensity] (0 = paling bening,
/// 1 = frosted tebal) sehingga tidak ada angka blur/alpha yang ditulis per komponen.
@immutable
class GlassTheme extends ThemeExtension<GlassTheme> {
  /// 0..1, default 0.5. Dikendalikan pengguna lewat slider "Transparansi".
  final double intensity;

  /// True = semua kaca diganti permukaan solid (setelan pengguna).
  final bool reduceTransparency;

  /// Warna dasar kaca (putih di terang, surface gelap aplikasi di gelap).
  final Color tint;

  /// Warna rim dan kilau specular.
  final Color rim;

  /// Skala kilau (lebih kecil di mode gelap).
  final double highlightScale;

  const GlassTheme({
    this.intensity = 0.5,
    this.reduceTransparency = false,
    required this.tint,
    this.rim = const Color(0xFFFFFFFF),
    this.highlightScale = 1,
  });

  factory GlassTheme.light({double intensity = 0.5, bool reduceTransparency = false}) =>
      GlassTheme(
        intensity: intensity,
        reduceTransparency: reduceTransparency,
        tint: const Color(0xFFFFFFFF),
      );

  factory GlassTheme.dark({double intensity = 0.5, bool reduceTransparency = false}) =>
      GlassTheme(
        intensity: intensity,
        reduceTransparency: reduceTransparency,
        tint: const Color(0xFF17201C), // sama dengan surface gelap aplikasi
        highlightScale: 0.6,
      );

  double get blur => 6 + intensity * 24;
  double get tintAlpha => 0.06 + intensity * 0.34;
  double get rimAlpha => (0.30 + intensity * 0.20) * highlightScale;
  double get specAlpha => (0.45 + intensity * 0.25) * highlightScale;
  double get edgeAlpha => 0.05 + intensity * 0.07;
  double get shadowAlpha => 0.06 + intensity * 0.08;

  /// Varian lokal: thin = -0.25, tebal = +0.25. Hasil dijepit 0..1.
  GlassTheme withBias(double bias) =>
      copyWith(intensity: (intensity + bias).clamp(0.0, 1.0));

  @override
  GlassTheme copyWith({
    double? intensity,
    bool? reduceTransparency,
    Color? tint,
    Color? rim,
    double? highlightScale,
  }) {
    return GlassTheme(
      intensity: intensity ?? this.intensity,
      reduceTransparency: reduceTransparency ?? this.reduceTransparency,
      tint: tint ?? this.tint,
      rim: rim ?? this.rim,
      highlightScale: highlightScale ?? this.highlightScale,
    );
  }

  @override
  GlassTheme lerp(ThemeExtension<GlassTheme>? other, double t) {
    if (other is! GlassTheme) return this;
    return GlassTheme(
      intensity: lerpDouble(intensity, other.intensity, t)!,
      reduceTransparency: t < 0.5 ? reduceTransparency : other.reduceTransparency,
      tint: Color.lerp(tint, other.tint, t)!,
      rim: Color.lerp(rim, other.rim, t)!,
      highlightScale: lerpDouble(highlightScale, other.highlightScale, t)!,
    );
  }
}

extension GlassThemeContext on BuildContext {
  GlassTheme get glass =>
      Theme.of(this).extension<GlassTheme>() ??
      (Theme.of(this).brightness == Brightness.dark ? GlassTheme.dark() : GlassTheme.light());
}
