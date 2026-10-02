import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  final LocalStorageService _storage = LocalStorageService();

  ThemeMode _themeMode = ThemeMode.system;
  double _glassIntensity = 0.5;
  bool _reduceTransparency = false;
  bool isLoading = true;

  ThemeMode get themeMode => _themeMode;

  /// Transparansi kaca 0 (bening) .. 1 (tebal).
  double get glassIntensity => _glassIntensity;

  /// True = semua kaca diganti permukaan solid.
  bool get reduceTransparency => _reduceTransparency;

  /// Apakah tampilan yang sedang aktif gelap (memperhitungkan mode sistem).
  bool isDark(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  Future<void> muatData() async {
    final tersimpan = await _storage.muatThemeMode();
    _themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == tersimpan,
      orElse: () => ThemeMode.system,
    );
    _glassIntensity = ((await _storage.muatGlassIntensity()) ?? 0.5).clamp(0.0, 1.0);
    _reduceTransparency = await _storage.muatReduceTransparency();
    isLoading = false;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    _storage.simpanThemeMode(mode.name);
  }

  void setGlassIntensity(double nilai, {bool simpan = true}) {
    final v = nilai.clamp(0.0, 1.0);
    if (v == _glassIntensity) return;
    _glassIntensity = v;
    notifyListeners();
    if (simpan) _storage.simpanGlassIntensity(v);
  }

  /// Menyimpan nilai terakhir slider (dipanggil saat slider dilepas).
  void simpanGlassIntensity() => _storage.simpanGlassIntensity(_glassIntensity);

  void setReduceTransparency(bool nilai) {
    if (nilai == _reduceTransparency) return;
    _reduceTransparency = nilai;
    notifyListeners();
    _storage.simpanReduceTransparency(nilai);
  }

  /// Membalik tampilan yang sedang terlihat: terang <-> gelap.
  void toggle(BuildContext context) {
    setThemeMode(isDark(context) ? ThemeMode.light : ThemeMode.dark);
  }
}
