import 'package:flutter/foundation.dart';
import '../models/destinasi.dart';
import '../models/review.dart';
import '../services/review_repository.dart';

/// Bobot nilai dasar destinasi saat dicampur dengan ulasan nyata (setara 10 suara),
/// supaya satu ulasan tidak langsung menjungkirbalikkan nilai.
const bobotRatingDasar = 10;

class ReviewProvider extends ChangeNotifier {
  final ReviewRepository _repo;
  List<Review> _semua = [];
  bool isLoading = true;

  ReviewProvider({ReviewRepository? repo}) : _repo = repo ?? LocalReviewRepository();

  Future<void> muatData() async {
    _semua = await _repo.muatSemua();
    isLoading = false;
    notifyListeners();
  }

  /// Ulasan sebuah destinasi: milik [userId] di paling atas, sisanya terbaru dulu.
  List<Review> untuk(String destinasiId, {String? userId}) {
    final daftar = _semua.where((r) => r.destinasiId == destinasiId).toList()
      ..sort((a, b) {
        if (userId != null) {
          final am = a.userId == userId, bm = b.userId == userId;
          if (am != bm) return am ? -1 : 1;
        }
        return b.diubah.compareTo(a.diubah);
      });
    return daftar;
  }

  Review? milik(String destinasiId, String? userId) {
    if (userId == null) return null;
    for (final r in _semua) {
      if (r.destinasiId == destinasiId && r.userId == userId) return r;
    }
    return null;
  }

  RingkasanUlasan ringkasan(String destinasiId) =>
      RingkasanUlasan.dari(_semua.where((r) => r.destinasiId == destinasiId));

  /// Rating untuk kartu/detail: nilai dasar dicampur ulasan nyata.
  double ratingTampil(Destinasi d) {
    final r = ringkasan(d.id);
    if (r.jumlah == 0) return d.rating;
    final total = r.rataRata * r.jumlah;
    return (d.rating * bobotRatingDasar + total) / (bobotRatingDasar + r.jumlah);
  }

  /// Menyimpan (baru atau mengubah). Mengembalikan pesan galat, atau null bila berhasil.
  Future<String?> simpan({
    required String destinasiId,
    required String userId,
    required String namaPenulis,
    required int rating,
    String komentar = '',
  }) async {
    if (rating < 1 || rating > 5) return 'Pilih jumlah bintang dulu ya.';
    final teks = komentar.trim();
    if (teks.length > Review.maksKomentar) return 'Komentar maksimal ${Review.maksKomentar} karakter.';

    final sekarang = DateTime.now();
    final lama = milik(destinasiId, userId);
    final baru = lama == null
        ? Review(
            destinasiId: destinasiId,
            userId: userId,
            namaPenulis: namaPenulis,
            rating: rating,
            komentar: teks,
            dibuat: sekarang,
            diubah: sekarang,
          )
        : lama.copyWith(rating: rating, komentar: teks, diubah: sekarang, namaPenulis: namaPenulis);

    final sebelum = _semua;
    _semua = [..._semua.where((r) => r.id != baru.id), baru];
    notifyListeners();
    try {
      await _repo.simpan(baru);
      return null;
    } catch (e) {
      debugPrint('ReviewProvider.simpan gagal: $e');
      _semua = sebelum; // batalkan perubahan tampilan
      notifyListeners();
      return 'Ulasan belum tersimpan. Coba lagi ya.';
    }
  }

  Future<String?> hapus(String destinasiId, String userId) async {
    final sebelum = _semua;
    _semua = _semua.where((r) => !(r.destinasiId == destinasiId && r.userId == userId)).toList();
    notifyListeners();
    try {
      await _repo.hapus(destinasiId, userId);
      return null;
    } catch (e) {
      debugPrint('ReviewProvider.hapus gagal: $e');
      _semua = sebelum;
      notifyListeners();
      return 'Ulasan belum terhapus. Coba lagi ya.';
    }
  }
}
