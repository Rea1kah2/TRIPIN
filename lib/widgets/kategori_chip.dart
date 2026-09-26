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
    return ChoiceChip(
      label: Text(kategori.nama),
      avatar: Icon(kategori.icon,
          size: 16, color: selected ? Colors.white : AppColors.primary),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.paleMint,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
