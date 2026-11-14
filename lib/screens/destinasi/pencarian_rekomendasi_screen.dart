import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/destinasi.dart';
import '../../providers/destinasi_provider.dart';
import '../../providers/review_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/radii.dart';
import '../../theme/typography.dart';
import '../../utils/formatters.dart';
import '../../widgets/destinasi_image.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/glass_insets.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/glass_scaffold.dart';
import '../../widgets/kategori_chip.dart';
import '../../widgets/keadaan_kosong.dart';
import '../../widgets/pressable_scale.dart';
import '../../widgets/rating_stars.dart';

final _bentukCari = OutlineInputBorder(
  borderRadius: BorderRadius.circular(999),
  borderSide: BorderSide.none,
);

class PencarianRekomendasiScreen extends StatefulWidget {
  const PencarianRekomendasiScreen({super.key});

  @override
  State<PencarianRekomendasiScreen> createState() =>
      _PencarianRekomendasiScreenState();
}

class _PencarianRekomendasiScreenState
    extends State<PencarianRekomendasiScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _kataKunci = '';
  String? _kategoriIdTerpilih;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _labelKategori(
    DestinasiProvider provider,
    String kategoriId,
  ) {
    for (final kategori in provider.daftarKategori) {
      if (kategori.id == kategoriId) {
        return kategori.nama;
      }
    }
    return 'Lainnya';
  }

  void _bukaDetail(Destinasi d) {
    Navigator.pushNamed(
      context,
      AppRoutes.destinasiDetail,
      arguments: d.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DestinasiProvider>();
    final scheme = context.colors;

    final rekomendasi = List<Destinasi>.from(provider.daftarDestinasi)
      ..sort((a, b) => b.rating.compareTo(a.rating));
    final limaRekomendasi = rekomendasi.take(5).toList();

    final hasilPencarian = provider.cari(
      query: _kataKunci,
      kategoriId: _kategoriIdTerpilih,
    );
    final sedangFilter =
        _kataKunci.trim().isNotEmpty || _kategoriIdTerpilih != null;

    return GlassScaffold(
      appBar: const GlassAppBar(judul: 'Cari Wisata'),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          24 + GlassInsets.bawahOf(context),
        ),
        children: [
          // Kolom pencarian bergaya kapsul Liquid Glass
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _kataKunci = value),
            decoration: InputDecoration(
              hintText: 'Cari nama atau lokasi wisata...',
              fillColor: scheme.onSurface.withOpacity(0.07),
              prefixIcon: Icon(Icons.search, color: scheme.primary),
              suffixIcon: _kataKunci.isNotEmpty
                  ? IconButton(
                      tooltip: 'Hapus kata kunci',
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _kataKunci = '');
                      },
                    )
                  : null,
              border: _bentukCari,
              enabledBorder: _bentukCari,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide(color: scheme.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Kategori Wisata',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),

          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SemuaChip(
                    selected: _kategoriIdTerpilih == null,
                    onTap: () => setState(() => _kategoriIdTerpilih = null),
                  ),
                ),
                for (final kategori in provider.daftarKategori)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: KategoriChip(
                      kategori: kategori,
                      selected: _kategoriIdTerpilih == kategori.id,
                      onTap: () =>
                          setState(() => _kategoriIdTerpilih = kategori.id),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          if (!sedangFilter) ...[
            const Text(
              'Rekomendasi untuk Kamu',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 280,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: limaRekomendasi.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final destinasi = limaRekomendasi[index];
                  return _KartuRekomendasiGlass(
                    destinasi: destinasi,
                    kategori: _labelKategori(provider, destinasi.kategoriId),
                    onTap: () => _bukaDetail(destinasi),
                    onFavoriteTap: () => provider.toggleFavorit(destinasi.id),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          Row(
            children: [
              Expanded(
                child: Text(
                  sedangFilter ? 'Hasil Pencarian' : 'Semua Destinasi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${hasilPencarian.length} tempat',
                style: angkaTabular.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.tripin.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (hasilPencarian.isEmpty)
            KeadaanKosong(
              ikon: Icons.search_off_rounded,
              judul: 'Destinasi tidak ditemukan.',
              pesan: 'Coba kata kunci atau kategori lain.',
              labelAksi: 'Reset filter',
              onAksi: () {
                _searchController.clear();
                setState(() {
                  _kataKunci = '';
                  _kategoriIdTerpilih = null;
                });
              },
            )
          else
            for (final destinasi in hasilPencarian)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _KartuHasilGlass(
                  destinasi: destinasi,
                  kategori: _labelKategori(provider, destinasi.kategoriId),
                  onTap: () => _bukaDetail(destinasi),
                  onFavoriteTap: () => provider.toggleFavorit(destinasi.id),
                ),
              ),
        ],
      ),
    );
  }
}

class _KartuRekomendasiGlass extends StatelessWidget {
  final Destinasi destinasi;
  final String kategori;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  const _KartuRekomendasiGlass({
    required this.destinasi,
    required this.kategori,
    required this.onTap,
    required this.onFavoriteTap,
  });

  static const _padding = 8.0;

  @override
  Widget build(BuildContext context) {
    final tripin = context.tripin;
    final radiusFoto = konsentris(Radii.xl, _padding);

    return PressableScale(
      onTap: onTap,
      child: GlassPanel(
        radius: Radii.xl,
        padding: const EdgeInsets.all(_padding),
        child: SizedBox(
          width: 210,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(radiusFoto),
                child: SizedBox(
                  height: 132,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      DestinasiImage(
                        aset: destinasi.fotoUtama,
                        width: double.infinity,
                        height: 132,
                      ),
                      const Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 54,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x00000000), Color(0x88000000)],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.38),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.28),
                            ),
                          ),
                          child: Text(
                            kategori,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: _TombolFavorit(
                          aktif: destinasi.isFavorit,
                          onTap: onFavoriteTap,
                        ),
                      ),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: tripin.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            destinasi.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: tripin.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RatingStars(
                          rating: context
                              .watch<ReviewProvider>()
                              .ratingTampil(destinasi),
                          size: 15,
                        ),
                        Text(
                          formatRupiah(destinasi.price),
                          style: angkaTabular.copyWith(
                            color: context.colors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KartuHasilGlass extends StatelessWidget {
  final Destinasi destinasi;
  final String kategori;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  const _KartuHasilGlass({
    required this.destinasi,
    required this.kategori,
    required this.onTap,
    required this.onFavoriteTap,
  });

  static const _padding = 8.0;

  @override
  Widget build(BuildContext context) {
    final radiusFoto = konsentris(Radii.lg, _padding);
    final tripin = context.tripin;

    return PressableScale(
      onTap: onTap,
      child: GlassPanel(
        radius: Radii.lg,
        padding: const EdgeInsets.all(_padding),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(radiusFoto),
              child: DestinasiImage(
                aset: destinasi.fotoUtama,
                width: 100,
                height: 104,
              ),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      height: 1.2,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: tripin.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          destinasi.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: tripin.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        kategori,
                        style: TextStyle(
                          color: context.colors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      RatingStars(
                        rating: context
                            .watch<ReviewProvider>()
                            .ratingTampil(destinasi),
                        size: 14,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatRupiah(destinasi.price),
                    style: angkaTabular.copyWith(
                      color: context.colors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            _TombolFavorit(
              aktif: destinasi.isFavorit,
              onTap: onFavoriteTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _TombolFavorit extends StatelessWidget {
  final bool aktif;
  final VoidCallback onTap;

  const _TombolFavorit({
    required this.aktif,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Semantics(
        button: true,
        label: aktif ? 'Hapus dari favorit' : 'Tambah ke favorit',
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
                  aktif ? Icons.favorite : Icons.favorite_border,
                  color: aktif
                      ? context.tripin.favoriteActive
                      : context.colors.onSurface.withOpacity(0.7),
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
