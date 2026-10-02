import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

const _lightBackground = Color(0xFFF7FAF8);
const _darkBackground = Color(0xFF0F1512);

ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.seed).copyWith(
    primary: const Color(0xFF2E7D6B),
    onPrimary: Colors.white,
    primaryContainer: TripinColors.light.paleMint,
    onPrimaryContainer: const Color(0xFF1B5446),
    secondaryContainer: TripinColors.light.paleMint,
    onSecondaryContainer: const Color(0xFF2E7D6B),
    surface: Colors.white,
    onSurface: const Color(0xFF1C1B1F),
    onSurfaceVariant: TripinColors.light.textSecondary,
    outline: const Color(0xFFBDBDBD),
    outlineVariant: const Color(0xFFE0E0E0),
    error: TripinColors.light.favoriteActive,
    onError: Colors.white,
  );
  return _build(
    scheme: scheme,
    extension: TripinColors.light,
    background: _lightBackground,
    overlay: SystemUiOverlayStyle.dark,
  );
}

ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.seed,
    brightness: Brightness.dark,
  ).copyWith(
    primary: const Color(0xFF7CCBB5),
    onPrimary: const Color(0xFF06231B),
    primaryContainer: TripinColors.dark.paleMint,
    onPrimaryContainer: const Color(0xFF7CCBB5),
    secondaryContainer: TripinColors.dark.paleMint,
    onSecondaryContainer: const Color(0xFF7CCBB5),
    surface: const Color(0xFF17201C),
    onSurface: const Color(0xFFE3EAE6),
    onSurfaceVariant: TripinColors.dark.textSecondary,
    outline: const Color(0xFF2B3A34),
    outlineVariant: const Color(0xFF2B3A34),
    error: TripinColors.dark.favoriteActive,
    onError: const Color(0xFF3B0905),
  );
  return _build(
    scheme: scheme,
    extension: TripinColors.dark,
    background: _darkBackground,
    overlay: SystemUiOverlayStyle.light,
  );
}

ThemeData _build({
  required ColorScheme scheme,
  required TripinColors extension,
  required Color background,
  required SystemUiOverlayStyle overlay,
}) {
  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(15),
    borderSide: BorderSide.none,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: scheme.brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    extensions: [extension],
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      systemOverlayStyle: overlay.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: scheme.surface,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: extension.paleMint,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.primary,
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      hintStyle: TextStyle(color: extension.textSecondary, fontSize: 14),
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: extension.surfaceElevated,
      surfaceTintColor: Colors.transparent,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: extension.surfaceElevated,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      checkColor: WidgetStatePropertyAll(scheme.onPrimary),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant),
  );
}
