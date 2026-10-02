import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/destinasi.dart';
import '../providers/destinasi_provider.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import 'glass_card.dart';
import 'rating_stars.dart';
import 'safe_network_image.dart';

class DestinasiCard extends StatelessWidget {
  final Destinasi destinasi;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  final bool dense;

  const DestinasiCard({
    super.key,
    required this.destinasi,
    required this.onTap,
    required this.onFavoriteTap,
    this.dense = false,
  });

  String _labelKategori(BuildContext context) {
    final daftarKategori = context.watch<DestinasiProvider>().daftarKategori;
    for (final k in daftarKategori) {
      if (k.id == destinasi.kategoriId) return k.nama;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final labelKategori = _labelKategori(context);

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: EdgeInsets.zero,
        radius: 20,
        child: dense
            ? _buildDense(context, labelKategori)
            : _buildFull(context, labelKategori),
      ),
    );
  }

  Widget _buildFull(BuildContext context, String labelKategori) {
    final primary = context.colors.primary;
    final tripin = context.tripin;
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: SafeNetworkImage(
                  url: destinasi.imageUrl,
                  width: double.infinity,
                  height: 135,
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: onFavoriteTap,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: context.colors.surface.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      destinasi.isFavorit ? Icons.favorite : Icons.favorite_border,
                      color: destinasi.isFavorit ? tripin.favoriteActive : tripin.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(destinasi.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  labelKategori,
                  style: TextStyle(color: primary, fontSize: 11, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 15, color: tripin.textSecondary),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        destinasi.location,
                        style: TextStyle(color: tripin.textSecondary, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RatingStars(rating: destinasi.rating, size: 15),
                    Text(
                      formatRupiah(destinasi.price),
                      style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDense(BuildContext context, String labelKategori) {
    final primary = context.colors.primary;
    final tripin = context.tripin;
    return SizedBox(
      height: 105,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SafeNetworkImage(url: destinasi.imageUrl, width: 90, height: 85),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(destinasi.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.near_me_outlined, size: 14, color: primary),
                      const SizedBox(width: 3),
                      Text(
                        '${destinasi.distanceKm.toStringAsFixed(1)} km dari kamu',
                        style: TextStyle(color: primary, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onFavoriteTap,
              child: Icon(
                destinasi.isFavorit ? Icons.favorite : Icons.favorite_border,
                color: destinasi.isFavorit ? tripin.favoriteActive : tripin.textSecondary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}