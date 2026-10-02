import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/destinasi_provider.dart';
import '../../theme/app_colors.dart';

class MapsScreen extends StatefulWidget {
  final String destinasiId;

  const MapsScreen({
    super.key,
    required this.destinasiId,
  });

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  bool _sedangMemuat = false;

  Future<void> _bukaGoogleMaps(String query) async {
    final Uri url = Uri.https(
      'www.google.com',
      '/maps/search/',
      {'api': '1', 'query': query},
    );

    try {
      final berhasil = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!berhasil && mounted) {
        _tampilkanPesan('Google Maps tidak dapat dibuka.');
      }
    } catch (e) {
      _tampilkanPesan('Terjadi kesalahan saat membuka Google Maps.');
    }
  }

  Future<void> _cariWisataTerdekat() async {
    if (_sedangMemuat) return;

    setState(() => _sedangMemuat = true);

    try {
      final gpsAktif =
      await Geolocator.isLocationServiceEnabled();

      if (!gpsAktif) {
        _tampilkanPesan('Aktifkan GPS terlebih dahulu.');
        return;
      }

      LocationPermission izin =
      await Geolocator.checkPermission();

      if (izin == LocationPermission.denied) {
        izin = await Geolocator.requestPermission();
      }

      if (izin == LocationPermission.denied) {
        _tampilkanPesan('Izin lokasi belum diberikan.');
        return;
      }

      if (izin == LocationPermission.deniedForever) {
        _tampilkanPesan(
          'Izin lokasi ditolak permanen. Aktifkan melalui '
              'pengaturan aplikasi.',
        );
        return;
      }

      final posisi = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      if (!mounted) return;

      final query =
          'tempat wisata dekat ${posisi.latitude},${posisi.longitude}';

      await _bukaGoogleMaps(query);
    } catch (e) {
      _tampilkanPesan(
        'Lokasi gagal diperoleh. Pastikan GPS aktif, lalu coba lagi.',
      );
    } finally {
      if (mounted) {
        setState(() => _sedangMemuat = false);
      }
    }
  }

  void _tampilkanPesan(String pesan) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final destinasi = context
        .watch<DestinasiProvider>()
        .getById(widget.destinasiId);

    if (destinasi == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Peta Destinasi'),
        ),
        body: const Center(
          child: Text('Data destinasi tidak ditemukan.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Destinasi'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Icon(
                Icons.location_on_rounded,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                destinasi.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                destinasi.location,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Temukan lokasi destinasi dan cari tempat '
                            'wisata di sekitar posisi kamu menggunakan GPS.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final query =
                        '${destinasi.name}, ${destinasi.location}';

                    _bukaGoogleMaps(query);
                  },
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Buka Lokasi Destinasi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed:
                  _sedangMemuat ? null : _cariWisataTerdekat,
                  icon: _sedangMemuat
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.my_location),
                  label: Text(
                    _sedangMemuat
                        ? 'Mencari lokasi...'
                        : 'Cari Wisata Terdekat',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(
                      color: AppColors.primary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Catatan: Fitur GPS memerlukan izin lokasi dan '
                    'layanan GPS yang aktif. Google Maps akan dibuka '
                    'melalui aplikasi atau browser.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}