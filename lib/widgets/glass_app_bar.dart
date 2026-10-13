import 'package:flutter/material.dart';
import 'glass_panel.dart';

/// Bar atas kapsul melayang. Dipakai di slot `appBar` GlassScaffold; konten mulai di
/// bawahnya, jadi bar berada di atas latar hidup (bukan di atas isi yang bergulir).
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  static const _jarak = 6.0;

  final String? judul;
  final Widget? title;
  final Widget? leading;
  final List<Widget> actions;
  final double tinggi;

  /// Jarak isi dari lengkung kiri kapsul bila tidak ada tombol kembali. Lengkung kapsul
  /// memakan ruang, jadi teks perlu napas lebih besar daripada padding persegi biasa.
  final double paddingKiri;

  /// Tampilkan tombol kembali otomatis bila layar ini di-push.
  final bool otomatisKembali;

  const GlassAppBar({
    super.key,
    this.judul,
    this.title,
    this.leading,
    this.actions = const [],
    this.tinggi = 56,
    this.paddingKiri = 26,
    this.otomatisKembali = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(tinggi + _jarak * 2);

  @override
  Widget build(BuildContext context) {
    final bisaKembali = otomatisKembali && leading == null && (ModalRoute.of(context)?.canPop ?? false);
    final awal = leading ??
        (bisaKembali
            ? IconButton(
                tooltip: 'Kembali',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.maybePop(context),
              )
            : null);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: _jarak),
        child: SizedBox(
          height: tinggi,
          child: GlassPanel(
            radius: 999,
            bias: 0.1,
            padding: EdgeInsets.only(left: awal == null ? paddingKiri : 4, right: 10),
            child: Row(
              children: [
                if (awal != null) awal,
                Expanded(
                  child: title ??
                      Text(
                        judul ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                ),
                ...actions,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
