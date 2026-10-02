import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/destinasi.dart';
import '../services/location_service.dart';
import '../utils/geo.dart';

/// Posisi pengguna + izin lokasi. Aliran posisi hanya hidup saat layar Peta terlihat
/// (hemat baterai); layar lain memakai posisi terakhir yang diketahui.
class LokasiProvider extends ChangeNotifier {
  final LocationService _service;

  IzinLokasi? izin; // null = belum dicek
  Posisi? posisi;
  bool sedangMencari = false;
  StreamSubscription<Posisi>? _sub;
  bool _disposed = false;

  LokasiProvider({LocationService? service}) : _service = service ?? GeolocatorLocationService();

  bool get diizinkan => izin == IzinLokasi.diizinkan;
  bool get adaPosisi => posisi != null;

  /// Dipanggil saat layar dibuka: cek izin tanpa dialog; bila sudah diizinkan, ambil posisi sekali.
  Future<void> muatAwal() async {
    izin = await _service.cekIzin();
    _beri();
    if (diizinkan && posisi == null) await _ambilSekali();
  }

  /// Dipanggil dari tombol "Aktifkan lokasi": minta izin lalu ambil posisi.
  Future<void> aktifkan() async {
    izin = await _service.mintaIzin();
    _beri();
    if (diizinkan) await _ambilSekali();
  }

  Future<void> _ambilSekali() async {
    sedangMencari = true;
    _beri();
    final p = await _service.posisiSekarang();
    if (p != null) posisi = p;
    sedangMencari = false;
    _beri();
  }

  Future<void> segarkan() => diizinkan ? _ambilSekali() : aktifkan();

  /// Mulai melacak posisi (dipanggil saat tab Peta terlihat).
  void mulaiLacak() {
    if (!diizinkan || _sub != null) return;
    _sub = _service.aliran().listen(
      (p) {
        posisi = p;
        _beri();
      },
      onError: (Object e) => debugPrint('LokasiProvider aliran: $e'),
    );
  }

  void berhentiLacak() {
    _sub?.cancel();
    _sub = null;
  }

  Future<void> bukaPengaturan() =>
      izin == IzinLokasi.layananMati ? _service.bukaPengaturanLokasi() : _service.bukaPengaturanAplikasi();

  /// Jarak ke destinasi dalam km, atau null bila posisi belum diketahui.
  double? jarakKe(Destinasi d) {
    final p = posisi;
    return p == null ? null : jarakKm(p.lat, p.lng, d.lat, d.lng);
  }

  /// Daftar diurutkan dari yang terdekat; tanpa posisi, urutan asli dikembalikan.
  List<Destinasi> urutTerdekat(Iterable<Destinasi> daftar) {
    final salinan = daftar.toList();
    if (posisi == null) return salinan;
    salinan.sort((a, b) => jarakKe(a)!.compareTo(jarakKe(b)!));
    return salinan;
  }

  void _beri() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    super.dispose();
  }
}
