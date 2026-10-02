import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/destinasi.dart';
import '../../providers/destinasi_provider.dart';
import '../../providers/rencana_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/destinasi_image.dart';
import '../../widgets/glass_scaffold.dart';
import '../../widgets/glass_sheet.dart';
import '../../theme/radii.dart';
import '../../theme/typography.dart';
import '../../widgets/glass_button.dart';
import '../../widgets/glass_panel.dart';
import '../../services/kredit_foto.dart';
import '../../providers/review_provider.dart';
import '../../widgets/review/review_section.dart';
import '../../providers/lokasi_provider.dart';
import '../../utils/geo.dart';

/// "Medan · 4,2 km dari kamu" (jarak nyata), atau hanya lokasi bila posisi belum diketahui.
String jarakTeks(BuildContext context, Destinasi d) {
  final jarak = context.watch<LokasiProvider>().jarakKe(d);
  final perkiraan = d.lokasiPerkiraan ? ' (perkiraan)' : '';
  return jarak == null ? d.location : '${d.location} · ${formatJarak(jarak)} dari kamu$perkiraan';
}

class DetailDestinasiScreen extends StatelessWidget {
  final String destinasiId;

  const DetailDestinasiScreen({super.key, required this.destinasiId});

  String _labelKategori(BuildContext context, String kategoriId) {
    final daftarKategori = context.watch<DestinasiProvider>().daftarKategori;
    for (final k in daftarKategori) {
      if (k.id == kategoriId) return k.nama;
    }
    return '';
  }

  void _bukaPilihRencana(BuildContext context) {
    final rencanaProvider = context.read<RencanaProvider>();

    showGlassSheet(
      context,
      builder: (sheetContext) {
        final daftarRencana = rencanaProvider.daftarRencana;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tambah ke Rencana',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (daftarRencana.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Kamu belum punya rencana perjalanan. Buat dulu satu.',
                      style: TextStyle(color: context.tripin.textSecondary),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: daftarRencana.length,
                      itemBuilder: (context, index) {
                        final rencana = daftarRencana[index];
                        final sudahAda =
                            rencana.daftarDestinasiId.contains(destinasiId);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(rencana.judul),
                          trailing: sudahAda
                              ? Icon(Icons.check_circle,
                                  color: context.colors.primary)
                              : const Icon(Icons.add_circle_outline),
                          onTap: sudahAda
                              ? null
                              : () {
                                  rencanaProvider.tambahDestinasiKeRencana(
                                    rencana.id,
                                    destinasiId,
                                  );
                                  Navigator.pop(sheetContext);
                                  showAppSnackbar(
                                    context,
                                    'Ditambahkan ke "${rencana.judul}"',
                                  );
                                },
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.pushNamed(context, AppRoutes.rencanaTambah);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Buat Rencana Baru'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DestinasiProvider>();
    final destinasi = provider.getById(destinasiId);

    if (destinasi == null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => Navigator.pop(context));
      return const SizedBox.shrink();
    }

    final labelKategori = _labelKategori(context, destinasi.kategoriId);
    final primary = context.colors.primary;
    final tripin = context.tripin;

    return GlassScaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            leadingWidth: 64,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: _TombolBulatKaca(
                tooltip: 'Kembali',
                ikon: Icons.arrow_back,
                onTap: () => Navigator.maybePop(context),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _TombolBulatKaca(
                  tooltip: destinasi.isFavorit
                      ? 'Hapus dari favorit'
                      : 'Tambah ke favorit',
                  ikon: destinasi.isFavorit
                      ? Icons.favorite
                      : Icons.favorite_border,
                  warnaIkon: destinasi.isFavorit ? tripin.favoriteActive : null,
                  onTap: () => provider.toggleFavorit(destinasi.id),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: ClipRRect(
                // Foto berakhir melengkung; AppBar yang di-pin melukis di atas sliver berikutnya,
                // jadi kartu info tidak boleh ditarik naik menimpa foto.
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(Radii.xl)),
                child: DestinasiImage(
                  aset: destinasi.fotoUtama,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Padding(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlassPanel(
                      radius: Radii.xl,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            destinasi.name,
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                height: 1.2),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              labelKategori,
                              style: TextStyle(
                                  color: primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 16, color: tripin.textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  jarakTeks(context, destinasi),
                                  style: angkaTabular.copyWith(
                                      color: tripin.textSecondary,
                                      fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              RatingStars(rating: context.watch<ReviewProvider>().ratingTampil(destinasi), size: 18),
                              Text(
                                formatRupiah(destinasi.price),
                                style: angkaTabular.copyWith(
                                  color: primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Tentang Destinasi',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(
                      destinasi.description,
                      style: TextStyle(
                          color: context.colors.onSurface.withOpacity(0.87),
                          height: 1.55,
                          fontSize: 15),
                    ),
                    const SizedBox(height: 24),
                    ReviewSection(destinasi: destinasi),
                    const SizedBox(height: 28),
                    GlassButton(
                      label: 'Tambah ke Rencana',
                      icon: Icons.map_outlined,
                      variant: GlassButtonVariant.prominent,
                      besar: true,
                      melebar: true,
                      onPressed: () => _bukaPilihRencana(context),
                    ),
                    const SizedBox(height: 12),
                    GlassButton(
                      label: 'Tanya Tripy tentang tempat ini',
                      icon: Icons.auto_awesome,
                      melebar: true,
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.chat,
                        arguments:
                            'Ceritakan tentang ${destinasi.name} dan apa yang bisa dilakukan di sana.',
                      ),
                    ),
                    const SizedBox(height: 16),
                    _KeteranganFoto(idDestinasi: destinasi.id),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tombol bulat kaca di atas foto (tampil 40, area sentuh 48).
class _TombolBulatKaca extends StatelessWidget {
  final String tooltip;
  final IconData ikon;
  final Color? warnaIkon;
  final VoidCallback onTap;

  const _TombolBulatKaca({
    required this.tooltip,
    required this.ikon,
    required this.onTap,
    this.warnaIkon,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: GlassPanel(
              radius: 20,
              bias: 0.25,
              blur: true,
              padding: EdgeInsets.zero,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(ikon,
                    size: 22, color: warnaIkon ?? context.colors.onSurface),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Atribusi foto (syarat lisensi CC BY / CC BY-SA); kosong bila foto belum tersedia.
class _KeteranganFoto extends StatelessWidget {
  final String idDestinasi;

  const _KeteranganFoto({required this.idDestinasi});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<KreditFoto>>>(
      future: KreditFotoService.muat(),
      builder: (context, snap) {
        final kredit = snap.data?[idDestinasi];
        if (kredit == null || kredit.isEmpty) return const SizedBox.shrink();
        return Center(
          child: Text(
            'Foto: ${kredit.first.ringkas}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: context.tripin.textSecondary),
          ),
        );
      },
    );
  }
}
