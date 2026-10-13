import 'package:flutter/material.dart';
import '../models/destinasi.dart';
import '../screens/destinasi/penampil_foto_screen.dart';
import '../services/kredit_foto.dart';
import 'destinasi_image.dart';

/// Galeri foto destinasi: geser antar foto, indikator titik, kredit fotografer, dan
/// ketuk untuk membuka penampil layar penuh. Bila belum ada foto, tampil penanda jujur.
class DestinasiGaleri extends StatefulWidget {
  final Destinasi destinasi;

  const DestinasiGaleri({super.key, required this.destinasi});

  @override
  State<DestinasiGaleri> createState() => _DestinasiGaleriState();
}

class _DestinasiGaleriState extends State<DestinasiGaleri> {
  final _kontrol = PageController();
  int _halaman = 0;

  @override
  void dispose() {
    _kontrol.dispose();
    super.dispose();
  }

  void _buka() {
    Navigator.of(context).push(PageRouteBuilder<void>(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => PenampilFotoScreen(destinasi: widget.destinasi, halamanAwal: _halaman),
      transitionsBuilder: (_, animasi, __, anak) => FadeTransition(opacity: animasi, child: anak),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final foto = widget.destinasi.fotoAssets;
    if (foto.isEmpty) {
      return const DestinasiImage(aset: null, width: double.infinity, height: double.infinity);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _kontrol,
          itemCount: foto.length,
          onPageChanged: (i) => setState(() => _halaman = i),
          itemBuilder: (_, i) => GestureDetector(
            onTap: _buka,
            child: Semantics(
              button: true,
              label: 'Foto ${i + 1} dari ${foto.length}, ketuk untuk memperbesar',
              child: DestinasiImage(aset: foto[i], width: double.infinity, height: double.infinity),
            ),
          ),
        ),
        // Kredit fotografer (syarat lisensi) untuk foto yang sedang tampil.
        Positioned(
          left: 12,
          bottom: 40,
          right: 90,
          child: IgnorePointer(child: KeteranganKredit(destinasiId: widget.destinasi.id, file: foto[_halaman])),
        ),
        if (foto.length > 1)
          Positioned(
            right: 12,
            bottom: 40,
            child: IgnorePointer(child: _Indikator(jumlah: foto.length, aktif: _halaman)),
          ),
      ],
    );
  }
}

/// Baris kredit kecil di atas foto: "Foto: fotografer · lisensi".
class KeteranganKredit extends StatelessWidget {
  final String destinasiId;
  final String file;

  const KeteranganKredit({super.key, required this.destinasiId, required this.file});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<KreditFoto>>>(
      future: KreditFotoService.muat(),
      builder: (context, snap) {
        final daftar = snap.data?[destinasiId] ?? const <KreditFoto>[];
        final k = daftar.where((e) => e.file == file).firstOrNull;
        if (k == null) return const SizedBox.shrink();
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Foto: ${k.ringkas}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.white),
            ),
          ),
        );
      },
    );
  }
}

/// Titik indikator + penghitung "2/3" dalam kapsul gelap (terbaca di atas foto apa pun).
class _Indikator extends StatelessWidget {
  final int jumlah;
  final int aktif;

  const _Indikator({required this.jumlah, required this.aktif});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Foto ${aktif + 1} dari $jumlah',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.45),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < jumlah; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: i == aktif ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(i == aktif ? 1 : 0.55),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                '${aktif + 1}/$jumlah',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
