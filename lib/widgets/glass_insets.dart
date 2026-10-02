import 'package:flutter/widgets.dart';

/// Ruang di bawah yang tertutup tab bar melayang. Layar tab menambahkannya ke padding
/// scroll agar isi terakhir tidak tertutup; nol bila tidak berada di dalam tab bar
/// (layar yang di-push) atau saat keyboard terbuka.
class GlassInsets extends InheritedWidget {
  final double bawah;

  const GlassInsets({super.key, required this.bawah, required super.child});

  static double bawahOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GlassInsets>()?.bawah ?? 0;

  @override
  bool updateShouldNotify(GlassInsets oldWidget) => oldWidget.bawah != bawah;
}
