
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

  // Data riwayat kunjungan.
  Map<String, DateTime> _riwayatKunjungan = {};
  String? _riwayatUserId;

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

  // Memuat data destinasi dan favorit.
  Future<void> muatData() async {
    final favoritIds = await _storage.muatFavoritIds();

    _daftarDestinasi = dummyDestinasiList
        .map(
          (d) => d.copyWith(
        isFavorit: favoritIds.contains(d.id),
      ),
    )
        .toList();

    isLoading = false;
    notifyListeners();
  }

  // Memuat riwayat berdasarkan akun pengguna.
  Future<void> muatRiwayatKunjungan(String userId) async {
    _riwayatUserId = userId;

    _riwayatKunjungan =
    await _storage.muatRiwayatKunjungan(userId);

    notifyListeners();
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

    notifyListeners();
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

    notifyListeners();
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
    return _daftarDestinasi.where((d) {
      final cocokQuery = query == null ||
          query.isEmpty ||
          d.name.toLowerCase().contains(query.toLowerCase());

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

  // Fitur favorit lama tetap dipertahankan.
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

    _storage.simpanFavoritIds(favoritIds);
  }
}
