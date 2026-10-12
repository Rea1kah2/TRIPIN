/// Konfigurasi koneksi ke backend chatbot.
///
/// Cara termudah (HP asli lewat kabel USB atau emulator): jalankan `./scripts/run_android.sh`.
/// Skrip itu memasang `adb reverse tcp:3000 tcp:3000` sehingga `localhost:3000` di perangkat
/// menunjuk ke backend di laptop, tanpa peduli IP Wi-Fi.
///
/// Tanpa USB (satu Wi-Fi), pakai IP LAN laptop:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000
class AppConfig {
  AppConfig._();

  static const _apiBaseUrlDefine = String.fromEnvironment('API_BASE_URL');

  /// Harus sama dengan APP_KEY di backend/.env (kosongkan jika tidak dipakai).
  static const appKey = String.fromEnvironment('APP_KEY');

  static String get apiBaseUrl {
    if (_apiBaseUrlDefine.isNotEmpty) return _apiBaseUrlDefine;
    // Default cloud backend di Render (bisa dioverride dengan --dart-define=API_BASE_URL=http://localhost:3000 saat dev lokal)
    return 'https://tripin-backend.onrender.com';
  }
}
