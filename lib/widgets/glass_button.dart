import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';
import 'glass_panel.dart';

enum GlassButtonVariant { prominent, glass, plain, destructive }

/// Tombol kapsul. Hanya SATU `prominent` per layar; aksi lain pakai `glass`/`plain`.
class GlassButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed; // null = nonaktif
  final IconData? icon;
  final GlassButtonVariant variant;
  final bool besar;
  final bool melebar;

  const GlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = GlassButtonVariant.glass,
    this.besar = false,
    this.melebar = false,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _tekan = false;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final aktif = widget.onPressed != null;
    final tinggi = widget.besar ? 52.0 : 48.0;
    final v = widget.variant;
    final warnaTeks = switch (v) {
      GlassButtonVariant.prominent => scheme.onPrimary,
      GlassButtonVariant.glass => scheme.onSurface,
      GlassButtonVariant.plain => scheme.primary,
      GlassButtonVariant.destructive => scheme.error,
    };

    final isi = SizedBox(
      height: tinggi,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Row(
          mainAxisSize: widget.melebar ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, size: 20, color: warnaTeks),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: warnaTeks),
              ),
            ),
          ],
        ),
      ),
    );

    final Widget tombol = v == GlassButtonVariant.plain
        ? isi
        : GlassPanel(
            radius: 999,
            padding: EdgeInsets.zero,
            accent: v == GlassButtonVariant.prominent,
            bias: v == GlassButtonVariant.prominent ? 0 : -0.25,
            child: isi,
          );

    return Semantics(
      button: true,
      enabled: aktif,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: aktif ? (_) => setState(() => _tekan = true) : null,
        onTapUp: aktif ? (_) => setState(() => _tekan = false) : null,
        onTapCancel: aktif ? () => setState(() => _tekan = false) : null,
        onTap: aktif
            ? () {
                if (v == GlassButtonVariant.prominent) HapticFeedback.lightImpact();
                widget.onPressed!();
              }
            : null,
        child: AnimatedScale(
          scale: _tekan ? 0.96 : 1,
          duration: Motion.fast,
          curve: Motion.easeOut,
          child: Opacity(opacity: aktif ? 1 : 0.4, child: tombol),
        ),
      ),
    );
  }
}
