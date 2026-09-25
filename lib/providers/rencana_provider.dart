import 'package:flutter/foundation.dart';
import '../data/dummy_rencana.dart';
import '../models/rencana_perjalanan.dart';

class RencanaProvider extends ChangeNotifier {
  final List<RencanaPerjalanan> _daftarRencana = List.from(dummyRencanaList);

  List<RencanaPerjalanan> get daftarRencana =>
      List.unmodifiable(_daftarRencana);

  RencanaPerjalanan? getById(String id) {
    for (final r in _daftarRencana) {
      if (r.id == id) return r;
    }
    return null;
  }

  void tambahRencana(RencanaPerjalanan rencana) {
    _daftarRencana.add(rencana);
    notifyListeners();
  }

  void perbaruiRencana(RencanaPerjalanan rencana) {
    final index = _daftarRencana.indexWhere((r) => r.id == rencana.id);
    if (index == -1) return;
    _daftarRencana[index] = rencana;
    notifyListeners();
  }

  void hapusRencana(String id) {
    _daftarRencana.removeWhere((r) => r.id == id);
    notifyListeners();
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
