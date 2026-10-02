import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/destinasi.dart';
import '../providers/destinasi_provider.dart';
import '../theme/app_colors.dart';
import '../theme/radii.dart';
import '../theme/typography.dart';
import '../utils/formatters.dart';
import 'glass_panel.dart';
import 'pressable_scale.dart';
import 'rating_stars.dart';
import 'destinasi_image.dart';
import '../providers/review_provider.dart';
import '../providers/lokasi_provider.dart';
import '../utils/geo.dart';

/// Kartu destinasi bergaya Liquid Glass: foto di dalam bingkai kaca dengan radius
/// konsentris. Tanpa BackdropFilter (aman dipakai di dalam list).
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

  static const _paddingBingkai = 8.0;

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

    return PressableScale(
      onTap: onTap,
      child: GlassPanel(
        padding: const EdgeInsets.all(_paddingBingkai),
        radius: dense ? Radii.lg : Radii.xl,
        child: dense ? _buildDense(context) : _buildFull(context, labelKategori),
      ),
    );
  }

  Widget _tombolFavorit(BuildContext context) {
    final tripin = context.tripin;
    // Tampil 36 px, area sentuh 44 px.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onFavoriteTap,
      child: Semantics(
        button: true,
        label: destinasi.isFavorit ? 'Hapus dari favorit' : 'Tambah ke favorit',
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: GlassPanel(
              radius: 18,
              bias: 0.25,
              padding: EdgeInsets.zero,
              child: SizedBox(
                width: 36,
                height: 36,
                child: Icon(
                  destinasi.isFavorit ? Icons.favorite : Icons.favorite_border,
                  color: destinasi.isFavorit ? tripin.favoriteActive : context.colors.onSurface.withOpacity(0.7),
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFull(BuildContext context, String labelKategori) {
    final primary = context.colors.primary;
    final tripin = context.tripin;
    final radiusFoto = konsentris(Radii.xl, _paddingBingkai);
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(radiusFoto),
            child: SizedBox(
              height: 140,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DestinasiImage(aset: destinasi.fotoUtama, width: double.infinity, height: 140),
                  // Scrim bawah agar pil kategori terbaca di atas foto apa pun.
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 64,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x00000000), Color(0x8C000000)],
                        ),
                      ),
                    ),
                  ),
                  if (labelKategori.isNotEmpty)
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.38),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white.withOpacity(0.28)),
                        ),
                        child: Text(
                          labelKategori,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  Positioned(top: 0, right: 0, child: _tombolFavorit(context)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  destinasi.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 15, color: tripin.textSecondary),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        destinasi.location,
                        style: TextStyle(color: tripin.textSecondary, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RatingStars(rating: context.watch<ReviewProvider>().ratingTampil(destinasi), size: 15),
                    Text(
                      formatRupiah(destinasi.price),
                      style: angkaTabular.copyWith(color: primary, fontWeight: FontWeight.w700, fontSize: 13),
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

  Widget _buildDense(BuildContext context) {
    final radiusFoto = konsentris(Radii.lg, _paddingBingkai);
    return SizedBox(
      height: 84,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(radiusFoto),
            child: DestinasiImage(aset: destinasi.fotoUtama, width: 90, height: 84),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  destinasi.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.2),
                ),
                const SizedBox(height: 6),
                _BarisJarak(destinasi: destinasi),
              ],
            ),
          ),
          _tombolFavorit(context),
        ],
      ),
    );
  }
}

/// Jarak nyata dari posisi pengguna; bila lokasi belum aktif, tampil penanda (bukan angka palsu).
class _BarisJarak extends StatelessWidget {
  final Destinasi destinasi;

  const _BarisJarak({required this.destinasi});

  @override
  Widget build(BuildContext context) {
    final jarak = context.watch<LokasiProvider>().jarakKe(destinasi);
    final primary = context.colors.primary;
    return Row(
      children: [
        Icon(jarak == null ? Icons.location_off_outlined : Icons.near_me_outlined,
            size: 14, color: jarak == null ? context.tripin.textSecondary : primary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            jarak == null ? 'Lokasi belum aktif' : '${formatJarak(jarak)} dari kamu',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: angkaTabular.copyWith(
              color: jarak == null ? context.tripin.textSecondary : primary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
