import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Hash password dengan PBKDF2-HMAC-SHA256 + garam acak.
///
/// Format tersimpan: `pbkdf2$<iterasi>$<garam-base64>$<hash-base64>`.
/// Ini pengerasan untuk penyimpanan LOKAL; akun cloud (Firebase) akan menggantikannya.
class PasswordHasher {
  static const iterasiDefault = 10000;
  static const _panjangGaram = 16;
  static const _prefiks = 'pbkdf2';

  /// Jalankan di isolate agar UI tidak macet (dimatikan di tes widget yang memakai FakeAsync).
  final bool pakaiIsolate;
  final int iterasi;

  const PasswordHasher({this.pakaiIsolate = true, this.iterasi = iterasiDefault});

  Future<String> hash(String password) {
    final n = iterasi;
    return pakaiIsolate ? Isolate.run(() => hashSinkron(password, iterasi: n)) : Future.value(hashSinkron(password, iterasi: n));
  }

  Future<bool> verifikasi(String password, String tersimpan) {
    return pakaiIsolate
        ? Isolate.run(() => verifikasiSinkron(password, tersimpan))
        : Future.value(verifikasiSinkron(password, tersimpan));
  }

  /// True bila hash dibuat dengan iterasi lebih sedikit dari pengaturan sekarang (perlu di-hash ulang).
  bool perluDiperbarui(String tersimpan) {
    final bagian = tersimpan.split(r'$');
    final iter = bagian.length == 4 ? int.tryParse(bagian[1]) : null;
    return iter == null || iter < iterasi;
  }

  static String hashSinkron(String password, {List<int>? garam, int iterasi = iterasiDefault}) {
    final g = garam ?? _garamAcak();
    final kunci = _pbkdf2(utf8.encode(password), g, iterasi);
    return '$_prefiks\$$iterasi\$${base64Encode(g)}\$${base64Encode(kunci)}';
  }

  static bool verifikasiSinkron(String password, String tersimpan) {
    final bagian = tersimpan.split(r'$');
    if (bagian.length != 4 || bagian[0] != _prefiks) return false;
    final iter = int.tryParse(bagian[1]);
    if (iter == null || iter < 1) return false;
    try {
      final garam = base64Decode(bagian[2]);
      final harapan = base64Decode(bagian[3]);
      final hitung = _pbkdf2(utf8.encode(password), garam, iter);
      return _samaWaktuKonstan(hitung, harapan);
    } on FormatException {
      return false;
    }
  }

  static List<int> _garamAcak() {
    final r = Random.secure();
    return List<int>.generate(_panjangGaram, (_) => r.nextInt(256));
  }

  /// PBKDF2 dengan satu blok keluaran (32 byte = panjang SHA-256).
  static List<int> _pbkdf2(List<int> password, List<int> garam, int iterasi) {
    final hmac = Hmac(sha256, password);
    var u = hmac.convert([...garam, 0, 0, 0, 1]).bytes;
    final t = List<int>.from(u);
    for (var i = 1; i < iterasi; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < t.length; j++) {
        t[j] ^= u[j];
      }
    }
    return t;
  }

  static bool _samaWaktuKonstan(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var beda = 0;
    for (var i = 0; i < a.length; i++) {
      beda |= a[i] ^ b[i];
    }
    return beda == 0;
  }
}
