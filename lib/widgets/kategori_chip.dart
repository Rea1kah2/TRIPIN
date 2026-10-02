import 'package:flutter/material.dart';
import '../models/kategori.dart';
import '../theme/app_colors.dart';

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
    final primary = context.colors.primary;
    final onPrimary = context.colors.onPrimary;

    return ChoiceChip(
      label: Text(label),
      avatar: icon == null
          ? null
          : Icon(icon, size: 16, color: selected ? onPrimary : primary),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: primary,
      backgroundColor: context.tripin.paleMint,
      side: BorderSide.none,
      labelStyle: TextStyle(
        color: selected ? onPrimary : primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
