import 'package:flutter/foundation.dart';

/// Konfigurasi koneksi ke backend chatbot.
///
/// Jalankan dengan, misalnya:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000
/// (HP asli harus memakai IP LAN laptop; emulator Android memakai 10.0.2.2.)
class AppConfig {
  AppConfig._();

  static const _apiBaseUrlDefine = String.fromEnvironment('API_BASE_URL');

  /// Harus sama dengan APP_KEY di backend/.env (kosongkan jika tidak dipakai).
  static const appKey = String.fromEnvironment('APP_KEY');

  static String get apiBaseUrl {
    if (_apiBaseUrlDefine.isNotEmpty) return _apiBaseUrlDefine;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }
}
