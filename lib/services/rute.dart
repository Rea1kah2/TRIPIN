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
