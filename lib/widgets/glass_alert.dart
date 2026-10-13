import 'package:flutter/material.dart';
import 'glass_panel.dart';

class GlassAlertAksi<T> {
  final String label;
  final T nilai;
  final bool destruktif;
  final bool utama;

  const GlassAlertAksi({
    required this.label,
    required this.nilai,
    this.destruktif = false,
    this.utama = false,
  });
}

/// Dialog kaca tebal (lebar 270-320). Selalu sediakan jalan keluar (aksi Batal).
Future<T?> showGlassAlert<T>(
  BuildContext context, {
  required String judul,
  String? pesan,
  required List<GlassAlertAksi<T>> aksi,
}) {
  return showDialog<T>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.35),
    builder: (dialogContext) {
      final scheme = Theme.of(dialogContext).colorScheme;
      final garis = scheme.onSurface.withOpacity(0.14);

      Widget tombol(GlassAlertAksi<T> a) {
        final warna = a.destruktif ? scheme.error : scheme.primary;
        return Expanded(
          child: InkWell(
            onTap: () => Navigator.pop(dialogContext, a.nilai),
            child: SizedBox(
              height: 48,
              child: Center(
                child: Text(
                  a.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: a.utama ? FontWeight.w700 : FontWeight.w500,
                    color: warna,
                  ),
                ),
              ),
            ),
          ),
        );
      }

      final baris = <Widget>[];
      for (var i = 0; i < aksi.length; i++) {
        if (i > 0) baris.add(Container(width: 0.5, height: 48, color: garis));
        baris.add(tombol(aksi[i]));
      }

      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 270, maxWidth: 320),
            child: GlassPanel(
              blur: true,
              bias: 0.25,
              radius: 28,
              padding: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          judul,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                        ),
                        if (pesan != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            pesan,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: scheme.onSurface.withOpacity(0.72),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(height: 0.5, color: garis),
                  Row(children: baris),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
