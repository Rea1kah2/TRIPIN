import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/local_storage_service.dart';
import '../services/password_hasher.dart';

/// Batas percobaan masuk yang gagal sebelum dikunci sementara.
const maksPercobaanGagal = 5;
const durasiKunci = Duration(seconds: 30);

class AuthProvider with ChangeNotifier {
  final LocalStorageService _storage;
  final PasswordHasher _hasher;
  final DateTime Function() _sekarang;

  List<User> _daftarUser = [];
  User? currentUser;
  bool isLoading = true;

  // Percobaan gagal per email (di memori; reset saat app ditutup).
  final Map<String, int> _gagal = {};
  final Map<String, DateTime> _kunciSampai = {};

  AuthProvider({
    LocalStorageService? storage,
    PasswordHasher? hasher,
    DateTime Function()? sekarang,
  })  : _storage = storage ?? LocalStorageService(),
        _hasher = hasher ?? const PasswordHasher(),
        _sekarang = sekarang ?? DateTime.now;

  bool get isLoggedIn => currentUser != null;

  static String normalisasiEmail(String email) => email.trim().toLowerCase();

  Future<void> muatData() async {
    _daftarUser = await _storage.muatUser();
    await _migrasiPasswordLama();

    final sessionId = await _storage.muatSessionUserId();
    if (sessionId != null) {
      for (final u in _daftarUser) {
        if (u.id == sessionId) {
          currentUser = u;
          break;
        }
      }
    }
    isLoading = false;
    notifyListeners();
  }

  /// Akun buatan versi lama menyimpan password polos: hash sekali, simpan ulang,
  /// sehingga tidak ada plaintext tersisa di penyimpanan.
  Future<void> _migrasiPasswordLama() async {
    if (!_daftarUser.any((u) => u.passwordLama != null)) return;
    final baru = <User>[];
    for (final u in _daftarUser) {
      final lama = u.passwordLama;
      baru.add(lama == null ? u : u.copyWith(passwordHash: await _hasher.hash(lama), hapusPasswordLama: true));
    }
    _daftarUser = baru;
    await _storage.simpanUser(_daftarUser);
  }

  /// Mengembalikan pesan galat, atau null bila berhasil.
  Future<String?> register(String nama, String email, String password) async {
    final emailNorm = normalisasiEmail(email);
    if (_daftarUser.any((u) => normalisasiEmail(u.email) == emailNorm)) {
      return 'Email sudah terdaftar';
    }

    final userBaru = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nama: nama.trim(),
      email: emailNorm,
      passwordHash: await _hasher.hash(password),
    );

    _daftarUser = [..._daftarUser, userBaru];
    await _storage.simpanUser(_daftarUser);
    notifyListeners();
    return null;
  }

  Future<String?> login(String email, String password) async {
    final emailNorm = normalisasiEmail(email);

    final kunci = _kunciSampai[emailNorm];
    if (kunci != null) {
      final sisa = kunci.difference(_sekarang());
      if (sisa > Duration.zero) {
        return 'Terlalu banyak percobaan. Coba lagi dalam ${sisa.inSeconds + 1} detik.';
      }
      _kunciSampai.remove(emailNorm);
      _gagal.remove(emailNorm);
    }

    User? user;
    for (final u in _daftarUser) {
      if (normalisasiEmail(u.email) == emailNorm) {
        user = u;
        break;
      }
    }

    final cocok = user != null && await _hasher.verifikasi(password, user.passwordHash);
    if (!cocok) {
      final n = (_gagal[emailNorm] ?? 0) + 1;
      _gagal[emailNorm] = n;
      if (n >= maksPercobaanGagal) {
        _kunciSampai[emailNorm] = _sekarang().add(durasiKunci);
        return 'Terlalu banyak percobaan. Coba lagi dalam ${durasiKunci.inSeconds} detik.';
      }
      return 'Email atau password salah';
    }

    _gagal.remove(emailNorm);

    // Naikkan kekuatan hash otomatis bila parameter iterasi sudah diperbarui.
    if (_hasher.perluDiperbarui(user.passwordHash)) {
      final diperbarui = user.copyWith(passwordHash: await _hasher.hash(password));
      _daftarUser = [for (final u in _daftarUser) u.id == user.id ? diperbarui : u];
      await _storage.simpanUser(_daftarUser);
      user = diperbarui;
    }

    currentUser = user;
    await _storage.simpanSessionUserId(user.id);
    notifyListeners();
    return null;
  }

  void logout() {
    currentUser = null;
    _storage.simpanSessionUserId(null);
    notifyListeners();
  }
}
