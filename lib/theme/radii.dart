import 'dart:math' as math;

/// Token radius (bahasa bentuk Liquid Glass: serba membulat).
class Radii {
  Radii._();

  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 28.0;
  static const xxl = 36.0;
  static const full = 999.0;
}

/// Radius konsentris: radius elemen dalam = radius luar dikurangi padding (minimal 4).
double konsentris(double radiusLuar, double padding) => math.max(4, radiusLuar - padding);
