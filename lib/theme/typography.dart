import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Inter di Android/web/desktop lain; iOS dan macOS memakai font sistem (SF).
String? get appFontFamily {
  if (kIsWeb) return 'Inter';
  final apple = defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
  return apple ? null : 'Inter';
}

/// Angka sejajar (harga, jarak, rating) agar digit tidak bergeser.
const angkaTabular = TextStyle(fontFeatures: [FontFeature.tabularFigures()]);
