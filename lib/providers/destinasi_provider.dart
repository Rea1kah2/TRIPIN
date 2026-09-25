import 'package:flutter/foundation.dart';
import '../data/dummy_destinasi.dart';
import '../data/dummy_kategori.dart';
import '../models/destinasi.dart';
import '../models/kategori.dart';

class DestinasiProvider extends ChangeNotifier {
  final List<Destinasi> _daftarDestinasi = List.from(dummyDestinasiList);
  final List<Kategori> daftarKategori = dummyKategoriList;

  List<Destinasi> get daftarDestinasi => List.unmodifiable(_daftarDestinasi);

  List<Destinasi> get daftarFavorit =>
      _daftarDestinasi.where((d) => d.isFavorit).toList();

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

  List<Destinasi> get destinasiTerdekat {
    final salinan = List<Destinasi>.from(_daftarDestinasi);
    salinan.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return salinan;
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
  }
}