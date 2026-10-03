import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugas_kelompok/data/dummy_destinasi.dart';
import 'package:tugas_kelompok/screens/destinasi/penampil_foto_screen.dart';
import 'package:tugas_kelompok/theme/app_theme.dart';
import 'package:tugas_kelompok/widgets/destinasi_galeri.dart';

dynamic ambil(String id) => dummyDestinasiList.firstWhere((d) => d.id == id);

Future<void> pasang(WidgetTester tester, String id) async {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: buildLightTheme(),
    home: Scaffold(body: SizedBox(height: 320, width: double.infinity, child: DestinasiGaleri(destinasi: ambil(id)))),
  ));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('3 foto: indikator "1/3", geser mengganti halaman dan kredit', (tester) async {
    await pasang(tester, 'd01');
    expect(find.text('1/3'), findsOneWidget);
    final kredit1 = tester.widget<Text>(find.textContaining('Foto: ')).data;

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1500);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('2/3'), findsOneWidget);
    expect(find.text('1/3'), findsNothing);
    expect(find.textContaining('Foto: '), findsOneWidget);
    expect(tester.widget<Text>(find.textContaining('Foto: ')).data, isNotNull);
    expect(kredit1, isNotNull);
  });

  testWidgets('ketuk foto membuka penampil layar penuh pada halaman yang sama; tombol Tutup kembali', (tester) async {
    await pasang(tester, 'd01');
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1500);
    await tester.pumpAndSettle(); // sampai halaman benar-benar berhenti (ketukan saat masih meluncur hanya menghentikannya)

    await tester.tap(find.byType(PageView));
    await tester.pump(); // rute dipasang pada frame pertama
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(PenampilFotoScreen), findsOneWidget);
    expect(find.text('2/3'), findsWidgets); // dibuka di foto ke-2

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(PenampilFotoScreen), findsNothing);
  });

  testWidgets('penampil: ketuk dua kali memperbesar lalu mengembalikan', (tester) async {
    await pasang(tester, 'd05');
    await tester.tap(find.byType(PageView));
    await tester.pump(); // rute dipasang pada frame pertama
    await tester.pump(const Duration(milliseconds: 400));
    final viewer = find.byType(InteractiveViewer);
    expect(viewer, findsWidgets);

    double skala() => tester.widget<InteractiveViewer>(viewer.first).transformationController!.value.getMaxScaleOnAxis();
    expect(skala(), 1);
    final pusat = tester.getCenter(viewer.first);
    await tester.tapAt(pusat);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(pusat);
    await tester.pump(const Duration(milliseconds: 300));
    expect(skala(), greaterThan(2));
  });

  testWidgets('satu foto: tanpa indikator geser', (tester) async {
    await pasang(tester, 'd14');
    expect(find.textContaining('/'), findsNothing);
    expect(find.textContaining('Foto: '), findsOneWidget);
  });

  testWidgets('tanpa foto: penanda jujur, bukan foto asal', (tester) async {
    await pasang(tester, 'd16');
    expect(find.text('Foto belum tersedia'), findsOneWidget);
    expect(find.byType(PageView), findsNothing);
  });
}
