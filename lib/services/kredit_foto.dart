import 'dart:convert';
import 'package:flutter/services.dart';

/// Atribusi satu foto (syarat lisensi CC BY / CC BY-SA dari Wikimedia Commons).
class KreditFoto {
  final String file;
  final String judul;
  final String fotografer;
  final String lisensi;
  final String sumber;

  const KreditFoto({
    required this.file,
    required this.judul,
    required this.fotografer,
    required this.lisensi,
    required this.sumber,
  });

  factory KreditFoto.fromJson(Map<String, dynamic> j) => KreditFoto(
        file: j['file'] as String? ?? '',
        judul: j['judul'] as String? ?? '',
        fotografer: j['fotografer'] as String? ?? 'Tidak diketahui',
        lisensi: j['lisensi'] as String? ?? '',
        sumber: j['sumber'] as String? ?? '',
      );

  String get ringkas => '$fotografer · $lisensi';
}

class KreditFotoService {
  KreditFotoService._();

  static Map<String, List<KreditFoto>>? _cache;

  /// id destinasi (atau "banner") -> daftar kredit foto.
  static Future<Map<String, List<KreditFoto>>> muat([AssetBundle? bundle]) async {
    final c = _cache;
    if (c != null && bundle == null) return c;
    try {
      final raw = await (bundle ?? rootBundle).loadString('assets/destinasi/kredit.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final hasil = {
        for (final e in json.entries)
          e.key: [for (final k in e.value as List) KreditFoto.fromJson(k as Map<String, dynamic>)],
      };
      if (bundle == null) _cache = hasil;
      return hasil;
    } catch (_) {
      return {}; // atribusi gagal dimuat: jangan sampai merusak layar
    }
  }
}
