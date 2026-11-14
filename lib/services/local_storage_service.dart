
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../models/checklist_item.dart';
import '../models/review.dart';
import '../models/rencana_perjalanan.dart';
import '../models/user.dart';

class LocalStorageService {
  static const _keyUsers = 'tripin_users';
  static const _keySessionUserId = 'tripin_session_user_id';
  static const _keyFavoritIds = 'tripin_favorit_ids';
  static const _keyRencana = 'tripin_rencana';
  static const _keyRencanaInitialized = 'tripin_rencana_initialized';
  static const _keyThemeMode = 'tripin_theme_mode';
  static const _keyReview = 'tripin_reviews';
  static const _keyGlassIntensity = 'tripin_glass_intensity';
  static const _keyReduceTransparency = 'tripin_reduce_transparency';

  static String _keyChat(String userId) => 'tripin_chat_$userId';

  static String _keyFavorit(String? userId) =>
      (userId == null || userId.isEmpty)
          ? _keyFavoritIds
          : 'tripin_favorit_ids_$userId';

  static String _keyRencanaUser(String? userId) =>
      (userId == null || userId.isEmpty)
          ? _keyRencana
          : 'tripin_rencana_$userId';

  static String _keyRencanaInitUser(String? userId) =>
      (userId == null || userId.isEmpty)
          ? _keyRencanaInitialized
          : 'tripin_rencana_init_$userId';

  static String _keyChecklist(String? userId) =>
      'tripin_checklist_${(userId == null || userId.isEmpty) ? "guest" : userId}';

  static String _keyChecklistInit(String? userId) =>
      'tripin_checklist_init_${(userId == null || userId.isEmpty) ? "guest" : userId}';

  // Key penyimpanan riwayat kunjungan per pengguna.
  static String _keyRiwayatKunjungan(String userId) =>
      'tripin_riwayat_kunjungan_$userId';

  // =========================
  // CHAT
  // =========================

  Future<List<ChatMessage>> muatChat(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyChat(userId));

    if (raw == null) return [];

    try {
      return (jsonDecode(raw) as List)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> simpanChat(String userId, List<ChatMessage> pesan) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _keyChat(userId),
      jsonEncode(pesan.map((m) => m.toJson()).toList()),
    );
  }

  // =========================
  // TEMA APLIKASI
  // =========================

  Future<String?> muatThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyThemeMode);
  }

  Future<void> simpanThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode);
  }

  // =========================
  // REVIEW
  // =========================

  Future<List<Review>> muatReview() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyReview);

    if (raw == null) return [];

    try {
      return [
        for (final e in jsonDecode(raw) as List)
          if (Review.tryFromJson(e) case final r?) r,
      ];
    } catch (_) {
      return [];
    }
  }

  Future<void> simpanReview(List<Review> review) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _keyReview,
      jsonEncode(review.map((r) => r.toJson()).toList()),
    );
  }

  // =========================
  // GLASS EFFECT
  // =========================

  Future<double?> muatGlassIntensity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyGlassIntensity);
  }

  Future<void> simpanGlassIntensity(double nilai) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyGlassIntensity, nilai);
  }

  Future<bool> muatReduceTransparency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyReduceTransparency) ?? false;
  }

  Future<void> simpanReduceTransparency(bool nilai) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReduceTransparency, nilai);
  }

  // =========================
  // USER
  // =========================

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

  // =========================
  // FAVORIT
  // =========================

  Future<Set<String>> muatFavoritIds({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();

    return (prefs.getStringList(_keyFavorit(userId)) ?? []).toSet();
  }

  Future<void> simpanFavoritIds(Set<String> ids, {String? userId}) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(_keyFavorit(userId), ids.toList());
  }

  // =========================
  // RENCANA PERJALANAN
  // =========================

  Future<bool> rencanaSudahDiinisialisasi({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_keyRencanaInitUser(userId)) ?? false;
  }

  Future<List<RencanaPerjalanan>> muatRencana({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyRencanaUser(userId));

    if (raw == null) return [];

    try {
      return (jsonDecode(raw) as List)
          .map((e) => RencanaPerjalanan.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> simpanRencana(
    List<RencanaPerjalanan> rencana, {
    String? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _keyRencanaUser(userId),
      jsonEncode(rencana.map((r) => r.toJson()).toList()),
    );

    await prefs.setBool(_keyRencanaInitUser(userId), true);
  }

  // =========================
  // CHECKLIST PERSIAPAN
  // =========================

  Future<List<ChecklistItem>> muatChecklist({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final sudahInit = prefs.getBool(_keyChecklistInit(userId)) ?? false;

    if (!sudahInit) {
      final bawaan = ChecklistItem.bawaanAwal();
      await simpanChecklist(bawaan, userId: userId);
      return bawaan;
    }

    final raw = prefs.getString(_keyChecklist(userId));
    if (raw == null) return [];

    try {
      return [
        for (final item in jsonDecode(raw) as List)
          if (ChecklistItem.tryFromJson(item) case final parsed?) parsed,
      ];
    } catch (_) {
      return [];
    }
  }

  Future<void> simpanChecklist(
    List<ChecklistItem> items, {
    String? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyChecklist(userId),
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
    await prefs.setBool(_keyChecklistInit(userId), true);
  }

  // =========================
  // RIWAYAT DESTINASI
  // =========================

  // Memuat riwayat kunjungan berdasarkan ID pengguna.
  Future<Map<String, DateTime>> muatRiwayatKunjungan(
      String userId) async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(_keyRiwayatKunjungan(userId));

    if (raw == null) return {};

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;

      return data.map(
            (id, tanggal) => MapEntry(
          id,
          DateTime.parse(tanggal as String),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  // Menyimpan riwayat kunjungan berdasarkan ID pengguna.
  Future<void> simpanRiwayatKunjungan(
      String userId,
      Map<String, DateTime> riwayat,
      ) async {
    final prefs = await SharedPreferences.getInstance();

    final data = riwayat.map(
          (id, tanggal) => MapEntry(
        id,
        tanggal.toIso8601String(),
      ),
    );

    await prefs.setString(
      _keyRiwayatKunjungan(userId),
      jsonEncode(data),
    );
  }
}
