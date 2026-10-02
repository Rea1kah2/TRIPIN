import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tugas_kelompok/providers/destinasi_provider.dart';
import 'package:tugas_kelompok/providers/lokasi_provider.dart';
import 'package:tugas_kelompok/providers/review_provider.dart';
import 'package:tugas_kelompok/theme/app_theme.dart';
import 'package:tugas_kelompok/widgets/destinasi_card.dart';

Future<void> pasang(
  WidgetTester tester, {
  required bool dense,
  required VoidCallback onTap,
  required VoidCallback onFav,
  bool gelap = false,
}) async {
  SharedPreferences.setMockInitialValues({});
  final provider = DestinasiProvider();
  await provider.muatData();
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: provider),
      ChangeNotifierProvider(create: (_) => ReviewProvider()),
      ChangeNotifierProvider(create: (_) => LokasiProvider()),
    ],
    child: MaterialApp(
      theme: gelap ? buildDarkTheme() : buildLightTheme(),
      home: Scaffold(
        body: Center(
          child: DestinasiCard(
            destinasi: provider.daftarDestinasi[4],
            dense: dense,
            onTap: onTap,
            onFavoriteTap: onFav,
          ),
        ),
      ),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  for (final dense in [false, true]) {
    final nama = dense ? 'dense' : 'penuh';

    testWidgets('kartu $nama: ketuk kartu memanggil onTap, ketuk hati hanya onFavoriteTap', (tester) async {
      var tap = 0, fav = 0;
      await pasang(tester, dense: dense, onTap: () => tap++, onFav: () => fav++);

      await tester.tap(find.byIcon(Icons.favorite_border));
      expect((tap, fav), (0, 1));

      await tester.tap(find.text('Istana Maimun'));
      expect((tap, fav), (1, 1));
    });

    testWidgets('kartu $nama: area sentuh favorit >= 44x44 dan tanpa BackdropFilter', (tester) async {
      await pasang(tester, dense: dense, onTap: () {}, onFav: () {});
      final area = tester.getSize(find.ancestor(
        of: find.byIcon(Icons.favorite_border),
        matching: find.byWidgetPredicate((w) => w is SizedBox && w.width == 44 && w.height == 44),
      ));
      expect(area.width, greaterThanOrEqualTo(44));
      expect(area.height, greaterThanOrEqualTo(44));
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('kartu $nama tampil di mode gelap tanpa error', (tester) async {
      await pasang(tester, dense: dense, onTap: () {}, onFav: () {}, gelap: true);
      expect(tester.takeException(), isNull);
      expect(find.text('Istana Maimun'), findsOneWidget);
    });
  }
}
