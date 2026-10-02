import 'package:flutter/material.dart';
import '../models/kategori.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';

class KategoriChip extends StatelessWidget {
  final Kategori kategori;
  final bool selected;
  final VoidCallback onTap;

  const KategoriChip({
    super.key,
    required this.kategori,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _PilihChip(
      label: kategori.nama,
      icon: kategori.icon,
      selected: selected,
      onTap: onTap,
    );
  }
}

/// Chip "Semua" dengan gaya yang sama seperti [KategoriChip].
class SemuaChip extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const SemuaChip({super.key, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _PilihChip(label: 'Semua', selected: selected, onTap: onTap);
  }
}

class _PilihChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _PilihChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final warna = selected ? scheme.primary : scheme.onSurface.withOpacity(0.78);

    // Kapsul 36 px, area sentuh 44 px. Aktif = tint utama 16% (+ ikon/teks utama).
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Center(
            child: AnimatedContainer(
              duration: Motion.base,
              curve: Motion.easeOut,
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected
                    ? scheme.primary.withOpacity(0.16)
                    : scheme.onSurface.withOpacity(0.06),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected ? scheme.primary.withOpacity(0.5) : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: warna),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: warna,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
