import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  final LocalStorageService _storage = LocalStorageService();

  ThemeMode _themeMode = ThemeMode.system;
  bool isLoading = true;

  ThemeMode get themeMode => _themeMode;

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
    isLoading = false;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    _storage.simpanThemeMode(mode.name);
  }

  /// Membalik tampilan yang sedang terlihat: terang <-> gelap.
  void toggle(BuildContext context) {
    setThemeMode(isDark(context) ? ThemeMode.light : ThemeMode.dark);
  }
}
