import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/destinasi.dart';
import '../../providers/destinasi_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/kategori_warna.dart';
import '../glass_panel.dart';
import '../pressable_scale.dart';

/// Warna titik posisi pengguna di peta.
const biruPosisi = Color(0xFF2F80ED);

/// Lapisan ubin OpenStreetMap (mode gelap memakai penyaring warna). Dipakai Peta dan Peta Rencana.
TileLayer lapisanUbinOsm({required bool gelap, TileProvider? tileProvider}) => TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.example.tugas_kelompok',
      // Ubin yang gagal dimuat (offline) dibiarkan kosong, bukan dilaporkan sebagai error.
      tileProvider: tileProvider ?? NetworkTileProvider(silenceExceptions: true),
      tileBuilder: gelap ? darkModeTileBuilder : null,
    );

class Penanda extends StatelessWidget {
  final Destinasi destinasi;
  final bool dipilih;
  final VoidCallback onTap;

  const Penanda({super.key, required this.destinasi, required this.dipilih, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final warna = warnaKategori(destinasi.kategoriId, b);
    final kategori = context.read<DestinasiProvider>().daftarKategori.where((k) => k.id == destinasi.kategoriId);
    final ikon = kategori.isEmpty ? Icons.place : kategori.first.icon;
    final ukuran = dipilih ? 46.0 : 34.0;
    return Semantics(
      button: true,
      label: destinasi.name,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: ukuran,
            height: ukuran,
            decoration: BoxDecoration(
              color: warna,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: dipilih ? 3 : 2),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: dipilih ? 10 : 5, offset: const Offset(0, 2))],
            ),
            child: Icon(ikon, size: dipilih ? 24 : 18, color: b == Brightness.dark ? const Color(0xFF10201A) : Colors.white),
          ),
        ),
      ),
    );
  }
}

class TitikPengguna extends StatelessWidget {
  const TitikPengguna({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Posisimu sekarang',
      child: Container(
        decoration: BoxDecoration(
          color: biruPosisi,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 6)],
        ),
      ),
    );
  }
}

class TombolBulat extends StatelessWidget {
  final String tooltip;
  final IconData ikon;
  final VoidCallback onTap;

  const TombolBulat({super.key, required this.tooltip, required this.ikon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: PressableScale(
        onTap: onTap,
        skala: 0.94,
        child: GlassPanel(
          radius: 26,
          blur: true,
          bias: 0.25,
          padding: EdgeInsets.zero,
          child: SizedBox(width: 52, height: 52, child: Icon(ikon, color: context.colors.primary)),
        ),
      ),
    );
  }
}

class AtribusiOsm extends StatelessWidget {
  final bool tersembunyi;

  const AtribusiOsm({super.key, required this.tersembunyi});

  @override
  Widget build(BuildContext context) {
    if (tersembunyi) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse('https://www.openstreetmap.org/copyright'), mode: LaunchMode.externalApplication),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.75),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('© OpenStreetMap', style: TextStyle(fontSize: 10, color: Colors.black87)),
      ),
    );
  }
}

/// Penanda bernomor urutan kunjungan pada Peta Rencana.
class PenandaBernomor extends StatelessWidget {
  final int nomor;
  final Destinasi destinasi;

  const PenandaBernomor({super.key, required this.nomor, required this.destinasi});

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final warna = warnaKategori(destinasi.kategoriId, b);
    return Semantics(
      label: 'Perhentian $nomor: ${destinasi.name}',
      child: Center(
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: warna,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 5, offset: const Offset(0, 2))],
          ),
          child: Text(
            '$nomor',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: b == Brightness.dark ? const Color(0xFF10201A) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
