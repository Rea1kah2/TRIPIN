import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tugas_kelompok/models/destinasi.dart';
import 'package:tugas_kelompok/models/rencana_perjalanan.dart';
import 'package:tugas_kelompok/providers/destinasi_provider.dart';
import 'package:tugas_kelompok/providers/lokasi_provider.dart';
import 'package:tugas_kelompok/providers/rencana_provider.dart';
import 'package:tugas_kelompok/providers/review_provider.dart';
import 'package:tugas_kelompok/routes/app_routes.dart';
import 'package:tugas_kelompok/screens/rencana/detail_rencana_screen.dart';
import 'package:tugas_kelompok/screens/rencana/peta_rencana_screen.dart';
import 'package:tugas_kelompok/services/location_service.dart';
import 'package:tugas_kelompok/services/rute.dart';
import 'package:tugas_kelompok/theme/app_theme.dart';
import 'package:tugas_kelompok/utils/geo.dart';

import 'lokasi_test.dart' show FakeLokasi;

class _TileKosong extends TileProvider {
  static final _png = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) => MemoryImage(_png);
}

Future<List<Destinasi>> _ambil(List<String> id) async {
  final dp = DestinasiProvider();
  await dp.muatData();
  return [for (final i in id) dp.getById(i)!];
}

Widget _bungkus(Widget layar, {required DestinasiProvider dp, RencanaProvider? rp, LokasiProvider? lp}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: dp),
      if (rp != null) ChangeNotifierProvider.value(value: rp),
      ChangeNotifierProvider.value(value: lp ?? LokasiProvider(service: FakeLokasi())),
      ChangeNotifierProvider(create: (_) => ReviewProvider()),
    ],
    child: MaterialApp(
      theme: buildLightTheme(),
      onGenerateRoute: AppRoutes.onGenerateRoute,
      home: layar,
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('panjangRuteKm', () {
    test('kurang dari dua titik = 0; jumlah jarak antar titik berurutan', () {
      expect(panjangRuteKm([]), 0);
      expect(panjangRuteKm([(lat: 3.5, lng: 98.6)]), 0);
      final a = (lat: 3.5952, lng: 98.6722);
      final b = (lat: 2.66176, lng: 98.93918);
      final c = (lat: 2.9, lng: 98.5);
      expect(
        panjangRuteKm([a, b, c]),
        closeTo(jarakKm(a.lat, a.lng, b.lat, b.lng) + jarakKm(b.lat, b.lng, c.lat, c.lng), 1e-9),
      );
    });
  });

  group('rancangRuteRencana', () {
    test('kosong = null; satu tempat tanpa waypoints', () async {
      expect(rancangRuteRencana([]), isNull);
      final d = await _ambil(['d01']);
      final r = rancangRuteRencana(d)!;
      expect(r.uri.queryParameters['destination'], '${d[0].lat},${d[0].lng}');
      expect(r.uri.queryParameters.containsKey('waypoints'), isFalse);
      expect(r.terpotong, 0);
    });

    test('tujuan = tempat terakhir, singgah berurutan dipisah |', () async {
      final d = await _ambil(['d01', 'd08', 'd15']);
      final r = rancangRuteRencana(d)!;
      expect(r.uri.queryParameters['destination'], '${d[2].lat},${d[2].lng}');
      expect(r.uri.queryParameters['waypoints'], '${d[0].lat},${d[0].lng}|${d[1].lat},${d[1].lng}');
      expect(r.uri.queryParameters['travelmode'], 'driving');
      expect(r.dipakai, 3);
    });

    test('lebih dari 10 perhentian dipotong dan dilaporkan', () async {
      final dp = DestinasiProvider();
      await dp.muatData();
      final banyak = dp.daftarDestinasi.take(13).toList();
      final r = rancangRuteRencana(banyak)!;
      expect(r.dipakai, maksPerhentianRute);
      expect(r.terpotong, 3);
      expect(r.uri.queryParameters['waypoints']!.split('|').length, maksPerhentianRute - 1);
      expect(r.uri.queryParameters['destination'], '${banyak[9].lat},${banyak[9].lng}');
    });

    test('bukaRuteRencana: kosong null, sukses, gagal, dan pengecualian', () async {
      final d = await _ambil(['d01', 'd08']);
      expect(await bukaRuteRencana([], luncurkan: (_) async => true), isNull);
      Uri? dibuka;
      expect(await bukaRuteRencana(d, luncurkan: (u) async { dibuka = u; return true; }), isTrue);
      expect(dibuka, isNotNull);
      expect(await bukaRuteRencana(d, luncurkan: (_) async => false), isFalse);
      expect(await bukaRuteRencana(d, luncurkan: (_) async => throw Exception('x')), isFalse);
    });
  });

  group('RencanaProvider.urutUlangDestinasi', () {
    Future<RencanaProvider> siap() async {
      final rp = RencanaProvider();
      await rp.muatData();
      rp.tambahRencana(RencanaPerjalanan(
        id: 'rx',
        judul: 'Uji',
        tanggalMulai: DateTime(2026, 1, 1),
        tanggalSelesai: DateTime(2026, 1, 2),
        daftarDestinasiId: ['a', 'b', 'c'],
      ));
      return rp;
    }

    test('pindah ke bawah memakai konvensi ReorderableListView dan tersimpan', () async {
      final rp = await siap();
      rp.urutUlangDestinasi('rx', 0, 3); // a ke paling akhir
      expect(rp.getById('rx')!.daftarDestinasiId, ['b', 'c', 'a']);
      final rp2 = RencanaProvider();
      await rp2.muatData();
      expect(rp2.getById('rx')!.daftarDestinasiId, ['b', 'c', 'a']);
    });

    test('pindah ke atas, indeks tak valid, dan posisi sama tidak mengubah apa pun', () async {
      final rp = await siap();
      rp.urutUlangDestinasi('rx', 2, 0);
      expect(rp.getById('rx')!.daftarDestinasiId, ['c', 'a', 'b']);
      rp.urutUlangDestinasi('rx', 1, 1);
      rp.urutUlangDestinasi('rx', 1, 2); // setelah dicabut tetap di indeks 1
      rp.urutUlangDestinasi('rx', 9, 0);
      rp.urutUlangDestinasi('tidak-ada', 0, 1);
      expect(rp.getById('rx')!.daftarDestinasiId, ['c', 'a', 'b']);
    });
  });

  group('PetaRencanaScreen', () {
    Future<void> pasang(WidgetTester tester, List<Destinasi> daftar,
        {Future<bool> Function(Uri)? luncurkan, LokasiProvider? lp}) async {
      tester.view.physicalSize = const Size(800, 1700);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final dp = DestinasiProvider();
      await dp.muatData();
      await tester.pumpWidget(_bungkus(
        PetaRencanaScreen(judul: 'Rencanaku', daftar: daftar, tileProvider: _TileKosong(), luncurkan: luncurkan),
        dp: dp,
        lp: lp,
      ));
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('penanda bernomor sesuai urutan, ringkasan jarak jujur, dan tombol memanggil peluncur', (tester) async {
      final daftar = await _ambil(['d01', 'd08', 'd15']);
      Uri? dibuka;
      await pasang(tester, daftar, luncurkan: (u) async {
        dibuka = u;
        return true;
      });
      for (var i = 1; i <= 3; i++) {
        expect(find.bySemanticsLabel(RegExp('^Perhentian $i: ')), findsOneWidget);
      }
      expect(find.textContaining('3 perhentian · total ±'), findsOneWidget);
      expect(find.textContaining('bukan jarak jalan'), findsOneWidget);
      expect(find.textContaining('Dari posisimu'), findsNothing); // lokasi belum aktif: tidak mengarang

      await tester.tap(find.text('Buka rute di Google Maps'));
      await tester.pump();
      expect(dibuka, isNotNull);
      expect(dibuka!.queryParameters['destination'], '${daftar.last.lat},${daftar.last.lng}');
    });

    testWidgets('lokasi aktif menampilkan jarak ke perhentian pertama', (tester) async {
      final daftar = await _ambil(['d01', 'd08']);
      final lp = LokasiProvider(service: FakeLokasi(cek: IzinLokasi.diizinkan, posisi: const Posisi(3.5952, 98.6722)));
      await pasang(tester, daftar, lp: lp);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('Dari posisimu ke perhentian 1:'), findsOneWidget);
    });

    testWidgets('daftar perhentian menampilkan jarak antar titik', (tester) async {
      final daftar = await _ambil(['d01', 'd08', 'd15']);
      await pasang(tester, daftar);
      await tester.tap(find.byTooltip('Daftar perhentian'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Urutan kunjungan'), findsOneWidget);
      expect(find.textContaining('(garis lurus)'), findsNWidgets(2));
    });

    testWidgets('gagal membuka peta memberi pesan ramah', (tester) async {
      final daftar = await _ambil(['d01', 'd08']);
      await pasang(tester, daftar, luncurkan: (_) async => false);
      await tester.tap(find.text('Buka rute di Google Maps'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Tidak bisa membuka peta'), findsOneWidget);
    });

    testWidgets('rencana dengan satu tempat dan rencana kosong tidak error', (tester) async {
      await pasang(tester, await _ambil(['d01']));
      expect(find.text('1 perhentian'), findsOneWidget);
      await pasang(tester, const []);
      expect(find.text('0 perhentian'), findsOneWidget);
      expect(tester.widget<GestureDetector>(find.ancestor(of: find.text('Buka rute di Google Maps'), matching: find.byType(GestureDetector)).first), isNotNull);
    });
  });

  group('DetailRencanaScreen', () {
    Future<(RencanaProvider, DestinasiProvider)> pasangDetail(WidgetTester tester, List<String> id) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final dp = DestinasiProvider();
      await dp.muatData();
      final rp = RencanaProvider();
      await rp.muatData();
      rp.tambahRencana(RencanaPerjalanan(
        id: 'rx',
        judul: 'Uji Rute',
        tanggalMulai: DateTime(2026, 1, 1),
        tanggalSelesai: DateTime(2026, 1, 2),
        daftarDestinasiId: id,
      ));
      await tester.pumpWidget(_bungkus(const DetailRencanaScreen(rencanaId: 'rx'), dp: dp, rp: rp));
      await tester.pump(const Duration(milliseconds: 400));
      return (rp, dp);
    }

    testWidgets('seret pegangan mengubah urutan dan tersimpan; nomor mengikuti urutan', (tester) async {
      final (rp, _) = await pasangDetail(tester, ['d01', 'd08', 'd15']);
      expect(find.byIcon(Icons.drag_handle), findsNWidgets(3));
      await tester.drag(find.byIcon(Icons.drag_handle).first, const Offset(0, 420));
      await tester.pump(const Duration(milliseconds: 600));
      final urutan = rp.getById('rx')!.daftarDestinasiId;
      expect(urutan.first, isNot('d01'));
      expect(urutan.toSet(), {'d01', 'd08', 'd15'});
      expect(urutan.indexOf('d01'), greaterThan(0));
    });

    testWidgets('tombol Lihat di peta muncul bila ada tempat dan membuka peta rencana', (tester) async {
      await pasangDetail(tester, ['d01', 'd08']);
      expect(find.text('Lihat di peta'), findsOneWidget);
      await tester.tap(find.text('Lihat di peta'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byType(PetaRencanaScreen), findsOneWidget);
    });

    testWidgets('rencana kosong: tanpa tombol peta dan tanpa pegangan seret', (tester) async {
      await pasangDetail(tester, const []);
      expect(find.text('Lihat di peta'), findsNothing);
      expect(find.byIcon(Icons.drag_handle), findsNothing);
    });

    testWidgets('satu tempat: ada tombol peta tetapi tanpa pegangan seret', (tester) async {
      await pasangDetail(tester, ['d01']);
      expect(find.text('Lihat di peta'), findsOneWidget);
      expect(find.byIcon(Icons.drag_handle), findsNothing);
    });
  });
}
