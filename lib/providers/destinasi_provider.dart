
import 'package:flutter/foundation.dart';
import '../data/dummy_destinasi.dart';
import '../data/dummy_kategori.dart';
import '../models/destinasi.dart';
import '../models/kategori.dart';
import '../services/local_storage_service.dart';

class DestinasiProvider extends ChangeNotifier {
  final LocalStorageService _storage = LocalStorageService();

  List<Destinasi> _daftarDestinasi = List.from(dummyDestinasiList);
  final List<Kategori> daftarKategori = dummyKategoriList;
  bool isLoading = true;

  String? _userId;
  bool _sudahDimuat = false;
  bool _sedangMemuat = false;
  int _generasi = 0;
  bool _disposed = false;

  // Data riwayat kunjungan.
  Map<String, DateTime> _riwayatKunjungan = {};
  String? _riwayatUserId;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  List<Destinasi> get daftarDestinasi =>
      List.unmodifiable(_daftarDestinasi);

  List<Destinasi> get daftarFavorit =>
      _daftarDestinasi.where((d) => d.isFavorit).toList();

  // Mengambil daftar destinasi yang sudah dikunjungi.
  List<Destinasi> get daftarRiwayatKunjungan {
    final daftarId = _riwayatKunjungan.entries.toList();

    // Urutkan berdasarkan tanggal kunjungan terbaru.
    daftarId.sort(
      (a, b) => b.value.compareTo(a.value),
    );

    return daftarId
        .map((entry) => getById(entry.key))
        .whereType<Destinasi>()
        .toList();
  }

  // Mengambil tanggal kunjungan destinasi.
  DateTime? tanggalKunjungan(String destinasiId) {
    return _riwayatKunjungan[destinasiId];
  }

  // Memeriksa apakah destinasi sudah pernah dikunjungi.
  bool sudahDikunjungi(String destinasiId) {
    return _riwayatKunjungan.containsKey(destinasiId);
  }

  /// Sinkronisasi akun aktif agar favorit & riwayat terisolasi per pengguna.
  Future<void> gantiUser(String? userId) async {
    if (userId == _userId && (_sudahDimuat || _sedangMemuat)) return;
    _userId = userId;
    await muatData();
  }

  // Memuat data destinasi, favorit, dan riwayat kunjungan untuk akun aktif.
  Future<void> muatData() async {
    final targetUserId = _userId;
    final generasi = ++_generasi;
    _sedangMemuat = true;

    final favoritIds = await _storage.muatFavoritIds(userId: targetUserId);
    final riwayat = (targetUserId == null || targetUserId.isEmpty)
        ? <String, DateTime>{}
        : await _storage.muatRiwayatKunjungan(targetUserId);

    if (_disposed || generasi != _generasi) return;

    _daftarDestinasi = dummyDestinasiList
        .map(
          (d) => d.copyWith(
            isFavorit: favoritIds.contains(d.id),
          ),
        )
        .toList();
    _riwayatUserId = targetUserId;
    _riwayatKunjungan = riwayat;

    _sudahDimuat = true;
    _sedangMemuat = false;
    isLoading = false;
    notifyListeners();
  }

  // Memuat riwayat berdasarkan akun pengguna.
  Future<void> muatRiwayatKunjungan(String userId) async {
    _riwayatUserId = userId;

    _riwayatKunjungan = await _storage.muatRiwayatKunjungan(userId);

    if (!_disposed) notifyListeners();
  }

  // Memastikan riwayat yang digunakan sesuai akun aktif.
  Future<void> _pastikanRiwayatDimuat(String userId) async {
    if (_riwayatUserId != userId) {
      await muatRiwayatKunjungan(userId);
    }
  }

  // Menandai destinasi sebagai sudah dikunjungi.
  Future<void> tandaiSudahDikunjungi(
    String userId,
    String destinasiId,
  ) async {
    if (getById(destinasiId) == null) return;

    await _pastikanRiwayatDimuat(userId);

    _riwayatKunjungan[destinasiId] = DateTime.now();

    await _storage.simpanRiwayatKunjungan(
      userId,
      _riwayatKunjungan,
    );

    if (!_disposed) notifyListeners();
  }

  // Membatalkan status sudah dikunjungi.
  Future<void> batalkanKunjungan(
    String userId,
    String destinasiId,
  ) async {
    await _pastikanRiwayatDimuat(userId);

    if (!_riwayatKunjungan.containsKey(destinasiId)) return;

    _riwayatKunjungan.remove(destinasiId);

    await _storage.simpanRiwayatKunjungan(
      userId,
      _riwayatKunjungan,
    );

    if (!_disposed) notifyListeners();
  }

  /// Menandai atau membatalkan status kunjungan dan mengembalikan status akhir.
  Future<bool> toggleKunjungan(String userId, String destinasiId) async {
    await _pastikanRiwayatDimuat(userId);
    if (sudahDikunjungi(destinasiId)) {
      await batalkanKunjungan(userId, destinasiId);
      return false;
    } else {
      await tandaiSudahDikunjungi(userId, destinasiId);
      return true;
    }
  }

  Destinasi? getById(String id) {
    for (final d in _daftarDestinasi) {
      if (d.id == id) return d;
    }
    return null;
  }

  List<Destinasi> cari({
    String? query,
    String? kategoriId,
  }) {
    final q = query?.trim().toLowerCase() ?? '';
    return _daftarDestinasi.where((d) {
      final cocokQuery = q.isEmpty ||
          d.name.toLowerCase().contains(q) ||
          d.location.toLowerCase().contains(q);

      final cocokKategori =
          kategoriId == null || d.kategoriId == kategoriId;

      return cocokQuery && cocokKategori;
    }).toList();
  }

  List<Destinasi> get destinasiTeratas {
    final salinan = List<Destinasi>.from(_daftarDestinasi);

    salinan.sort(
      (a, b) => b.rating.compareTo(a.rating),
    );

    return salinan;
  }

  // Toggle status favorit dan simpan sesuai user aktif.
  void toggleFavorit(String id) {
    final index = _daftarDestinasi.indexWhere((d) => d.id == id);

    if (index == -1) return;

    final lama = _daftarDestinasi[index];

    _daftarDestinasi[index] = lama.copyWith(
      isFavorit: !lama.isFavorit,
    );

    notifyListeners();

    final favoritIds = _daftarDestinasi
        .where((d) => d.isFavorit)
        .map((d) => d.id)
        .toSet();

    _storage.simpanFavoritIds(favoritIds, userId: _userId);
  }
}
