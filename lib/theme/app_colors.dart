import 'package:flutter/material.dart';

/// Warna brand yang dipakai sebagai seed. Warna yang berubah antar mode
/// ada di [TripinColors] (ThemeExtension) dan [ColorScheme].
class AppColors {
  AppColors._();

  static const seed = Color(0xFF2E7D6B);
}

/// Warna di luar ColorScheme Material. Akses lewat `context.tripin`.
@immutable
class TripinColors extends ThemeExtension<TripinColors> {
  final Color paleMint; // background ikon/avatar/chip
  final Color softMint; // background kartu AI
  final Color textSecondary;
  final Color ratingStar;
  final Color favoriteActive;
  final Color surfaceElevated; // bottom sheet, dialog
  final Color imagePlaceholder;
  final Color softShadow;
  final Color glassFillStart;
  final Color glassFillEnd;
  final Color glassBorder;
  final Color glassHighlight;
  final Color glassShadow;

  const TripinColors({
    required this.paleMint,
    required this.softMint,
    required this.textSecondary,
    required this.ratingStar,
    required this.favoriteActive,
    required this.surfaceElevated,
    required this.imagePlaceholder,
    required this.softShadow,
    required this.glassFillStart,
    required this.glassFillEnd,
    required this.glassBorder,
    required this.glassHighlight,
    required this.glassShadow,
  });

  static const light = TripinColors(
    paleMint: Color(0xFFE1F1EC),
    softMint: Color(0xFFE8F4F0),
    textSecondary: Color(0xFF9E9E9E),
    ratingStar: Color(0xFFFFC107),
    favoriteActive: Color(0xFFF44336),
    surfaceElevated: Color(0xFFFFFFFF),
    imagePlaceholder: Color(0xFFEEEEEE),
    softShadow: Color(0x0D000000), // hitam 5%
    glassFillStart: Color(0x8CFFFFFF), // putih 55%
    glassFillEnd: Color(0x40FFFFFF), // putih 25%
    glassBorder: Color(0x99FFFFFF), // putih 60%
    glassHighlight: Color(0x80FFFFFF), // putih 50%
    glassShadow: Color(0x1A000000), // hitam 10%
  );

  static const dark = TripinColors(
    paleMint: Color(0xFF1F3B33),
    softMint: Color(0xFF1A2B25),
    textSecondary: Color(0xFF9AABA3),
    ratingStar: Color(0xFFFFCA5C),
    favoriteActive: Color(0xFFFF7B72),
    surfaceElevated: Color(0xFF1E2A25),
    imagePlaceholder: Color(0xFF1E2A25),
    softShadow: Color(0x4D000000), // hitam 30%
    glassFillStart: Color(0x14FFFFFF), // putih 8%
    glassFillEnd: Color(0x08FFFFFF), // putih 3%
    glassBorder: Color(0x1FFFFFFF), // putih 12%
    glassHighlight: Color(0x26FFFFFF), // putih 15%
    glassShadow: Color(0x66000000), // hitam 40%
  );

  @override
  TripinColors copyWith({
    Color? paleMint,
    Color? softMint,
    Color? textSecondary,
    Color? ratingStar,
    Color? favoriteActive,
    Color? surfaceElevated,
    Color? imagePlaceholder,
    Color? softShadow,
    Color? glassFillStart,
    Color? glassFillEnd,
    Color? glassBorder,
    Color? glassHighlight,
    Color? glassShadow,
  }) {
    return TripinColors(
      paleMint: paleMint ?? this.paleMint,
      softMint: softMint ?? this.softMint,
      textSecondary: textSecondary ?? this.textSecondary,
      ratingStar: ratingStar ?? this.ratingStar,
      favoriteActive: favoriteActive ?? this.favoriteActive,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      imagePlaceholder: imagePlaceholder ?? this.imagePlaceholder,
      softShadow: softShadow ?? this.softShadow,
      glassFillStart: glassFillStart ?? this.glassFillStart,
      glassFillEnd: glassFillEnd ?? this.glassFillEnd,
      glassBorder: glassBorder ?? this.glassBorder,
      glassHighlight: glassHighlight ?? this.glassHighlight,
      glassShadow: glassShadow ?? this.glassShadow,
    );
  }

  @override
  TripinColors lerp(ThemeExtension<TripinColors>? other, double t) {
    if (other is! TripinColors) return this;
    return TripinColors(
      paleMint: Color.lerp(paleMint, other.paleMint, t)!,
      softMint: Color.lerp(softMint, other.softMint, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      ratingStar: Color.lerp(ratingStar, other.ratingStar, t)!,
      favoriteActive: Color.lerp(favoriteActive, other.favoriteActive, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      imagePlaceholder:
          Color.lerp(imagePlaceholder, other.imagePlaceholder, t)!,
      softShadow: Color.lerp(softShadow, other.softShadow, t)!,
      glassFillStart: Color.lerp(glassFillStart, other.glassFillStart, t)!,
      glassFillEnd: Color.lerp(glassFillEnd, other.glassFillEnd, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      glassHighlight: Color.lerp(glassHighlight, other.glassHighlight, t)!,
      glassShadow: Color.lerp(glassShadow, other.glassShadow, t)!,
    );
  }
}

extension TripinThemeContext on BuildContext {
  TripinColors get tripin => Theme.of(this).extension<TripinColors>()!;
  ColorScheme get colors => Theme.of(this).colorScheme;
}
