import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blurSigma;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.blurSigma = 12,
  });

  @override
  Widget build(BuildContext context) {
    final warna = context.tripin;
    final isiKaca = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [warna.glassFillStart, warna.glassFillEnd],
        ),
        border: Border.all(color: warna.glassBorder, width: 1),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: radius,
            right: radius,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    warna.glassHighlight.withOpacity(0.0),
                    warna.glassHighlight,
                    warna.glassHighlight.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: warna.glassShadow,
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: isiKaca,
          ),
        ),
      ),
    );
  }
}
