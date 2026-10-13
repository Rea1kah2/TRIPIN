import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'glass_insets.dart';
import 'glass_panel.dart';

/// Toast kapsul kaca. Status dibedakan lewat ikon (bukan warna saja).
void showAppSnackbar(BuildContext context, String message, {bool isError = false}) {
  final scheme = context.colors;
  final warna = isError ? scheme.error : scheme.primary;
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 4),
        margin: EdgeInsets.fromLTRB(16, 0, 16, 12 + GlassInsets.bawahOf(context)),
        content: Semantics(
          liveRegion: true,
          child: GlassPanel(
            blur: true,
            radius: 999,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(isError ? Icons.error_outline : Icons.check_circle_outline, size: 20, color: warna),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: scheme.onSurface),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
}
