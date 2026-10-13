import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../glass_panel.dart';

/// Penanda bahwa Tripy sedang bekerja: titik bergelombang + teks status.
///
/// [kecil] = baris ringan di bawah balasan yang sedang mengalir; bila false, kapsul
/// kaca dengan avatar yang berdenyut dipakai saat belum ada teks sama sekali.
class AssistantStatus extends StatefulWidget {
  final String teks;
  final bool kecil;

  const AssistantStatus({super.key, required this.teks, this.kecil = false});

  @override
  State<AssistantStatus> createState() => _AssistantStatusState();
}

class _AssistantStatusState extends State<AssistantStatus>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  /// True bila sistem meminta gerak dikurangi (Reduce Motion / animasi dimatikan di
  /// pengaturan HP, termasuk mode hemat baterai di beberapa merek). Gerak (naik-turun,
  /// denyut, kilau) dimatikan, tetapi titik tetap berkedip lembut lewat opacity supaya
  /// pengguna tahu Tripy masih bekerja.
  bool _kurangiGerak = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _kurangiGerak = MediaQuery.disableAnimationsOf(context);
    if (!_c.isAnimating) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final semantik = 'Tripy sedang bekerja: ${widget.teks}';
    return Semantics(
      liveRegion: true,
      label: semantik,
      child: ExcludeSemantics(
        child: widget.kecil ? _kecil(context) : _besar(context),
      ),
    );
  }

  Widget _kecil(BuildContext context) {
    final warna = context.tripin.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TitikGelombang(controller: _c, kurangiGerak: _kurangiGerak, warna: context.colors.primary, ukuran: 5),
          const SizedBox(width: 8),
          Text(widget.teks, style: TextStyle(color: warna, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _besar(BuildContext context) {
    final colors = context.colors;
    final tripin = context.tripin;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _c,
          builder: (_, child) {
            // Denyut avatar: skala 0.94 -> 1.06 (transform saja).
            final skala = _kurangiGerak ? 1.0 : 1.0 + 0.06 * math.sin(_c.value * 2 * math.pi);
            return Transform.scale(scale: skala, child: child);
          },
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: tripin.paleMint, shape: BoxShape.circle),
            child: Icon(Icons.auto_awesome, size: 16, color: colors.primary),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: GlassPanel(
            radius: 22,
            bias: -0.25,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TitikGelombang(controller: _c, kurangiGerak: _kurangiGerak, warna: colors.primary, ukuran: 7),
                const SizedBox(width: 10),
                Flexible(child: _TeksShimmer(teks: widget.teks, controller: _c, kurangiGerak: _kurangiGerak)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Tiga titik naik-turun berurutan (translateY + opacity).
class _TitikGelombang extends StatelessWidget {
  final AnimationController controller;
  final bool kurangiGerak;
  final Color warna;
  final double ukuran;

  const _TitikGelombang({
    required this.controller,
    required this.kurangiGerak,
    required this.warna,
    required this.ukuran,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: EdgeInsets.only(right: i < 2 ? ukuran * 0.6 : 0),
              child: _titik(i),
            ),
        ],
      ),
    );
  }

  Widget _titik(int i) {
    // Fase tiap titik bergeser 0.18 siklus; gelombang hanya aktif di separuh siklus.
    final t = (controller.value - i * 0.18) % 1.0;
    final puncak = math.sin(math.min(t / 0.5, 1.0) * math.pi);
    return Transform.translate(
      offset: Offset(0, kurangiGerak ? 0 : -ukuran * 0.8 * puncak),
      child: Opacity(
        opacity: kurangiGerak ? 0.3 + 0.7 * puncak : 0.45 + 0.55 * puncak,
        child: Container(
          width: ukuran,
          height: ukuran,
          decoration: BoxDecoration(color: warna, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

/// Teks status dengan kilau yang bergeser.
class _TeksShimmer extends StatelessWidget {
  final String teks;
  final AnimationController controller;
  final bool kurangiGerak;

  const _TeksShimmer({required this.teks, required this.controller, required this.kurangiGerak});

  @override
  Widget build(BuildContext context) {
    final dasar = context.tripin.textSecondary;
    final terang = context.colors.onSurface;
    final gaya = const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.3);
    if (kurangiGerak) return Text(teks, style: gaya.copyWith(color: terang));

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final geser = -1.0 + 3.0 * Curves.easeInOut.transform(controller.value);
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment(geser - 0.6, 0),
            end: Alignment(geser + 0.6, 0),
            colors: [dasar, terang, dasar],
          ).createShader(rect),
          child: Text(teks, style: gaya.copyWith(color: Colors.white)),
        );
      },
    );
  }
}
