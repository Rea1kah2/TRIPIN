import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tugas_kelompok/providers/destinasi_provider.dart';
import 'package:tugas_kelompok/providers/review_provider.dart';
import 'package:tugas_kelompok/routes/app_routes.dart';
import 'package:tugas_kelompok/screens/destinasi/pencarian_rekomendasi_screen.dart';
import 'package:tugas_kelompok/theme/app_theme.dart';

void main() {
  testWidgets('layar Pencarian Rekomendasi (dari Nazwa) tampil dengan tema baru dan mencari berdasarkan nama', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final destinasi = DestinasiProvider();
    await destinasi.muatData();

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: destinasi),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
      ],
      child: MaterialApp(
        theme: buildLightTheme(),
        onGenerateRoute: AppRoutes.onGenerateRoute,
        initialRoute: AppRoutes.pencarianRekomendasi,
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Cari Wisata'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'toba');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Danau Toba'), findsWidgets);
    expect(find.text('Istana Maimun'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
