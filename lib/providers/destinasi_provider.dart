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

  List<Destinasi> get daftarDestinasi => List.unmodifiable(_daftarDestinasi);

  List<Destinasi> get daftarFavorit =>
      _daftarDestinasi.where((d) => d.isFavorit).toList();

  Future<void> muatData() async {
    final favoritIds = await _storage.muatFavoritIds();
    _daftarDestinasi = dummyDestinasiList
        .map((d) => d.copyWith(isFavorit: favoritIds.contains(d.id)))
        .toList();
    isLoading = false;
    notifyListeners();
  }

  Destinasi? getById(String id) {
    for (final d in _daftarDestinasi) {
      if (d.id == id) return d;
    }
    return null;
  }

  List<Destinasi> cari({String? query, String? kategoriId}) {
    return _daftarDestinasi.where((d) {
      final cocokQuery = query == null ||
          query.isEmpty ||
          d.name.toLowerCase().contains(query.toLowerCase());
      final cocokKategori = kategoriId == null || d.kategoriId == kategoriId;
      return cocokQuery && cocokKategori;
    }).toList();
  }

  List<Destinasi> get destinasiTeratas {
    final salinan = List<Destinasi>.from(_daftarDestinasi);
    salinan.sort((a, b) => b.rating.compareTo(a.rating));
    return salinan;
  }

  void toggleFavorit(String id) {
    final index = _daftarDestinasi.indexWhere((d) => d.id == id);
    if (index == -1) return;
    final lama = _daftarDestinasi[index];
    _daftarDestinasi[index] = lama.copyWith(isFavorit: !lama.isFavorit);
    notifyListeners();

    final favoritIds =
        _daftarDestinasi.where((d) => d.isFavorit).map((d) => d.id).toSet();
    _storage.simpanFavoritIds(favoritIds);
  }
}
