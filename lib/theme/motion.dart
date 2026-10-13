import 'package:flutter/animation.dart';

/// Token gerak. Animasi hanya memakai transform dan opacity.
class Motion {
  Motion._();

  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 400);
  static const easeOut = Cubic(0.32, 0.72, 0, 1);
  static const easeInOut = Cubic(0.65, 0, 0.35, 1);
}
