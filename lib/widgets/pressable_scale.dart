import 'package:flutter/material.dart';
import '../theme/motion.dart';

/// Memberi umpan balik tekan (menciut halus) pada kartu yang bisa diketuk.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double skala;

  const PressableScale({super.key, required this.child, this.onTap, this.skala = 0.985});

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _tekan = false;

  @override
  Widget build(BuildContext context) {
    final aktif = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: aktif ? (_) => setState(() => _tekan = true) : null,
      onTapUp: aktif ? (_) => setState(() => _tekan = false) : null,
      onTapCancel: aktif ? () => setState(() => _tekan = false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _tekan ? widget.skala : 1,
        duration: Motion.fast,
        curve: Motion.easeOut,
        child: widget.child,
      ),
    );
  }
}
