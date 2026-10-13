import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tugas_kelompok/data/dummy_destinasi.dart';
import 'package:tugas_kelompok/providers/chat_provider.dart';
import 'package:tugas_kelompok/providers/destinasi_provider.dart';
import 'package:tugas_kelompok/providers/lokasi_provider.dart';
import 'package:tugas_kelompok/providers/rencana_provider.dart';
import 'package:tugas_kelompok/services/location_service.dart';
import 'package:tugas_kelompok/services/rute.dart';
import 'package:tugas_kelompok/utils/geo.dart';

class FakeLokasi implements LocationService {
  IzinLokasi cek;
  IzinLokasi setelahMinta;
  Posisi? posisi;
  final aliranCtrl = StreamController<Posisi>.broadcast();
  int diminta = 0;
  int pengaturan = 0;

  FakeLokasi({this.cek = IzinLokasi.ditolak, this.setelahMinta = IzinLokasi.diizinkan, this.posisi});

  @override
  Future<IzinLokasi> cekIzin() async => cek;
  @override
  Future<IzinLokasi> mintaIzin() async {
    diminta++;
    cek = setelahMinta;
    return setelahMinta;
  }

  @override
  Future<Posisi?> posisiSekarang() async => posisi;
  @override
  Stream<Posisi> aliran() => aliranCtrl.stream;
  @override
  Future<void> bukaPengaturanAplikasi() async => pengaturan++;
  @override
  Future<void> bukaPengaturanLokasi() async => pengaturan += 10;
}

const medan = Posisi(3.5952, 98.6722);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('geo', () {
    test('jarakKm: titik sama nol, Medan-Parapat sekitar 108 km, simetris', () {
      expect(jarakKm(3.5, 98.6, 3.5, 98.6), closeTo(0, 1e-9));
      final a = jarakKm(3.5952, 98.6722, 2.66176, 98.93918);
      expect(a, inInclusiveRange(100, 115));
      expect(jarakKm(2.66176, 98.93918, 3.5952, 98.6722), closeTo(a, 1e-9));
    });

    test('formatJarak: meter, satu desimal berkoma, dan bulat', () {
      expect(formatJarak(0.85), '850 m');
      expect(formatJarak(4.23), '4,2 km');
      expect(formatJarak(127.6), '128 km');
    });
  });

  group('data destinasi', () {
    test('semua memiliki koordinat Sumatera Utara dan id unik', () {
      expect(dummyDestinasiList, hasLength(32));
      expect(dummyDestinasiList.map((d) => d.id).toSet(), hasLength(32));
      for (final d in dummyDestinasiList) {
        expect(d.lat, inInclusiveRange(0.4, 4.3), reason: d.id);
        expect(d.lng, inInclusiveRange(97.0, 100.5), reason: d.id);
      }
    });
  });

  group('LokasiProvider', () {
    test('belum diizinkan: tanpa posisi dan tanpa jarak (bukan angka palsu)', () async {
      final p = LokasiProvider(service: FakeLokasi());
      await p.muatAwal();
      expect(p.diizinkan, isFalse);
      expect(p.adaPosisi, isFalse);
      expect(p.jarakKe(dummyDestinasiList.first), isNull);
      // urutan asli dikembalikan bila posisi tidak diketahui
      expect(p.urutTerdekat(dummyDestinasiList).first.id, 'd01');
    });

    test('sudah diizinkan sejak awal: posisi diambil otomatis tanpa dialog', () async {
      final f = FakeLokasi(cek: IzinLokasi.diizinkan, posisi: medan);
      final p = LokasiProvider(service: f);
      await p.muatAwal();
      expect(p.adaPosisi, isTrue);
      expect(f.diminta, 0);
    });

    test('aktifkan(): minta izin lalu ambil posisi; urut terdekat dan jarak nyata', () async {
      final p = LokasiProvider(service: FakeLokasi(posisi: medan));
      await p.muatAwal();
      await p.aktifkan();
      expect(p.diizinkan, isTrue);
      final urut = p.urutTerdekat(dummyDestinasiList);
      expect(urut.first.id, anyOf('d24', 'd21', 'd22', 'd05', 'd23')); // pusat kota Medan
      final j = [for (final d in urut) p.jarakKe(d)!];
      expect(j, [...j]..sort());
      expect(p.jarakKe(dummyDestinasiList.firstWhere((d) => d.id == 'd30'))!, greaterThan(300)); // Nias
    });

    test('ditolak permanen: tidak ada posisi, aksi membuka pengaturan', () async {
      final f = FakeLokasi(setelahMinta: IzinLokasi.ditolakPermanen);
      final p = LokasiProvider(service: f);
      await p.aktifkan();
      expect(p.izin, IzinLokasi.ditolakPermanen);
      await p.bukaPengaturan();
      expect(f.pengaturan, 1);
    });

    test('layanan lokasi mati: buka pengaturan lokasi', () async {
      final f = FakeLokasi(cek: IzinLokasi.layananMati);
      final p = LokasiProvider(service: f);
      await p.muatAwal();
      await p.bukaPengaturan();
      expect(f.pengaturan, 10);
    });

    test('pelacakan hanya saat diminta: aliran memperbarui posisi, berhenti memutus', () async {
      final f = FakeLokasi(cek: IzinLokasi.diizinkan, posisi: medan);
      final p = LokasiProvider(service: f);
      await p.muatAwal();
      p.mulaiLacak();
      expect(f.aliranCtrl.hasListener, isTrue);
      f.aliranCtrl.add(const Posisi(3.2, 98.5));
      await Future<void>.delayed(Duration.zero);
      expect(p.posisi!.lat, 3.2);
      p.berhentiLacak();
      expect(f.aliranCtrl.hasListener, isFalse);
    });

    test('tidak melacak bila belum diizinkan', () async {
      final f = FakeLokasi();
      final p = LokasiProvider(service: f);
      await p.muatAwal();
      p.mulaiLacak();
      expect(f.aliranCtrl.hasListener, isFalse);
    });
  });

  group('konteks chat', () {
    test('posisi dibulatkan kasar (2 desimal) dan hanya ada bila diketahui', () async {
      final d = DestinasiProvider();
      await d.muatData();
      final r = RencanaProvider();
      await r.muatData();
      expect(bangunKonteks(d, r).containsKey('posisi'), isFalse);
      final k = bangunKonteks(d, r, posisi: const Posisi(3.595234, 98.672291));
      expect(k['posisi'], {'lat': 3.6, 'lng': 98.67});
    });
  });

  group('rute', () {
    test('URL Google Maps ke koordinat destinasi', () {
      final d = dummyDestinasiList.firstWhere((x) => x.id == 'd05');
      final u = uriRute(d);
      expect(u.host, 'www.google.com');
      expect(u.queryParameters['destination'], '${d.lat},${d.lng}');
      expect(u.queryParameters['api'], '1');
    });

    test('bukaRute: sukses, gagal, dan pengecualian ditangani', () async {
      final d = dummyDestinasiList.first;
      expect(await bukaRute(d, luncurkan: (_) async => true), isTrue);
      expect(await bukaRute(d, luncurkan: (_) async => false), isFalse);
      expect(await bukaRute(d, luncurkan: (_) async => throw Exception('tak ada aplikasi')), isFalse);
    });
  });
}
