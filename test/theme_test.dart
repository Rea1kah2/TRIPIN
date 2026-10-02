import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tugas_kelompok/main.dart';
import 'package:tugas_kelompok/providers/theme_provider.dart';
import 'package:tugas_kelompok/theme/app_colors.dart';

void main() {
  group('ThemeProvider', () {
    test('default ke ThemeMode.system', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = ThemeProvider();
      await provider.muatData();
      expect(provider.themeMode, ThemeMode.system);
      expect(provider.isLoading, isFalse);
    });

    test('mode tersimpan dan dimuat ulang', () async {
      SharedPreferences.setMockInitialValues({});
      final a = ThemeProvider();
      await a.muatData();
      a.setThemeMode(ThemeMode.dark);
      await Future<void>.delayed(Duration.zero);

      final b = ThemeProvider();
      await b.muatData();
      expect(b.themeMode, ThemeMode.dark);
    });

    test('nilai tersimpan yang rusak jatuh ke system', () async {
      SharedPreferences.setMockInitialValues({'tripin_theme_mode': 'ungu'});
      final provider = ThemeProvider();
      await provider.muatData();
      expect(provider.themeMode, ThemeMode.system);
    });
  });

  group('Dark mode di app', () {
    testWidgets('memakai palet gelap saat mode tersimpan = dark',
        (tester) async {
      SharedPreferences.setMockInitialValues({'tripin_theme_mode': 'dark'});
      await tester.pumpWidget(const TripinApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.text('Selamat Datang 👋'));
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(Theme.of(context).scaffoldBackgroundColor,
          const Color(0xFF0F1512));
      expect(context.colors.primary, const Color(0xFF7CCBB5));
      expect(context.tripin.paleMint, const Color(0xFF1F3B33));
    });

    testWidgets('toggle membalik tema dan menyimpannya', (tester) async {
      SharedPreferences.setMockInitialValues({'tripin_theme_mode': 'light'});
      await tester.pumpWidget(const TripinApp());
      await tester.pumpAndSettle();

      var context = tester.element(find.text('Selamat Datang 👋'));
      expect(Theme.of(context).brightness, Brightness.light);

      await tester.tap(find.byTooltip('Ganti ke mode gelap'));
      await tester.pumpAndSettle();

      context = tester.element(find.text('Selamat Datang 👋'));
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(find.byTooltip('Ganti ke mode terang'), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('tripin_theme_mode'), 'dark');

      await tester.tap(find.byTooltip('Ganti ke mode terang'));
      await tester.pumpAndSettle();
      context = tester.element(find.text('Selamat Datang 👋'));
      expect(Theme.of(context).brightness, Brightness.light);
    });
  });

  group('Kontras palet (WCAG AA >= 4.5:1)', () {
    double kontras(Color a, Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      final terang = la > lb ? la : lb;
      final gelap = la > lb ? lb : la;
      return (terang + 0.05) / (gelap + 0.05);
    }

    const bg = Color(0xFF0F1512);
    const surface = Color(0xFF17201C);

    test('teks di atas background/surface gelap', () {
      expect(kontras(const Color(0xFFE3EAE6), bg), greaterThanOrEqualTo(4.5));
      expect(kontras(const Color(0xFFE3EAE6), surface),
          greaterThanOrEqualTo(4.5));
      expect(kontras(TripinColors.dark.textSecondary, surface),
          greaterThanOrEqualTo(4.5));
      expect(kontras(const Color(0xFF7CCBB5), bg), greaterThanOrEqualTo(4.5));
      expect(kontras(const Color(0xFF7CCBB5), surface),
          greaterThanOrEqualTo(4.5));
      expect(kontras(TripinColors.dark.favoriteActive, surface),
          greaterThanOrEqualTo(4.5));
    });

    test('teks di atas tombol terisi (onPrimary)', () {
      expect(kontras(const Color(0xFF06231B), const Color(0xFF7CCBB5)),
          greaterThanOrEqualTo(4.5));
      expect(kontras(Colors.white, const Color(0xFF2E7D6B)),
          greaterThanOrEqualTo(4.5));
    });

    test('primary di atas paleMint (chip/ikon) gelap', () {
      expect(kontras(const Color(0xFF7CCBB5), TripinColors.dark.paleMint),
          greaterThanOrEqualTo(4.5));
    });
  });
}
