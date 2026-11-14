import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tugas_kelompok/models/rencana_perjalanan.dart';
import 'package:tugas_kelompok/models/user.dart';
import 'package:tugas_kelompok/providers/auth_provider.dart';
import 'package:tugas_kelompok/providers/destinasi_provider.dart';
import 'package:tugas_kelompok/providers/lokasi_provider.dart';
import 'package:tugas_kelompok/providers/rencana_provider.dart';
import 'package:tugas_kelompok/providers/review_provider.dart';
import 'package:tugas_kelompok/screens/checklist/checklist_screen.dart';
import 'package:tugas_kelompok/screens/destinasi/detail_destinasi_screen.dart';
import 'package:tugas_kelompok/theme/app_theme.dart';

Widget _bungkusDenganTema({
  required Widget child,
  AuthProvider? auth,
  DestinasiProvider? destinasi,
}) {
  return MultiProvider(
    providers: [
      if (auth != null) ChangeNotifierProvider.value(value: auth),
      if (destinasi != null) ChangeNotifierProvider.value(value: destinasi),
      ChangeNotifierProvider(create: (_) => ReviewProvider()),
      ChangeNotifierProvider(create: (_) => LokasiProvider()),
    ],
    child: MaterialApp(
      theme: buildLightTheme(),
      home: child,
    ),
  );
}

void main() {
  testWidgets('ChecklistScreen memuat daftar bawaan dan menyimpan perubahan per-user',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final auth = AuthProvider()
      ..currentUser = const User(
        id: 'u1',
        nama: 'Indah',
        email: 'indah@example.com',
      )
      ..isLoading = false;

    await tester.pumpWidget(_bungkusDenganTema(
      auth: auth,
      child: const ChecklistScreen(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Checklist Persiapan'), findsOneWidget);
    expect(find.text('0 dari 5 perlengkapan siap'), findsOneWidget);

    // Tambah item baru dan simpan
    await tester.enterText(find.byType(TextField), 'Jas hujan lipat');
    await tester.tap(find.byTooltip('Tambah perlengkapan'));
    await tester.pumpAndSettle();

    expect(find.text('Jas hujan lipat'), findsOneWidget);
    expect(find.text('0 dari 6 perlengkapan siap'), findsOneWidget);

    // Centang item baru
    await tester.tap(find.text('Jas hujan lipat'));
    await tester.pumpAndSettle();
    expect(find.text('1 dari 6 perlengkapan siap'), findsOneWidget);

    // Mount ulang dengan user yang sama: data tetap bertahan
    await tester.pumpWidget(_bungkusDenganTema(
      auth: auth,
      child: const ChecklistScreen(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Jas hujan lipat'), findsOneWidget);
    expect(find.text('1 dari 6 perlengkapan siap'), findsOneWidget);

    // Pindah ke user lain: daftar kembali ke bawaan (terisolasi per user)
    final authLain = AuthProvider()
      ..currentUser = const User(
        id: 'u2',
        nama: 'Ariel',
        email: 'ariel@example.com',
      )
      ..isLoading = false;
    await tester.pumpWidget(_bungkusDenganTema(
      auth: authLain,
      child: const ChecklistScreen(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Jas hujan lipat'), findsNothing);
    expect(find.text('0 dari 5 perlengkapan siap'), findsOneWidget);
  });

  test('DestinasiProvider mengisolasi favorit & riwayat per-user serta mendukung toggleKunjungan & cari lokasi',
      () async {
    SharedPreferences.setMockInitialValues({});
    final destinasi = DestinasiProvider();

    await destinasi.gantiUser('u1');
    destinasi.toggleFavorit('d01');
    final ditandai = await destinasi.toggleKunjungan('u1', 'd01');
    expect(ditandai, isTrue);
    expect(destinasi.sudahDikunjungi('d01'), isTrue);
    expect(destinasi.daftarFavorit.map((d) => d.id), ['d01']);

    // Pindah ke u2: favorit & riwayat kosong
    await destinasi.gantiUser('u2');
    expect(destinasi.daftarFavorit, isEmpty);
    expect(destinasi.sudahDikunjungi('d01'), isFalse);

    // Kembali ke u1: data pulih kembali dan bisa dibatalkan lewat toggleKunjungan
    await destinasi.gantiUser('u1');
    expect(destinasi.daftarFavorit.map((d) => d.id), ['d01']);
    expect(destinasi.sudahDikunjungi('d01'), isTrue);

    final setelahBatal = await destinasi.toggleKunjungan('u1', 'd01');
    expect(setelahBatal, isFalse);
    expect(destinasi.sudahDikunjungi('d01'), isFalse);

    // Pencarian mencakup nama dan lokasi
    final hasilLokasi = destinasi.cari(query: 'Karo');
    expect(hasilLokasi, isNotEmpty);
  });

  test('RencanaProvider mengisolasi rencana perjalanan per-user', () async {
    SharedPreferences.setMockInitialValues({});
    final rencana = RencanaProvider();

    await rencana.gantiUser('u1');
    final awalU1 = rencana.daftarRencana.length;
    rencana.tambahRencana(RencanaPerjalanan(
      id: 'r_khusus_u1',
      judul: 'Trip Khusus U1',
      tanggalMulai: DateTime(2026, 6, 1),
      tanggalSelesai: DateTime(2026, 6, 2),
      daftarDestinasiId: const ['d01'],
    ));
    expect(rencana.daftarRencana.length, awalU1 + 1);

    await rencana.gantiUser('u2');
    expect(rencana.getById('r_khusus_u1'), isNull);

    await rencana.gantiUser('u1');
    expect(rencana.getById('r_khusus_u1'), isNotNull);
  });

  testWidgets('DetailDestinasiScreen menampilkan chip interaktif status kunjungan dan 2 CTA utama',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(800, 2200);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final auth = AuthProvider()
      ..currentUser = const User(
        id: 'u1',
        nama: 'Budi',
        email: 'budi@example.com',
      )
      ..isLoading = false;
    final destinasi = DestinasiProvider();
    await destinasi.gantiUser('u1');

    await tester.pumpWidget(_bungkusDenganTema(
      auth: auth,
      destinasi: destinasi,
      child: const DetailDestinasiScreen(destinasiId: 'd01'),
    ));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Tandai dikunjungi'), findsOneWidget);
    expect(find.text('Tambah ke Rencana'), findsOneWidget);
    expect(find.text('Tanya Tripy tentang tempat ini'), findsOneWidget);

    await tester.tap(find.text('Tandai dikunjungi'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(destinasi.sudahDikunjungi('d01'), isTrue);
    expect(find.textContaining('Dikunjungi · '), findsOneWidget);
  });
}
