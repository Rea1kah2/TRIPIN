import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

enum IzinLokasi { diizinkan, ditolak, ditolakPermanen, layananMati }

class Posisi {
  final double lat;
  final double lng;
  final double akurasiMeter;

  const Posisi(this.lat, this.lng, {this.akurasiMeter = 0});
}

/// Kontrak lokasi; dipisah supaya provider dan layar peta bisa diuji dengan versi palsu.
abstract class LocationService {
  /// Status saat ini tanpa memunculkan dialog izin.
  Future<IzinLokasi> cekIzin();

  /// Meminta izin lewat dialog sistem (bila masih bisa diminta).
  Future<IzinLokasi> mintaIzin();

  Future<Posisi?> posisiSekarang();

  /// Aliran posisi (hemat baterai: akurasi sedang, minimal berpindah 20 m).
  Stream<Posisi> aliran();

  Future<void> bukaPengaturanAplikasi();
  Future<void> bukaPengaturanLokasi();
}

class GeolocatorLocationService implements LocationService {
  IzinLokasi _petakan(LocationPermission p) => switch (p) {
        LocationPermission.always || LocationPermission.whileInUse => IzinLokasi.diizinkan,
        LocationPermission.deniedForever => IzinLokasi.ditolakPermanen,
        _ => IzinLokasi.ditolak,
      };

  @override
  Future<IzinLokasi> cekIzin() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return IzinLokasi.layananMati;
      return _petakan(await Geolocator.checkPermission());
    } catch (e) {
      debugPrint('LocationService.cekIzin: $e');
      return IzinLokasi.layananMati;
    }
  }

  @override
  Future<IzinLokasi> mintaIzin() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return IzinLokasi.layananMati;
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      return _petakan(p);
    } catch (e) {
      debugPrint('LocationService.mintaIzin: $e');
      return IzinLokasi.layananMati;
    }
  }

  @override
  Future<Posisi?> posisiSekarang() async {
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return Posisi(p.latitude, p.longitude, akurasiMeter: p.accuracy);
    } catch (e) {
      debugPrint('LocationService.posisiSekarang: $e');
      // Cadangan: posisi terakhir yang diketahui sistem (bisa kosong).
      try {
        final p = await Geolocator.getLastKnownPosition();
        return p == null ? null : Posisi(p.latitude, p.longitude, akurasiMeter: p.accuracy);
      } catch (_) {
        return null;
      }
    }
  }

  @override
  Stream<Posisi> aliran() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, distanceFilter: 20),
    ).map((p) => Posisi(p.latitude, p.longitude, akurasiMeter: p.accuracy));
  }

  @override
  Future<void> bukaPengaturanAplikasi() async {
    try {
      await Geolocator.openAppSettings();
    } catch (_) {}
  }

  @override
  Future<void> bukaPengaturanLokasi() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (_) {}
  }
}
