import 'package:flutter/foundation.dart';
import '../data/dummy_rencana.dart';
import '../models/rencana_perjalanan.dart';
import '../services/local_storage_service.dart';

class RencanaProvider extends ChangeNotifier {
  final LocalStorageService _storage = LocalStorageService();

  List<RencanaPerjalanan> _daftarRencana = [];
  bool isLoading = true;

  String? _userId;
  bool _sudahDimuat = false;
  bool _sedangMemuat = false;
  int _generasi = 0;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  List<RencanaPerjalanan> get daftarRencana =>
      List.unmodifiable(_daftarRencana);

  /// Sinkronisasi akun aktif agar rencana perjalanan terisolasi per pengguna.
  Future<void> gantiUser(String? userId) async {
    if (userId == _userId && (_sudahDimuat || _sedangMemuat)) return;
    _userId = userId;
    await muatData();
  }

  Future<void> muatData() async {
    final targetUserId = _userId;
    final generasi = ++_generasi;
    _sedangMemuat = true;

    final sudahDiinisialisasi =
        await _storage.rencanaSudahDiinisialisasi(userId: targetUserId);
    if (_disposed || generasi != _generasi) return;

    if (!sudahDiinisialisasi) {
      _daftarRencana = List.from(dummyRencanaList);
      await _storage.simpanRencana(_daftarRencana, userId: targetUserId);
    } else {
      _daftarRencana = await _storage.muatRencana(userId: targetUserId);
    }
    if (_disposed || generasi != _generasi) return;

    _sudahDimuat = true;
    _sedangMemuat = false;
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
    _storage.simpanRencana(_daftarRencana, userId: _userId);
  }

  void perbaruiRencana(RencanaPerjalanan rencana) {
    final index = _daftarRencana.indexWhere((r) => r.id == rencana.id);
    if (index == -1) return;
    _daftarRencana[index] = rencana;
    notifyListeners();
    _storage.simpanRencana(_daftarRencana, userId: _userId);
  }

  void hapusRencana(String id) {
    _daftarRencana.removeWhere((r) => r.id == id);
    notifyListeners();
    _storage.simpanRencana(_daftarRencana, userId: _userId);
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

  /// Memindahkan destinasi pada urutan kunjungan. [indeksBaru] memakai konvensi
  /// ReorderableListView (indeks sebelum item lama dicabut).
  void urutUlangDestinasi(String rencanaId, int indeksLama, int indeksBaru) {
    final rencana = getById(rencanaId);
    if (rencana == null) return;
    final daftar = [...rencana.daftarDestinasiId];
    if (indeksLama < 0 || indeksLama >= daftar.length) return;
    if (indeksBaru > indeksLama) indeksBaru -= 1;
    indeksBaru = indeksBaru.clamp(0, daftar.length - 1);
    if (indeksBaru == indeksLama) return;
    daftar.insert(indeksBaru, daftar.removeAt(indeksLama));
    perbaruiRencana(rencana.copyWith(daftarDestinasiId: daftar));
  }
}
