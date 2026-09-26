import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/local_storage_service.dart';

class AuthProvider with ChangeNotifier {
  final LocalStorageService _storage = LocalStorageService();

  List<User> _daftarUser = [];
  User? currentUser;
  bool isLoading = true;

  bool get isLoggedIn => currentUser != null;

  Future<void> muatData() async {
    _daftarUser = await _storage.muatUser();
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

  String? register(String nama, String email, String password) {
    final sudahAda = _daftarUser.any((u) => u.email == email);
    if (sudahAda) {
      return 'Email sudah terdaftar';
    }

    final userBaru = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nama: nama,
      email: email,
      password: password,
    );

    _daftarUser.add(userBaru);
    _storage.simpanUser(_daftarUser);
    notifyListeners();
    return null;
  }

  String? login(String email, String password) {
    User? user;
    for (final u in _daftarUser) {
      if (u.email == email && u.password == password) {
        user = u;
        break;
      }
    }

    if (user == null) {
      return 'Email atau password salah';
    }

    currentUser = user;
    _storage.simpanSessionUserId(user.id);
    notifyListeners();
    return null;
  }

  void logout() {
    currentUser = null;
    _storage.simpanSessionUserId(null);
    notifyListeners();
  }
}
