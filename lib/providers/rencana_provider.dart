import 'package:flutter/foundation.dart';
import '../data/dummy_rencana.dart';
import '../models/rencana_perjalanan.dart';
import '../services/local_storage_service.dart';

class RencanaProvider extends ChangeNotifier {
  final LocalStorageService _storage = LocalStorageService();

  List<RencanaPerjalanan> _daftarRencana = [];
  bool isLoading = true;

  List<RencanaPerjalanan> get daftarRencana =>
      List.unmodifiable(_daftarRencana);

  Future<void> muatData() async {
    final sudahDiinisialisasi = await _storage.rencanaSudahDiinisialisasi();
    if (!sudahDiinisialisasi) {
      _daftarRencana = List.from(dummyRencanaList);
      await _storage.simpanRencana(_daftarRencana);
    } else {
      _daftarRencana = await _storage.muatRencana();
    }
    isLoading = false;
    notifyListeners();
  }

  RencanaPerjalanan? getById(String id) {
    for (final r in _daftarRencana) {
      if (r.id == id) return r;
    }
    return null;
  }

  void tambahRencana(RencanaPerjalanan rencana) {
    _daftarRencana.add(rencana);
    notifyListeners();
    _storage.simpanRencana(_daftarRencana);
  }

  void perbaruiRencana(RencanaPerjalanan rencana) {
    final index = _daftarRencana.indexWhere((r) => r.id == rencana.id);
    if (index == -1) return;
    _daftarRencana[index] = rencana;
    notifyListeners();
    _storage.simpanRencana(_daftarRencana);
  }

  void hapusRencana(String id) {
    _daftarRencana.removeWhere((r) => r.id == id);
    notifyListeners();
    _storage.simpanRencana(_daftarRencana);
  }

  void tambahDestinasiKeRencana(String rencanaId, String destinasiId) {
    final rencana = getById(rencanaId);
    if (rencana == null) return;
    if (rencana.daftarDestinasiId.contains(destinasiId)) return;

    final daftarBaru = [...rencana.daftarDestinasiId, destinasiId];
    perbaruiRencana(rencana.copyWith(daftarDestinasiId: daftarBaru));
  }

  void hapusDestinasiDariRencana(String rencanaId, String destinasiId) {
    final rencana = getById(rencanaId);
    if (rencana == null) return;

    final daftarBaru =
        rencana.daftarDestinasiId.where((id) => id != destinasiId).toList();
    perbaruiRencana(rencana.copyWith(daftarDestinasiId: daftarBaru));
  }
}
