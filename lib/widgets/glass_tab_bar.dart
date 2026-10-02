import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';
import 'glass_panel.dart';
import 'liquid_background.dart';

class GlassTabItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const GlassTabItem({required this.icon, required this.selectedIcon, required this.label});
}

/// Tab bar kapsul melayang di bawah, dengan scrim di belakangnya supaya isi yang
/// tergulir di bawahnya tetap membuat label terbaca.
class GlassTabBar extends StatelessWidget {
  static const tinggiBar = 64.0;
  static const jarakBawah = 12.0;

  final List<GlassTabItem> items;
  final int index;
  final ValueChanged<int> onSelect;

  const GlassTabBar({
    super.key,
    required this.items,
    required this.index,
    required this.onSelect,
  });

  /// Total ruang vertikal yang dipakai bar (termasuk jarak dan safe area).
  static double tinggiTotal(BuildContext context) =>
      tinggiBar + jarakBawah + MediaQuery.paddingOf(context).bottom;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final latar = LiquidBackground.dasar(Theme.of(context).brightness);
    final n = items.length;

    return DecoratedBox(
      // Scrim: memudar dari transparan ke warna latar agar bar tidak "bocor" ke isi.
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [latar.withOpacity(0), latar.withOpacity(0.85)],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 20, 16, jarakBawah + MediaQuery.paddingOf(context).bottom),
        child: GlassPanel(
          radius: 32,
          blur: true,
          padding: const EdgeInsets.all(6),
          child: SizedBox(
            height: tinggiBar - 12,
            child: Stack(
              children: [
                AnimatedAlign(
                  alignment: Alignment(n == 1 ? 0 : -1 + 2 * index / (n - 1), 0),
                  duration: Motion.base,
                  curve: Motion.easeOut,
                  child: FractionallySizedBox(
                    widthFactor: 1 / n,
                    heightFactor: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.primary.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < n; i++)
                      Expanded(child: _Item(item: items[i], aktif: i == index, onTap: () => _pilih(i))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _pilih(int i) {
    if (i != index) HapticFeedback.selectionClick();
    onSelect(i);
  }
}

class _Item extends StatelessWidget {
  final GlassTabItem item;
  final bool aktif;
  final VoidCallback onTap;

  const _Item({required this.item, required this.aktif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    // Label tidak aktif memakai onSurface (bukan abu pudar) supaya kontras terjaga di atas kaca.
    final warna = aktif ? scheme.primary : scheme.onSurface.withOpacity(0.72);
    return Semantics(
      button: true,
      selected: aktif,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(aktif ? item.selectedIcon : item.icon, size: 24, color: warna),
            const SizedBox(height: 2),
            Text(
              item.label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 11,
                fontWeight: aktif ? FontWeight.w600 : FontWeight.w500,
                color: warna,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
