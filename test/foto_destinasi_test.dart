import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugas_kelompok/data/dummy_destinasi.dart';
import 'package:tugas_kelompok/services/kredit_foto.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('setiap foto yang dipakai ada di disk dan punya atribusi', () async {
    final kredit = await KreditFotoService.muat(rootBundle);
    for (final d in dummyDestinasiList) {
      for (final f in d.fotoAssets) {
        expect(File(f).existsSync(), isTrue, reason: '${d.id}: $f tidak ada');
        final k = kredit[d.id];
        expect(k, isNotNull, reason: '${d.id} tanpa atribusi');
        expect(k!.any((e) => e.file == f), isTrue, reason: '$f tanpa atribusi');
        expect(k.first.lisensi, isNotEmpty);
        expect(k.first.fotografer, isNotEmpty);
      }
    }
    expect(kredit['banner'], isNotNull);
  });

  test('destinasi tanpa foto asli dinyatakan jujur (tidak memakai foto asal)', () {
    final tanpaFoto = dummyDestinasiList.where((d) => d.fotoAssets.isEmpty).map((d) => d.id).toList();
    // Commons tidak punya foto yang cocok untuk d16 (Mangrove Percut) dan d17 (Sri Mersing).
    expect(tanpaFoto, ['d16', 'd17']);
    expect(dummyDestinasiList.firstWhere((d) => d.id == 'd16').fotoUtama, isNull);
  });

  test('galeri: 1-3 foto per tempat, semua berkredit lengkap dan berurutan', () async {
    final kredit = await KreditFotoService.muat(rootBundle);
    for (final d in dummyDestinasiList.where((d) => d.fotoAssets.isNotEmpty)) {
      expect(d.fotoAssets.length, inInclusiveRange(1, 3), reason: d.id);
      expect(kredit[d.id]!.map((k) => k.file).toList(), d.fotoAssets, reason: '${d.id}: urutan kredit = urutan foto');
      expect(d.fotoAssets.toSet().length, d.fotoAssets.length, reason: '${d.id}: tanpa duplikat');
    }
    // sebagian besar tempat sudah punya galeri penuh
    expect(dummyDestinasiList.where((d) => d.fotoAssets.length == 3).length, greaterThanOrEqualTo(24));
  });

  test('tidak ada lagi URL gambar acak (unsplash/picsum) di data', () {
    final isi = File('lib/data/dummy_destinasi.dart').readAsStringSync();
    expect(isi.contains('unsplash'), isFalse);
    expect(isi.contains('picsum'), isFalse);
  });
}
