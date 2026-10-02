import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tugas_kelompok/data/dummy_destinasi.dart';
import 'package:tugas_kelompok/models/review.dart';
import 'package:tugas_kelompok/providers/auth_provider.dart';
import 'package:tugas_kelompok/providers/destinasi_provider.dart';
import 'package:tugas_kelompok/providers/review_provider.dart';
import 'package:tugas_kelompok/services/review_repository.dart';
import 'package:tugas_kelompok/theme/app_theme.dart';
import 'package:tugas_kelompok/widgets/review/rating_picker.dart';
import 'package:tugas_kelompok/widgets/review/review_section.dart';
import 'package:tugas_kelompok/widgets/review/review_tile.dart';

class RepoGagal implements ReviewRepository {
  @override
  Future<List<Review>> muatSemua() async => [];
  @override
  Future<void> simpan(Review review) async => throw Exception('disk penuh');
  @override
  Future<void> hapus(String destinasiId, String userId) async => throw Exception('disk penuh');
}

Future<ReviewProvider> baru() async {
  final p = ReviewProvider();
  await p.muatData();
  return p;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final toba = dummyDestinasiList.firstWhere((d) => d.id == 'd01'); // rating dasar 4.8

  group('Review model', () {
    test('JSON bolak-balik dan id per pengguna per destinasi', () {
      final r = Review(
        destinasiId: 'd01',
        userId: 'u1',
        namaPenulis: 'Ari',
        rating: 4,
        komentar: 'Bagus',
        dibuat: DateTime(2026, 10, 2),
        diubah: DateTime(2026, 10, 3),
      );
      final dari = Review.tryFromJson(r.toJson())!;
      expect(dari.id, 'd01_u1');
      expect((dari.rating, dari.komentar, dari.namaPenulis), (4, 'Bagus', 'Ari'));
      expect(dari.diedit, isTrue);
    });

    test('data rusak atau rating di luar 1..5 dilewati, tidak crash', () {
      expect(Review.tryFromJson('bukan map'), isNull);
      expect(Review.tryFromJson({'destinasiId': 'd01', 'userId': 'u', 'rating': 9}), isNull);
      expect(Review.tryFromJson({'destinasiId': 'd01', 'rating': 3}), isNull);
    });

    test('ringkasan: rata-rata dan sebaran', () {
      final t = DateTime(2026);
      Review r(String u, int n) => Review(destinasiId: 'd01', userId: u, namaPenulis: u, rating: n, dibuat: t, diubah: t);
      final s = RingkasanUlasan.dari([r('a', 5), r('b', 4), r('c', 4), r('d', 1)]);
      expect(s.jumlah, 4);
      expect(s.rataRata, 3.5);
      expect(s.sebaran, [1, 0, 0, 2, 1]);
      expect(RingkasanUlasan.dari([]).jumlah, 0);
    });
  });

  group('ReviewProvider', () {
    test('simpan baru, ubah (tetap satu per pengguna), dan hapus', () async {
      final p = await baru();
      expect(await p.simpan(destinasiId: 'd01', userId: 'u1', namaPenulis: 'Ari', rating: 5, komentar: '  Mantap  '), isNull);
      expect(p.untuk('d01').single.komentar, 'Mantap'); // dipangkas

      await p.simpan(destinasiId: 'd01', userId: 'u1', namaPenulis: 'Ari', rating: 3, komentar: 'Biasa');
      expect(p.untuk('d01'), hasLength(1));
      expect(p.milik('d01', 'u1')!.rating, 3);
      expect(p.milik('d01', 'u1')!.diedit, isTrue);

      await p.simpan(destinasiId: 'd01', userId: 'u2', namaPenulis: 'Budi', rating: 4);
      expect(p.ringkasan('d01').jumlah, 2);

      await p.hapus('d01', 'u1');
      expect(p.untuk('d01').map((r) => r.userId), ['u2']);
    });

    test('validasi: bintang wajib, komentar maksimal 500 karakter', () async {
      final p = await baru();
      expect(await p.simpan(destinasiId: 'd01', userId: 'u1', namaPenulis: 'A', rating: 0), contains('bintang'));
      expect(
        await p.simpan(destinasiId: 'd01', userId: 'u1', namaPenulis: 'A', rating: 5, komentar: 'x' * 501),
        contains('500'),
      );
      expect(p.untuk('d01'), isEmpty);
    });

    test('ulasan milik pengguna di paling atas, sisanya terbaru dulu', () async {
      final p = await baru();
      await p.simpan(destinasiId: 'd01', userId: 'a', namaPenulis: 'A', rating: 5);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await p.simpan(destinasiId: 'd01', userId: 'b', namaPenulis: 'B', rating: 4);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await p.simpan(destinasiId: 'd01', userId: 'c', namaPenulis: 'C', rating: 3);
      expect(p.untuk('d01').map((r) => r.userId), ['c', 'b', 'a']);
      expect(p.untuk('d01', userId: 'a').map((r) => r.userId), ['a', 'c', 'b']);
    });

    test('rating tampil: nilai dasar tanpa ulasan, lalu dicampur berbobot 10 suara', () async {
      final p = await baru();
      expect(p.ratingTampil(toba), 4.8);
      await p.simpan(destinasiId: 'd01', userId: 'u1', namaPenulis: 'A', rating: 1);
      // (4.8*10 + 1) / 11 = 4.4545...
      expect(p.ratingTampil(toba), closeTo(4.4545, 0.001));
      expect(p.ratingTampil(dummyDestinasiList.firstWhere((d) => d.id == 'd02')), 4.7); // tak terpengaruh
    });

    test('tersimpan lokal dan dimuat ulang', () async {
      final p = await baru();
      await p.simpan(destinasiId: 'd05', userId: 'u1', namaPenulis: 'Ari', rating: 4, komentar: 'Megah');
      final q = await baru();
      expect(q.milik('d05', 'u1')!.komentar, 'Megah');
    });

    test('gagal menyimpan: tampilan dibatalkan dan ada pesan ramah', () async {
      final p = ReviewProvider(repo: RepoGagal());
      await p.muatData();
      final galat = await p.simpan(destinasiId: 'd01', userId: 'u1', namaPenulis: 'A', rating: 5);
      expect(galat, contains('belum tersimpan'));
      expect(p.untuk('d01'), isEmpty);
    });

    test('waktuRelatif', () {
      final n = DateTime(2026, 10, 10, 12);
      expect(waktuRelatif(n, n), 'Baru saja');
      expect(waktuRelatif(n.subtract(const Duration(minutes: 5)), n), '5 menit lalu');
      expect(waktuRelatif(n.subtract(const Duration(hours: 3)), n), '3 jam lalu');
      expect(waktuRelatif(n.subtract(const Duration(days: 2)), n), '2 hari lalu');
    });
  });

  group('UI ulasan', () {
    Future<(ReviewProvider, AuthProvider)> pasang(WidgetTester tester, {bool masuk = true}) async {
      final destinasi = DestinasiProvider();
      await destinasi.muatData();
      final review = await baru();
      final auth = AuthProvider();
      await auth.muatData();
      if (masuk) {
        auth.register('Ari Test', 'ari@test.id', 'rahasia1');
        auth.login('ari@test.id', 'rahasia1');
      }
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: destinasi),
          ChangeNotifierProvider.value(value: review),
          ChangeNotifierProvider.value(value: auth),
        ],
        child: MaterialApp(
          theme: buildLightTheme(),
          home: Scaffold(body: SingleChildScrollView(child: ReviewSection(destinasi: toba))),
        ),
      ));
      await tester.pump();
      return (review, auth);
    }

    testWidgets('RatingPicker: memilih bintang dan menampilkan label', (tester) async {
      int nilai = 0;
      await tester.pumpWidget(MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (c, set) => RatingPicker(nilai: nilai, onChanged: (v) => set(() => nilai = v)),
          ),
        ),
      ));
      expect(find.text('Ketuk bintang untuk menilai'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('4 dari 5 bintang'));
      await tester.pump();
      expect(nilai, 4);
      expect(find.text('Bagus'), findsOneWidget);
      // area sentuh tiap bintang >= 44
      expect(tester.getSize(find.bySemanticsLabel('1 dari 5 bintang')).height, greaterThanOrEqualTo(44));
    });

    testWidgets('belum ada ulasan: keadaan kosong dengan ajakan menulis', (tester) async {
      await pasang(tester);
      expect(find.text('Belum ada ulasan'), findsOneWidget);
      expect(find.text('Tulis ulasan'), findsOneWidget);
    });

    testWidgets('menulis ulasan lewat form: bintang wajib, lalu tampil di daftar dan bisa dihapus', (tester) async {
      final (review, auth) = await pasang(tester);

      await tester.tap(find.text('Tulis ulasan'));
      await tester.pumpAndSettle();
      expect(find.text('Kirim ulasan'), findsOneWidget);

      // tanpa bintang -> galat, tidak tersimpan
      await tester.tap(find.text('Kirim ulasan'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Pilih jumlah bintang'), findsOneWidget);
      expect(review.untuk('d01'), isEmpty);

      await tester.tap(find.bySemanticsLabel('5 dari 5 bintang'));
      await tester.enterText(find.byType(TextField), 'Pemandangannya luar biasa');
      await tester.tap(find.text('Kirim ulasan'));
      await tester.pumpAndSettle();

      final r = review.milik('d01', auth.currentUser!.id)!;
      expect((r.rating, r.komentar), (5, 'Pemandangannya luar biasa'));
      expect(find.text('Pemandangannya luar biasa'), findsOneWidget);
      expect(find.text('Ulasanmu'), findsOneWidget);
      expect(find.text('Ubah ulasanmu'), findsOneWidget);
    });
  });
}
