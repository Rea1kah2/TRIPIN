import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../models/destinasi.dart';
import '../../providers/lokasi_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/rute.dart';
import '../../theme/app_colors.dart';
import '../../theme/radii.dart';
import '../../utils/geo.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/glass_button.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/glass_scaffold.dart';
import '../../widgets/glass_sheet.dart';
import '../../widgets/peta/komponen_peta.dart';

/// Peta satu rencana: penanda bernomor sesuai urutan kunjungan, garis lurus antar titik,
/// ringkasan jarak, dan tombol membuka rute di Google Maps. Garis lurus hanya gambaran
/// urutan; jarak jalan sebenarnya dihitung Google Maps.
class PetaRencanaScreen extends StatefulWidget {
  final String judul;
  final List<Destinasi> daftar;

  /// Untuk tes: ganti pemuat ubin jaringan dan pembuka tautan.
  final TileProvider? tileProvider;
  final Future<bool> Function(Uri uri)? luncurkan;

  const PetaRencanaScreen({
    super.key,
    required this.judul,
    required this.daftar,
    this.tileProvider,
    this.luncurkan,
  });

  @override
  State<PetaRencanaScreen> createState() => _PetaRencanaScreenState();
}

class _PetaRencanaScreenState extends State<PetaRencanaScreen> {
  @override
  void initState() {
    super.initState();
    // Cek izin tanpa dialog; bila sudah diizinkan, ambil posisi sekali (tanpa pelacakan terus-menerus).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<LokasiProvider>().muatAwal();
    });
  }

  List<LatLng> get _titik => [for (final d in widget.daftar) LatLng(d.lat, d.lng)];

  double get _totalKm => panjangRuteKm([for (final d in widget.daftar) (lat: d.lat, lng: d.lng)]);

  Future<void> _bukaRute() async {
    final rute = rancangRuteRencana(widget.daftar);
    if (rute == null) return;
    final ok = await bukaRuteRencana(widget.daftar, luncurkan: widget.luncurkan);
    if (!mounted) return;
    if (ok == false) {
      showAppSnackbar(context, 'Tidak bisa membuka peta. Pastikan ada aplikasi peta atau browser.', isError: true);
    } else if (rute.terpotong > 0) {
      showAppSnackbar(context, 'Google Maps hanya memuat ${rute.dipakai} perhentian pertama (${rute.terpotong} lainnya tidak ikut).');
    }
  }

  void _bukaDaftar() {
    showGlassSheet<void>(
      context,
      builder: (sheetContext) => _DaftarPerhentian(
        daftar: widget.daftar,
        onPilih: (d) {
          Navigator.pop(sheetContext);
          Navigator.pushNamed(context, AppRoutes.destinasiDetail, arguments: d.id);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lokasi = context.watch<LokasiProvider>();
    final scheme = context.colors;
    final gelap = Theme.of(context).brightness == Brightness.dark;
    final titik = _titik;
    final p = lokasi.posisi;
    final daftar = widget.daftar;
    final jarakAwal = daftar.isEmpty ? null : lokasi.jarakKe(daftar.first);
    final rute = rancangRuteRencana(daftar);

    final MapOptions opsi = titik.length < 2
        ? MapOptions(
            initialCenter: titik.isEmpty ? const LatLng(3.5952, 98.6722) : titik.first,
            initialZoom: titik.isEmpty ? 8 : 12,
            minZoom: 5,
            maxZoom: 18,
          )
        : MapOptions(
            initialCameraFit: CameraFit.bounds(
              bounds: LatLngBounds.fromPoints(titik),
              padding: const EdgeInsets.fromLTRB(48, 56, 48, 250),
              maxZoom: 15,
            ),
            minZoom: 5,
            maxZoom: 18,
          );

    return GlassScaffold(
      appBar: GlassAppBar(judul: widget.judul),
      body: ClipRect(
        child: Stack(
          children: [
            Positioned.fill(
              child: FlutterMap(
                options: opsi,
                children: [
                  lapisanUbinOsm(gelap: gelap, tileProvider: widget.tileProvider),
                  if (titik.length >= 2)
                    PolylineLayer(polylines: [
                      Polyline(
                        points: titik,
                        strokeWidth: 4,
                        color: scheme.primary.withOpacity(0.85),
                        pattern: StrokePattern.dashed(segments: const [10, 8]),
                      ),
                    ]),
                  if (p != null)
                    MarkerLayer(
                      markers: [Marker(point: LatLng(p.lat, p.lng), width: 26, height: 26, child: const TitikPengguna())],
                    ),
                  MarkerLayer(
                    markers: [
                      for (var i = 0; i < daftar.length; i++)
                        Marker(
                          point: titik[i],
                          width: 44,
                          height: 44,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Navigator.pushNamed(context, AppRoutes.destinasiDetail, arguments: daftar[i].id),
                            child: PenandaBernomor(nomor: i + 1, destinasi: daftar[i]),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Positioned(left: 10, bottom: 6, child: AtribusiOsm(tersembunyi: false)),
            Positioned(
              left: 12,
              right: 12,
              bottom: 28,
              child: GlassPanel(
                radius: Radii.lg,
                blur: true,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            daftar.length < 2
                                ? '${daftar.length} perhentian'
                                : '${daftar.length} perhentian · total ±${formatJarak(_totalKm)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (daftar.isNotEmpty)
                          IconButton(
                            tooltip: 'Daftar perhentian',
                            visualDensity: VisualDensity.compact,
                            icon: Icon(Icons.format_list_numbered, color: scheme.primary),
                            onPressed: _bukaDaftar,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      daftar.length < 2
                          ? 'Tambahkan lebih banyak tempat untuk melihat urutan rute.'
                          : 'Jarak garis lurus antar titik, bukan jarak jalan. Rute jalan lewat Google Maps.',
                      style: TextStyle(fontSize: 12.5, height: 1.3, color: context.tripin.textSecondary),
                    ),
                    if (jarakAwal != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Dari posisimu ke perhentian 1: ${formatJarak(jarakAwal)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                    if (rute != null && rute.terpotong > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Google Maps hanya memuat ${rute.dipakai} perhentian pertama.',
                        style: TextStyle(fontSize: 12.5, color: scheme.error),
                      ),
                    ],
                    const SizedBox(height: 12),
                    GlassButton(
                      label: 'Buka rute di Google Maps',
                      icon: Icons.directions,
                      variant: GlassButtonVariant.prominent,
                      melebar: true,
                      onPressed: daftar.isEmpty ? null : _bukaRute,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DaftarPerhentian extends StatelessWidget {
  final List<Destinasi> daftar;
  final ValueChanged<Destinasi> onPilih;

  const _DaftarPerhentian({required this.daftar, required this.onPilih});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Urutan kunjungan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: daftar.length,
                itemBuilder: (context, i) {
                  final d = daftar[i];
                  final jarak = i == 0 ? null : jarakKm(daftar[i - 1].lat, daftar[i - 1].lng, d.lat, d.lng);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (jarak != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 13, top: 2, bottom: 2),
                          child: Text('↓ ±${formatJarak(jarak)} (garis lurus)', style: TextStyle(fontSize: 12, color: context.tripin.textSecondary)),
                        ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: scheme.primary,
                          child: Text('${i + 1}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: scheme.onPrimary)),
                        ),
                        title: Text(d.name),
                        subtitle: Text(d.location),
                        onTap: () => onPilih(d),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
