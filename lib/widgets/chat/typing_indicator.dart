import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Tiga titik berdenyut saat asisten sedang menyusun jawaban.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final warna = context.tripin.textSecondary;
    return Semantics(
      label: 'Asisten sedang mengetik',
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 5 : 0),
                  child: Opacity(
                    opacity: _opacity(i),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: warna, shape: BoxShape.circle),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  double _opacity(int i) {
    if (!_controller.isAnimating) return 0.7;
    final t = (_controller.value - i * 0.15) % 1.0;
    return 0.3 + 0.7 * (t < 0.5 ? t * 2 : (1 - t) * 2);
  }
}
