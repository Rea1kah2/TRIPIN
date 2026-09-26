import 'package:flutter/material.dart';
import '../models/rencana_perjalanan.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import 'glass_card.dart';

class RencanaCard extends StatelessWidget {
  final RencanaPerjalanan rencana;
  final int jumlahDestinasi;
  final VoidCallback onTap;

  const RencanaCard({
    super.key,
    required this.rencana,
    required this.jumlahDestinasi,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rencana.judul,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    '${formatTanggal(rencana.tanggalMulai)} - ${formatTanggal(rencana.tanggalSelesai)}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$jumlahDestinasi destinasi',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 15, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
