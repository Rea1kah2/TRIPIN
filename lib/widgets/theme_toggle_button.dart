import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

// Matahari memakai oranye lebih tua agar kontras (>=3:1) di atas latar terang.
const _sunColor = Color(0xFFD97706);
const _moonColor = Color(0xFFE6F4EF);

/// Tombol ganti tema. [pill] = false: ikon 48x48 untuk AppBar,
/// [pill] = true: switch 64x32 untuk halaman Profil.
class ThemeToggleButton extends StatefulWidget {
  final bool pill;

  const ThemeToggleButton({super.key, this.pill = false});

  @override
  State<ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<ThemeToggleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOutCubic,
  );
  bool? _dark;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (_dark == null) {
      _controller.value = dark ? 1 : 0;
    } else if (_dark != dark) {
      final reduceMotion = MediaQuery.disableAnimationsOf(context);
      _controller.animateTo(
        dark ? 1 : 0,
        duration: reduceMotion ? Duration.zero : null,
      );
    }
    _dark = dark;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.selectionClick();
    context.read<ThemeProvider>().toggle(context);
  }

  @override
  Widget build(BuildContext context) {
    final dark = _dark ?? false;
    final label = dark ? 'Ganti ke mode terang' : 'Ganti ke mode gelap';
    return widget.pill ? _buildPill(context, dark, label) : _buildIcon(label);
  }

  Widget _buildIcon(String label) {
    return IconButton(
      onPressed: _toggle,
      tooltip: label,
      icon: AnimatedBuilder(
        animation: _progress,
        builder: (context, _) => CustomPaint(
          size: const Size(24, 24),
          painter: SunMoonPainter(
            progress: _progress.value,
            sunColor: _sunColor,
            moonColor: _moonColor,
          ),
        ),
      ),
    );
  }

  Widget _buildPill(BuildContext context, bool dark, String label) {
    const trackLight = Color(0xFFCFE8E0);
    const trackDark = Color(0xFF1E2A25);
    const thumbDark = Color(0xFF0F1512);
    final outline = Theme.of(context).colorScheme.outline;

    return Semantics(
      button: true,
      toggled: dark,
      label: 'Mode gelap',
      child: Tooltip(
        message: label,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 64),
          child: Center(
            child: AnimatedBuilder(
              animation: _progress,
              builder: (context, _) {
                final t = _progress.value;
                return Material(
                  color: Color.lerp(trackLight, trackDark, t),
                  shape: StadiumBorder(side: BorderSide(color: outline)),
                  child: InkWell(
                    customBorder: const StadiumBorder(),
                    onTap: _toggle,
                    child: SizedBox(
                      width: 64,
                      height: 32,
                      child: Stack(
                        children: [
                          // bintang kecil, muncul saat gelap
                          for (final b in const [
                            (10.0, 9.0, 1.6),
                            (20.0, 20.0, 1.2),
                            (26.0, 8.0, 1.0),
                          ])
                            Positioned(
                              left: b.$1,
                              top: b.$2,
                              child: Opacity(
                                opacity: t,
                                child: Container(
                                  width: b.$3 * 2,
                                  height: b.$3 * 2,
                                  decoration: const BoxDecoration(
                                    color: _moonColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            top: 3,
                            left: 3 + 32 * t,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: Color.lerp(Colors.white, thumbDark, t),
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x33000000),
                                    blurRadius: 3,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: CustomPaint(
                                painter: SunMoonPainter(
                                  progress: t,
                                  sunColor: _sunColor,
                                  moonColor: _moonColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Menggambar morph matahari -> bulan sabit di ruang 24x24.
/// progress 0 = matahari, 1 = bulan sabit.
class SunMoonPainter extends CustomPainter {
  final double progress;
  final Color sunColor;
  final Color moonColor;

  const SunMoonPainter({
    required this.progress,
    required this.sunColor,
    required this.moonColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress;
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(size.shortestSide / 24);
    canvas.rotate(p * 0.7); // ~40 derajat

    // Sinar: memendek, berputar, lalu menghilang.
    final rayAlpha = (1 - p * 1.4).clamp(0.0, 1.0);
    if (rayAlpha > 0) {
      final rayPaint = Paint()
        ..color = sunColor.withOpacity(rayAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;
      final length = 3.0 * (1 - p);
      for (var i = 0; i < 8; i++) {
        final angle = i * math.pi / 4 + p * math.pi / 4;
        final dir = Offset(math.cos(angle), math.sin(angle));
        canvas.drawLine(dir * 8.4, dir * (8.4 + length), rayPaint);
      }
    }

    // Inti membesar; lingkaran masker menggigitnya jadi bulan sabit.
    final coreRadius = 5.5 + 2.5 * p;
    final maskCenter = Offset.lerp(
      const Offset(13, -13),
      const Offset(4.6, -4.6),
      p,
    )!;
    canvas.saveLayer(Rect.fromCircle(center: Offset.zero, radius: 14), Paint());
    canvas.drawCircle(
      Offset.zero,
      coreRadius,
      Paint()..color = Color.lerp(sunColor, moonColor, p)!,
    );
    canvas.drawCircle(
      maskCenter,
      6.8,
      Paint()..blendMode = BlendMode.clear,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(SunMoonPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.sunColor != sunColor ||
      oldDelegate.moonColor != moonColor;
}
