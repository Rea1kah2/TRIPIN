import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_repository.dart';
import '../services/local_storage_service.dart';
import '../services/password_hasher.dart';

export '../services/auth_repository.dart' show maksPercobaanGagal, durasiKunci, normalisasiEmail;

/// Status akun untuk UI. Penyimpanan dan aturan keamanan ada di [AuthRepository].
class AuthProvider with ChangeNotifier {
  final AuthRepository _repo;

  User? currentUser;
  bool isLoading = true;

  /// Tanpa [repository], dipakai [LocalAuthRepository] (parameter lain diteruskan ke sana).
  AuthProvider({
    AuthRepository? repository,
    LocalStorageService? storage,
    PasswordHasher? hasher,
    DateTime Function()? sekarang,
  }) : _repo = repository ?? LocalAuthRepository(storage: storage, hasher: hasher, sekarang: sekarang);

  bool get isLoggedIn => currentUser != null;

  Future<void> muatData() async {
    currentUser = await _repo.pulihkanSesi();
    isLoading = false;
    notifyListeners();
  }

  /// Mengembalikan pesan galat, atau null bila berhasil.
  Future<String?> register(String nama, String email, String password) async {
    final galat = await _repo.daftar(nama, email, password);
    if (galat == null) notifyListeners();
    return galat;
  }

  /// Mengembalikan pesan galat, atau null bila berhasil.
  Future<String?> login(String email, String password) async {
    final hasil = await _repo.masuk(email, password);
    if (hasil.galat != null) return hasil.galat;
    currentUser = hasil.user;
    notifyListeners();
    return null;
  }

  void logout() {
    currentUser = null;
    _repo.keluar();
    notifyListeners();
  }
}
