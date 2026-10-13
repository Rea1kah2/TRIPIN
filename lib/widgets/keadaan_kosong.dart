import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'glass_button.dart';

/// Keadaan kosong yang mengarahkan: ikon, judul, penjelasan singkat, dan satu aksi.
class KeadaanKosong extends StatelessWidget {
  final IconData ikon;
  final String judul;
  final String pesan;
  final String? labelAksi;
  final VoidCallback? onAksi;

  const KeadaanKosong({
    super.key,
    required this.ikon,
    required this.judul,
    required this.pesan,
    this.labelAksi,
    this.onAksi,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Semantics(
          container: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: context.colors.onSurface.withOpacity(0.07),
                  shape: BoxShape.circle,
                ),
                child: Icon(ikon, size: 30, color: context.colors.primary),
              ),
              const SizedBox(height: 14),
              Text(
                judul,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                pesan,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.tripin.textSecondary, height: 1.4),
              ),
              if (labelAksi != null && onAksi != null) ...[
                const SizedBox(height: 18),
                GlassButton(label: labelAksi!, onPressed: onAksi, variant: GlassButtonVariant.prominent),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
