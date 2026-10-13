import '../models/review.dart';
import 'local_storage_service.dart';

/// Penyimpanan ulasan. Implementasi lokal dipakai sekarang; implementasi Firestore
/// (ulasan dibagi antar pengguna) cukup menggantikan kelas ini tanpa mengubah UI.
abstract class ReviewRepository {
  Future<List<Review>> muatSemua();
  Future<void> simpan(Review review);
  Future<void> hapus(String destinasiId, String userId);
}

class LocalReviewRepository implements ReviewRepository {
  final LocalStorageService _storage;

  LocalReviewRepository({LocalStorageService? storage}) : _storage = storage ?? LocalStorageService();

  @override
  Future<List<Review>> muatSemua() => _storage.muatReview();

  @override
  Future<void> simpan(Review review) async {
    final semua = await _storage.muatReview();
    final lain = semua.where((r) => r.id != review.id).toList();
    await _storage.simpanReview([...lain, review]);
  }

  @override
  Future<void> hapus(String destinasiId, String userId) async {
    final id = '${destinasiId}_$userId';
    final semua = await _storage.muatReview();
    await _storage.simpanReview(semua.where((r) => r.id != id).toList());
  }
}
