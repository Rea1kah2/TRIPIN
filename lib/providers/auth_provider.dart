import 'package:flutter/foundation.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final List<User> _daftarUser = [];
  User? currentUser;

    bool get isLoggedIn => currentUser != null;

    String? register(String nama, String email, String password){
      final sudahAda = _daftarUser.any((u) => u.email == email);
      if(sudahAda){
        return 'Email sudah terdaftar';      
      }

      final userBaru = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nama: nama,
        email: email,
        password: password,
      );

      _daftarUser.add(userBaru);
      notifyListeners();
      return null;
    }

    String? login(String email, String password){
      User? user;
      for(final u in _daftarUser){
        if(u.email == email && u.password == password){
          user = u;
          break;
        }
      }

      if(user == null){
        return 'Email atau password salah';
      }

      currentUser = user;
      notifyListeners();
      return null;
    }

    void logout(){
      currentUser = null;
      notifyListeners();
    }
}