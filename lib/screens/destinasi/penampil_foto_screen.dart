import 'package:flutter/material.dart';
import '../../models/destinasi.dart';
import '../../widgets/destinasi_galeri.dart';
import '../../widgets/destinasi_image.dart';
import '../../widgets/glass_panel.dart';

/// Penampil foto layar penuh: geser antar foto, cubit/ketuk dua kali untuk zoom (1-4x).
class PenampilFotoScreen extends StatefulWidget {
  final Destinasi destinasi;
  final int halamanAwal;

  const PenampilFotoScreen({super.key, required this.destinasi, this.halamanAwal = 0});

  @override
  State<PenampilFotoScreen> createState() => _PenampilFotoScreenState();
}

class _PenampilFotoScreenState extends State<PenampilFotoScreen> {
  late final PageController _kontrol = PageController(initialPage: widget.halamanAwal);
  final _transformasi = TransformationController();
  late int _halaman = widget.halamanAwal;
  bool _diperbesar = false;

  @override
  void dispose() {
    _kontrol.dispose();
    _transformasi.dispose();
    super.dispose();
  }

  void _saatZoom() {
    final diperbesar = _transformasi.value.getMaxScaleOnAxis() > 1.02;
    if (diperbesar != _diperbesar) setState(() => _diperbesar = diperbesar);
  }

  void _zoomDuaKali() {
    _transformasi.value = _diperbesar ? Matrix4.identity() : (Matrix4.identity()..scale(2.5));
    _saatZoom();
  }

  @override
  Widget build(BuildContext context) {
    final foto = widget.destinasi.fotoAssets;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _kontrol,
            itemCount: foto.length,
            // Saat diperbesar, geser dipakai untuk menggeser foto, bukan pindah halaman.
            physics: _diperbesar ? const NeverScrollableScrollPhysics() : const PageScrollPhysics(),
            onPageChanged: (i) {
              _transformasi.value = Matrix4.identity();
              setState(() {
                _halaman = i;
                _diperbesar = false;
              });
            },
            itemBuilder: (_, i) => GestureDetector(
              onDoubleTap: _zoomDuaKali,
              child: InteractiveViewer(
                transformationController: i == _halaman ? _transformasi : null,
                minScale: 1,
                maxScale: 4,
                onInteractionEnd: (_) => _saatZoom(),
                child: Center(child: DestinasiImage(aset: foto[i], fit: BoxFit.contain)),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    button: true,
                    label: 'Tutup',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.maybePop(context),
                      child: const SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(
                          child: GlassPanel(
                            radius: 20,
                            blur: true,
                            bias: 0.25,
                            padding: EdgeInsets.zero,
                            child: SizedBox(width: 40, height: 40, child: Icon(Icons.close, size: 22)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(999)),
                    child: Text(
                      '${_halaman + 1}/${foto.length}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (foto.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: KeteranganKredit(destinasiId: widget.destinasi.id, file: foto[_halaman]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
