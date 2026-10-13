import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/destinasi.dart';

/// Tautan petunjuk arah Google Maps ke koordinat destinasi (titik asal = posisi pengguna).
Uri uriRute(Destinasi d) => Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${d.lat},${d.lng}&travelmode=driving',
    );

/// Membuka rute di aplikasi peta/ browser. Mengembalikan false bila gagal dibuka.
Future<bool> bukaRute(Destinasi d, {Future<bool> Function(Uri uri)? luncurkan}) async {
  final uri = uriRute(d);
  try {
    return await (luncurkan ?? (u) => launchUrl(u, mode: LaunchMode.externalApplication))(uri);
  } catch (e) {
    debugPrint('bukaRute gagal: $e');
    return false;
  }
}

/// Google Maps menerima titik tujuan + paling banyak 9 titik singgah.
const maksPerhentianRute = 10;

/// Hasil penyusunan rute rencana: tautan, jumlah perhentian yang ikut, dan yang terpotong.
class RuteRencana {
  final Uri uri;
  final int dipakai;
  final int terpotong;

  const RuteRencana(this.uri, {required this.dipakai, required this.terpotong});
}

/// Rute berurutan melalui semua [daftar] (titik asal = posisi pengguna). Lebih dari
/// [maksPerhentianRute] perhentian dipotong dari belakang dan dilaporkan di [RuteRencana.terpotong].
RuteRencana? rancangRuteRencana(List<Destinasi> daftar) {
  if (daftar.isEmpty) return null;
  final dipakai = daftar.take(maksPerhentianRute).toList();
  final tujuan = dipakai.last;
  final singgah = dipakai.sublist(0, dipakai.length - 1);
  final params = <String>[
    'api=1',
    'destination=${tujuan.lat},${tujuan.lng}',
    if (singgah.isNotEmpty) 'waypoints=${singgah.map((d) => '${d.lat},${d.lng}').join('%7C')}',
    'travelmode=driving',
  ];
  return RuteRencana(
    Uri.parse('https://www.google.com/maps/dir/?${params.join('&')}'),
    dipakai: dipakai.length,
    terpotong: daftar.length - dipakai.length,
  );
}

/// Membuka rute rencana di Google Maps. Null bila rencana kosong; false bila gagal dibuka.
Future<bool?> bukaRuteRencana(List<Destinasi> daftar, {Future<bool> Function(Uri uri)? luncurkan}) async {
  final rute = rancangRuteRencana(daftar);
  if (rute == null) return null;
  try {
    return await (luncurkan ?? (u) => launchUrl(u, mode: LaunchMode.externalApplication))(rute.uri);
  } catch (e) {
    debugPrint('bukaRuteRencana gagal: $e');
    return false;
  }
}
