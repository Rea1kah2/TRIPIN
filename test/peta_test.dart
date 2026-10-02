import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tugas_kelompok/providers/destinasi_provider.dart';
import 'package:tugas_kelompok/providers/lokasi_provider.dart';
import 'package:tugas_kelompok/providers/review_provider.dart';
import 'package:tugas_kelompok/routes/app_routes.dart';
import 'package:tugas_kelompok/screens/peta/peta_screen.dart';
import 'package:tugas_kelompok/services/location_service.dart';
import 'package:tugas_kelompok/theme/app_theme.dart';
import 'package:tugas_kelompok/widgets/glass_insets.dart';

import 'lokasi_test.dart' show FakeLokasi;

/// Ubin kosong supaya tes tidak mengakses jaringan.
class _TileKosong extends TileProvider {
  static final _png = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) => MemoryImage(_png);
}

Finder penanda(String nama) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == nama && w.properties.button == true);

Future<LokasiProvider> pasang(
  WidgetTester tester, {
  required FakeLokasi lokasi,
  bool aktif = true,
  bool gelap = false,
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(800, 1700);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final destinasi = DestinasiProvider();
  await destinasi.muatData();
  final lp = LokasiProvider(service: lokasi);
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: destinasi),
      ChangeNotifierProvider.value(value: lp),
      ChangeNotifierProvider(create: (_) => ReviewProvider()),
    ],
    child: MaterialApp(
      theme: gelap ? buildDarkTheme() : buildLightTheme(),
      onGenerateRoute: AppRoutes.onGenerateRoute,
      home: GlassInsets(bawah: 76, child: PetaScreen(aktif: aktif, tileProvider: _TileKosong())),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 300));
  return lp;
}

void main() {
  testWidgets('menampilkan penanda destinasi dan chip filter kategori', (tester) async {
    await pasang(tester, lokasi: FakeLokasi());
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Budaya'), findsWidgets);
    expect(penanda('Istana Maimun'), findsOneWidget);
    expect(penanda('Danau Toba'), findsOneWidget);
  });

  testWidgets('filter kategori menyembunyikan penanda kategori lain', (tester) async {
    await pasang(tester, lokasi: FakeLokasi(cek: IzinLokasi.diizinkan));
    expect(penanda('Pantai Cermin'), findsOneWidget);
    final chip = find.widgetWithText(GestureDetector, 'Budaya').first;
    await tester.ensureVisible(chip); // deretan chip bisa digeser
    await tester.pump();
    await tester.tap(chip);
    await tester.pump(const Duration(milliseconds: 300));
    expect(penanda('Pantai Cermin'), findsNothing);
    expect(penanda('Istana Maimun'), findsOneWidget);
  });

  testWidgets('ketuk penanda menampilkan pratinjau dengan Detail, Rute, dan jarak nyata; tutup menyembunyikannya', (tester) async {
    await pasang(tester, lokasi: FakeLokasi(cek: IzinLokasi.diizinkan, posisi: const Posisi(3.5952, 98.6722)));
    await tester.tap(penanda('Istana Maimun'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Rute'), findsOneWidget);
    expect(find.text('Detail'), findsOneWidget);
    expect(find.textContaining('dari kamu'), findsOneWidget);

    await tester.tap(find.byTooltip('Tutup'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Rute'), findsNothing);
  });

  testWidgets('tanpa lokasi aktif, pratinjau tidak mengarang jarak', (tester) async {
    await pasang(tester, lokasi: FakeLokasi());
    await tester.tap(penanda('Pantai Sorake'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Lokasi belum aktif'), findsOneWidget);
    expect(find.textContaining('dari kamu'), findsNothing);
  });

  testWidgets('titik perkiraan diberi keterangan jujur', (tester) async {
    await pasang(tester, lokasi: FakeLokasi(cek: IzinLokasi.diizinkan));
    await tester.tap(penanda('Pantai Sri Mersing'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Titik perkiraan'), findsOneWidget);
  });

  testWidgets('tanpa izin: banner ajakan; setelah diaktifkan muncul filter radius dan jarak nyata', (tester) async {
    final f = FakeLokasi(posisi: const Posisi(3.5952, 98.6722, akurasiMeter: 20));
    await pasang(tester, lokasi: f);
    expect(find.text('Aktifkan'), findsOneWidget);
    expect(find.text('Semua jarak'), findsNothing);

    await tester.tap(find.text('Aktifkan'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(f.diminta, 1);
    expect(find.text('Aktifkan'), findsNothing);
    expect(find.text('Semua jarak'), findsOneWidget);
    expect(find.text('25 km'), findsOneWidget);

    await tester.tap(penanda('Istana Maimun'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('dari kamu'), findsOneWidget);
  });

  testWidgets('radius menyaring tempat jauh (Nias hilang di 25 km dari Medan)', (tester) async {
    final f = FakeLokasi(cek: IzinLokasi.diizinkan, posisi: const Posisi(3.5952, 98.6722));
    await pasang(tester, lokasi: f);
    await tester.pump(const Duration(milliseconds: 300));
    // kamera sudah diarahkan ke pengguna; semua penanda yang ada di layar boleh dicek lewat logika filter
    await tester.tap(find.text('25 km'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(penanda('Pantai Sorake'), findsNothing); // Nias Selatan ~ 400 km
    expect(penanda('Istana Maimun'), findsOneWidget);
  });

  testWidgets('pelacakan GPS hanya menyala saat tab Peta aktif', (tester) async {
    final f = FakeLokasi(cek: IzinLokasi.diizinkan, posisi: const Posisi(3.5952, 98.6722));
    await pasang(tester, lokasi: f, aktif: false);
    await tester.pump(const Duration(milliseconds: 200));
    expect(f.aliranCtrl.hasListener, isFalse);
  });

  testWidgets('pelacakan menyala saat aktif', (tester) async {
    final f = FakeLokasi(cek: IzinLokasi.diizinkan, posisi: const Posisi(3.5952, 98.6722));
    await pasang(tester, lokasi: f, aktif: true);
    await tester.pump(const Duration(milliseconds: 300));
    expect(f.aliranCtrl.hasListener, isTrue);
  });

  testWidgets('mode gelap tampil tanpa error', (tester) async {
    await pasang(tester, lokasi: FakeLokasi(), gelap: true);
    expect(tester.takeException(), isNull);
    expect(find.byType(FlutterMap), findsOneWidget);
  });
}
