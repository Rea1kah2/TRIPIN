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
    // Commons tidak punya foto layak untuk d16 (Mangrove Percut), d17 (Sri Mersing), d23 (Rahmat Gallery).
    expect(tanpaFoto, ['d16', 'd17', 'd23']);
    expect(dummyDestinasiList.firstWhere((d) => d.id == 'd16').fotoUtama, isNull);
  });

  test('tidak ada lagi URL gambar acak (unsplash/picsum) di data', () {
    final isi = File('lib/data/dummy_destinasi.dart').readAsStringSync();
    expect(isi.contains('unsplash'), isFalse);
    expect(isi.contains('picsum'), isFalse);
  });
}
