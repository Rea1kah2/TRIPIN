import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../models/rencana_perjalanan.dart';
import '../models/user.dart';

class LocalStorageService {
  static const _keyUsers = 'tripin_users';
  static const _keySessionUserId = 'tripin_session_user_id';
  static const _keyFavoritIds = 'tripin_favorit_ids';
  static const _keyRencana = 'tripin_rencana';
  static const _keyRencanaInitialized = 'tripin_rencana_initialized';
  static const _keyThemeMode = 'tripin_theme_mode';

  static String _keyChat(String userId) => 'tripin_chat_$userId';

  Future<List<ChatMessage>> muatChat(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyChat(userId));
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return []; // riwayat rusak: mulai baru, jangan crash
    }
  }

  Future<void> simpanChat(String userId, List<ChatMessage> pesan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyChat(userId),
      jsonEncode(pesan.map((m) => m.toJson()).toList()),
    );
  }

  Future<String?> muatThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyThemeMode);
  }

  Future<void> simpanThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode);
  }

  Future<List<User>> muatUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUsers);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => User.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> simpanUser(List<User> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyUsers,
      jsonEncode(users.map((u) => u.toJson()).toList()),
    );
  }

  Future<String?> muatSessionUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySessionUserId);
  }

  Future<void> simpanSessionUserId(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId == null) {
      await prefs.remove(_keySessionUserId);
    } else {
      await prefs.setString(_keySessionUserId, userId);
    }
  }

  Future<Set<String>> muatFavoritIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_keyFavoritIds) ?? []).toSet();
  }

  Future<void> simpanFavoritIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyFavoritIds, ids.toList());
  }

  Future<bool> rencanaSudahDiinisialisasi() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRencanaInitialized) ?? false;
  }

  Future<List<RencanaPerjalanan>> muatRencana() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyRencana);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => RencanaPerjalanan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> simpanRencana(List<RencanaPerjalanan> rencana) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyRencana,
      jsonEncode(rencana.map((r) => r.toJson()).toList()),
    );
    await prefs.setBool(_keyRencanaInitialized, true);
  }
}
