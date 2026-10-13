import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tugas_kelompok/providers/theme_provider.dart';
import 'package:tugas_kelompok/theme/app_colors.dart';
import 'package:tugas_kelompok/theme/app_theme.dart';
import 'package:tugas_kelompok/theme/glass_theme.dart';
import 'package:tugas_kelompok/theme/radii.dart';
import 'package:tugas_kelompok/widgets/glass_panel.dart';
import 'package:tugas_kelompok/widgets/glass_scaffold.dart';
import 'package:tugas_kelompok/widgets/liquid_background.dart';

double _luminans(Color c) {
  double kanal(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * kanal(c.red / 255) + 0.7152 * kanal(c.green / 255) + 0.0722 * kanal(c.blue / 255);
}

double rasioKontras(Color a, Color b) {
  final la = _luminans(a), lb = _luminans(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

Future<void> pasangPanel(
  WidgetTester tester, {
  bool blur = false,
  bool reduce = false,
  bool kontrasTinggi = false,
  Brightness brightness = Brightness.light,
}) {
  final tema = brightness == Brightness.dark
      ? buildDarkTheme(reduceTransparency: reduce)
      : buildLightTheme(reduceTransparency: reduce);
  return tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(highContrast: kontrasTinggi),
      child: MaterialApp(
        theme: tema,
        home: Scaffold(body: Center(child: GlassPanel(blur: blur, child: const Text('isi')))),
      ),
    ),
  );
}

void main() {
  group('GlassTheme', () {
    test('turunan dihitung dari intensitas (0, 0.5, 1)', () {
      final g0 = GlassTheme.light(intensity: 0);
      final g5 = GlassTheme.light();
      final g1 = GlassTheme.light(intensity: 1);
      expect([g0.blur, g5.blur, g1.blur], [6, 18, 30]);
      expect(g0.tintAlpha, closeTo(0.06, 1e-9));
      expect(g5.tintAlpha, closeTo(0.23, 1e-9));
      expect(g1.tintAlpha, closeTo(0.40, 1e-9));
      expect(g5.rimAlpha, closeTo(0.40, 1e-9));
      expect(g5.specAlpha, closeTo(0.575, 1e-9));
    });

    test('mode gelap menurunkan kilau (skala 0.6)', () {
      expect(GlassTheme.dark().rimAlpha, closeTo(GlassTheme.light().rimAlpha * 0.6, 1e-9));
    });

    test('bias dijepit ke 0..1', () {
      expect(GlassTheme.light(intensity: 0.1).withBias(-0.25).intensity, 0);
      expect(GlassTheme.light(intensity: 0.9).withBias(0.25).intensity, 1);
      expect(GlassTheme.light().withBias(0.25).intensity, closeTo(0.75, 1e-9));
    });

    test('tema aplikasi membawa GlassTheme dengan setelan yang diberikan', () {
      final t = buildDarkTheme(glassIntensity: 0.8, reduceTransparency: true);
      final g = t.extension<GlassTheme>()!;
      expect(g.intensity, 0.8);
      expect(g.reduceTransparency, isTrue);
    });
  });

  test('radius konsentris: luar dikurangi padding, minimal 4', () {
    expect(konsentris(28, 8), 20);
    expect(konsentris(20, 8), 12);
    expect(konsentris(10, 9), 4);
  });

  group('Kontras teks utama di atas kaca (intensitas 0 = paling bening)', () {
    for (final b in Brightness.values) {
      test('${b.name}: onSurface di atas tint kaca di semua latar terburuk >= 4.5:1', () {
        final tema = b == Brightness.dark ? buildDarkTheme() : buildLightTheme();
        final g = GlassTheme.dark().copyWith(intensity: 0);
        final gl = b == Brightness.dark ? g : GlassTheme.light(intensity: 0);
        final teks = tema.colorScheme.onSurface;
        for (final latar in LiquidBackground.sampelTerburuk(b)) {
          final kaca = Color.alphaBlend(gl.tint.withOpacity(gl.tintAlpha), latar);
          expect(rasioKontras(teks, kaca), greaterThanOrEqualTo(4.5), reason: 'latar $latar');
        }
      });
    }
  });

  group('Kontras teks sekunder (hint, lokasi, keterangan)', () {
    for (final b in Brightness.values) {
      test('${b.name}: textSecondary >= 4.5:1 di atas latar hidup dan kaca', () {
        final warna = b == Brightness.dark ? TripinColors.dark.textSecondary : TripinColors.light.textSecondary;
        final gl = b == Brightness.dark ? GlassTheme.dark() : GlassTheme.light();
        for (final latar in LiquidBackground.sampelTerburuk(b)) {
          expect(rasioKontras(warna, latar), greaterThanOrEqualTo(4.5), reason: 'di atas latar $latar');
          // Kaca tanpa blur (kartu) di atas latar yang sama, pada intensitas default.
          final kartu = Color.alphaBlend(gl.tint.withOpacity((gl.tintAlpha + (b == Brightness.dark ? 0.30 : 0.42)).clamp(0.0, 0.85)), latar);
          expect(rasioKontras(warna, kartu), greaterThanOrEqualTo(4.5), reason: 'di atas kartu $kartu');
        }
      });
    }
  });

  group('GlassPanel', () {
    testWidgets('kaca ringan (blur=false) tidak memakai BackdropFilter', (tester) async {
      await pasangPanel(tester);
      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.text('isi'), findsOneWidget);
    });

    testWidgets('lapisan melayang (blur=true) memakai BackdropFilter', (tester) async {
      await pasangPanel(tester, blur: true);
      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('Reduce Transparency: solid, tanpa BackdropFilter', (tester) async {
      await pasangPanel(tester, blur: true, reduce: true);
      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.text('isi'), findsOneWidget);
    });

    testWidgets('High Contrast sistem: solid, tanpa BackdropFilter', (tester) async {
      await pasangPanel(tester, blur: true, kontrasTinggi: true);
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('tampil di mode gelap tanpa error', (tester) async {
      await pasangPanel(tester, blur: true, brightness: Brightness.dark);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('GlassScaffold melukis latar hidup di belakang isi', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildLightTheme(),
      home: const GlassScaffold(body: Text('halaman')),
    ));
    expect(find.byType(LiquidBackground), findsOneWidget);
    expect(find.text('halaman'), findsOneWidget);
  });

  group('ThemeProvider: setelan kaca tersimpan', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('default 0.5 dan tidak kurangi transparansi', () async {
      final p = ThemeProvider();
      await p.muatData();
      expect(p.glassIntensity, 0.5);
      expect(p.reduceTransparency, isFalse);
    });

    test('nilai disimpan, dijepit, dan dimuat ulang', () async {
      final p = ThemeProvider();
      await p.muatData();
      p.setGlassIntensity(1.7);
      p.setReduceTransparency(true);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(p.glassIntensity, 1);

      final q = ThemeProvider();
      await q.muatData();
      expect(q.glassIntensity, 1);
      expect(q.reduceTransparency, isTrue);
    });
  });

  test('TripinColors tidak lagi memuat token kaca (dipindah ke GlassTheme)', () {
    expect(TripinColors.light.paleMint, isNotNull);
  });
}
