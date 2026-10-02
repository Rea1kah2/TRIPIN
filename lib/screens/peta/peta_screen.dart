import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/destinasi.dart';
import '../../providers/destinasi_provider.dart';
import '../../providers/lokasi_provider.dart';
import '../../providers/review_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/location_service.dart';
import '../../services/rute.dart';
import '../../theme/app_colors.dart';
import '../../theme/kategori_warna.dart';
import '../../theme/radii.dart';
import '../../theme/typography.dart';
import '../../utils/geo.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/destinasi_image.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/glass_button.dart';
import '../../widgets/glass_insets.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/glass_scaffold.dart';
import '../../widgets/glass_sheet.dart';
import '../../widgets/pressable_scale.dart';
import '../../widgets/rating_stars.dart';

const _radiusPilihan = <double?>[null, 10, 25, 50, 100];
const _biru = Color(0xFF2F80ED);

/// Peta wisata Sumatera Utara: semua destinasi, posisi pengguna, filter kategori & radius,
/// pratinjau tempat, dan tombol rute. [aktif] = tab Peta sedang terlihat (pelacakan GPS
/// hanya menyala saat aktif).
class PetaScreen extends StatefulWidget {
  final bool aktif;

  /// Untuk tes: ganti pemuat ubin jaringan.
  final TileProvider? tileProvider;

  const PetaScreen({super.key, this.aktif = true, this.tileProvider});

  @override
  State<PetaScreen> createState() => _PetaScreenState();
}

class _PetaScreenState extends State<PetaScreen> {
  final _peta = MapController();
  late final LokasiProvider _lokasi;
  String? _kategoriId;
  double? _radiusKm;
  Destinasi? _terpilih;
  bool _petaSiap = false;
  bool _sudahMemusat = false;

  @override
  void initState() {
    super.initState();
    _lokasi = context.read<LokasiProvider>();
    _lokasi.addListener(_saatLokasiBerubah);
    if (widget.aktif) _aktifkan();
  }

  @override
  void didUpdateWidget(PetaScreen old) {
    super.didUpdateWidget(old);
    if (widget.aktif != old.aktif) {
      widget.aktif ? _aktifkan() : _lokasi.berhentiLacak();
    }
  }

  @override
  void dispose() {
    _lokasi.removeListener(_saatLokasiBerubah);
    _lokasi.berhentiLacak();
    _peta.dispose();
    super.dispose();
  }

  Future<void> _aktifkan() async {
    await _lokasi.muatAwal();
    if (mounted && widget.aktif) _lokasi.mulaiLacak();
  }

  void _saatLokasiBerubah() {
    // Pertama kali posisi diketahui: arahkan kamera ke pengguna.
    final p = _lokasi.posisi;
    if (p != null && _petaSiap && !_sudahMemusat) {
      _sudahMemusat = true;
      _peta.move(LatLng(p.lat, p.lng), 11);
    }
    if (mounted) setState(() {});
  }

  void _keLokasiku() {
    final p = _lokasi.posisi;
    if (p == null) {
      _lokasi.diizinkan ? _lokasi.segarkan() : _lokasi.aktifkan();
      return;
    }
    _peta.move(LatLng(p.lat, p.lng), 13);
  }

  void _pilih(Destinasi d) {
    setState(() => _terpilih = d);
    final zoom = _petaSiap ? _peta.camera.zoom : 10.0;
    _peta.move(LatLng(d.lat, d.lng), zoom < 10 ? 10 : zoom);
  }

  List<Destinasi> _terlihat(DestinasiProvider dp) {
    return dp.daftarDestinasi.where((d) {
      if (_kategoriId != null && d.kategoriId != _kategoriId) return false;
      final r = _radiusKm;
      if (r != null) {
        final j = _lokasi.jarakKe(d);
        if (j != null && j > r) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _rute(Destinasi d) async {
    final ok = await bukaRute(d);
    if (!ok && mounted) {
      showAppSnackbar(context, 'Tidak bisa membuka peta. Pastikan ada aplikasi peta atau browser.', isError: true);
    }
  }

  void _bukaDaftarTerdekat(List<Destinasi> terlihat) {
    showGlassSheet<void>(
      context,
      builder: (sheetContext) => _DaftarTerdekat(
        daftar: _lokasi.urutTerdekat(terlihat).take(12).toList(),
        onPilih: (d) {
          Navigator.pop(sheetContext);
          _pilih(d);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DestinasiProvider>();
    final lokasi = context.watch<LokasiProvider>();
    final scheme = context.colors;
    final gelap = Theme.of(context).brightness == Brightness.dark;
    final terlihat = _terlihat(dp);
    final inset = GlassInsets.bawahOf(context);
    final p = lokasi.posisi;

    final batas = LatLngBounds.fromPoints([for (final d in dp.daftarDestinasi) LatLng(d.lat, d.lng)]);

    return GlassScaffold(
      appBar: const GlassAppBar(judul: 'Peta Wisata'),
      body: ClipRect(
        child: Stack(
          children: [
            Positioned.fill(
              child: FlutterMap(
                mapController: _peta,
                options: MapOptions(
                  // Sisakan ruang untuk deretan filter di atas dan tombol/pratinjau di bawah.
                  initialCameraFit: CameraFit.bounds(
                    bounds: batas,
                    padding: EdgeInsets.fromLTRB(40, 130, 40, 150 + inset),
                  ),
                  minZoom: 5,
                  maxZoom: 18,
                  onMapReady: () {
                    _petaSiap = true;
                    _saatLokasiBerubah();
                  },
                  onTap: (_, __) => setState(() => _terpilih = null),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.tugas_kelompok',
                    tileProvider: widget.tileProvider,
                    tileBuilder: gelap ? darkModeTileBuilder : null,
                  ),
                  if (p != null && _radiusKm != null)
                    CircleLayer(circles: [
                      CircleMarker(
                        point: LatLng(p.lat, p.lng),
                        radius: _radiusKm! * 1000,
                        useRadiusInMeter: true,
                        color: scheme.primary.withOpacity(0.07),
                        borderColor: scheme.primary.withOpacity(0.6),
                        borderStrokeWidth: 1.5,
                      ),
                    ]),
                  if (p != null && p.akurasiMeter > 0)
                    CircleLayer(circles: [
                      CircleMarker(
                        point: LatLng(p.lat, p.lng),
                        radius: p.akurasiMeter,
                        useRadiusInMeter: true,
                        color: _biru.withOpacity(0.15),
                        borderColor: _biru.withOpacity(0.4),
                        borderStrokeWidth: 1,
                      ),
                    ]),
                  MarkerLayer(
                    markers: [
                      for (final d in terlihat)
                        if (d.id != _terpilih?.id)
                          Marker(
                            point: LatLng(d.lat, d.lng),
                            width: 44,
                            height: 44,
                            child: _Penanda(destinasi: d, dipilih: false, onTap: () => _pilih(d)),
                          ),
                      if (_terpilih != null)
                        Marker(
                          point: LatLng(_terpilih!.lat, _terpilih!.lng),
                          width: 56,
                          height: 56,
                          child: _Penanda(destinasi: _terpilih!, dipilih: true, onTap: () {}),
                        ),
                      if (p != null)
                        Marker(
                          point: LatLng(p.lat, p.lng),
                          width: 26,
                          height: 26,
                          child: const _TitikPengguna(),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Filter di atas peta.
            Positioned(
              top: 4,
              left: 0,
              right: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BarisFilter(
                    children: [
                      _ChipPeta(label: 'Semua', dipilih: _kategoriId == null, onTap: () => setState(() => _kategoriId = null)),
                      for (final k in dp.daftarKategori)
                        _ChipPeta(
                          label: k.nama,
                          ikon: k.icon,
                          dipilih: _kategoriId == k.id,
                          onTap: () => setState(() => _kategoriId = _kategoriId == k.id ? null : k.id),
                        ),
                    ],
                  ),
                  if (lokasi.adaPosisi)
                    _BarisFilter(
                      children: [
                        for (final r in _radiusPilihan)
                          _ChipPeta(
                            label: r == null ? 'Semua jarak' : '${r.round()} km',
                            ikon: r == null ? null : Icons.radar,
                            dipilih: _radiusKm == r,
                            onTap: () => setState(() => _radiusKm = r),
                          ),
                      ],
                    ),
                  if (!lokasi.diizinkan && lokasi.izin != null) _BannerIzin(lokasi: lokasi),
                ],
              ),
            ),
            // Atribusi OpenStreetMap (wajib oleh lisensi data).
            Positioned(
              left: 10,
              bottom: inset + (_terpilih == null ? 6 : 6),
              child: _Atribusi(tersembunyi: _terpilih != null),
            ),
            // Tombol kanan bawah + pratinjau.
            Positioned(
              left: 12,
              right: 12,
              bottom: inset + 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _TombolBulat(
                    tooltip: 'Daftar terdekat',
                    ikon: Icons.format_list_bulleted,
                    onTap: () => _bukaDaftarTerdekat(terlihat),
                  ),
                  const SizedBox(height: 10),
                  _TombolBulat(
                    tooltip: 'Ke lokasiku',
                    ikon: lokasi.sedangMencari ? Icons.hourglass_top : Icons.my_location,
                    onTap: _keLokasiku,
                  ),
                  if (_terpilih != null) ...[
                    const SizedBox(height: 10),
                    _KartuPratinjau(
                      destinasi: _terpilih!,
                      onTutup: () => setState(() => _terpilih = null),
                      onDetail: () => Navigator.pushNamed(context, AppRoutes.destinasiDetail, arguments: _terpilih!.id),
                      onRute: () => _rute(_terpilih!),
                    ),
                  ],
                ],
              ),
            ),
            if (terlihat.isEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: GlassPanel(
                      radius: Radii.lg,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      child: const Text('Tidak ada tempat di filter ini'),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BarisFilter extends StatelessWidget {
  final List<Widget> children;

  const _BarisFilter({required this.children});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => Center(child: children[i]),
      ),
    );
  }
}

/// Chip filter di atas peta: kapsul kaca (badan padat agar terbaca di atas peta apa pun).
class _ChipPeta extends StatelessWidget {
  final String label;
  final IconData? ikon;
  final bool dipilih;
  final VoidCallback onTap;

  const _ChipPeta({required this.label, this.ikon, required this.dipilih, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final warna = dipilih ? scheme.onPrimary : scheme.onSurface;
    return Semantics(
      button: true,
      selected: dipilih,
      label: label,
      child: PressableScale(
        onTap: onTap,
        skala: 0.96,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Center(
            child: GlassPanel(
              radius: 999,
              accent: dipilih,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (ikon != null) ...[
                    Icon(ikon, size: 16, color: warna),
                    const SizedBox(width: 6),
                  ],
                  Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: warna)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Penanda extends StatelessWidget {
  final Destinasi destinasi;
  final bool dipilih;
  final VoidCallback onTap;

  const _Penanda({required this.destinasi, required this.dipilih, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final warna = warnaKategori(destinasi.kategoriId, b);
    final kategori = context.read<DestinasiProvider>().daftarKategori.where((k) => k.id == destinasi.kategoriId);
    final ikon = kategori.isEmpty ? Icons.place : kategori.first.icon;
    final ukuran = dipilih ? 46.0 : 34.0;
    return Semantics(
      button: true,
      label: destinasi.name,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: ukuran,
            height: ukuran,
            decoration: BoxDecoration(
              color: warna,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: dipilih ? 3 : 2),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: dipilih ? 10 : 5, offset: const Offset(0, 2))],
            ),
            child: Icon(ikon, size: dipilih ? 24 : 18, color: b == Brightness.dark ? const Color(0xFF10201A) : Colors.white),
          ),
        ),
      ),
    );
  }
}

class _TitikPengguna extends StatelessWidget {
  const _TitikPengguna();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Posisimu sekarang',
      child: Container(
        decoration: BoxDecoration(
          color: _biru,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 6)],
        ),
      ),
    );
  }
}

class _TombolBulat extends StatelessWidget {
  final String tooltip;
  final IconData ikon;
  final VoidCallback onTap;

  const _TombolBulat({required this.tooltip, required this.ikon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: PressableScale(
        onTap: onTap,
        skala: 0.94,
        child: GlassPanel(
          radius: 26,
          blur: true,
          bias: 0.25,
          padding: EdgeInsets.zero,
          child: SizedBox(width: 52, height: 52, child: Icon(ikon, color: context.colors.primary)),
        ),
      ),
    );
  }
}

class _BannerIzin extends StatelessWidget {
  final LokasiProvider lokasi;

  const _BannerIzin({required this.lokasi});

  @override
  Widget build(BuildContext context) {
    final perluPengaturan = lokasi.izin == IzinLokasi.ditolakPermanen || lokasi.izin == IzinLokasi.layananMati;
    final teks = lokasi.izin == IzinLokasi.layananMati
        ? 'Layanan lokasi HP sedang mati.'
        : lokasi.izin == IzinLokasi.ditolakPermanen
            ? 'Izin lokasi ditolak.'
            : 'Aktifkan lokasi untuk melihat posisimu dan jarak ke tiap tempat.';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: GlassPanel(
        radius: Radii.lg,
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        child: Row(
          children: [
            Icon(Icons.location_off_outlined, color: context.colors.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(teks, style: const TextStyle(fontSize: 13, height: 1.3))),
            TextButton(
              onPressed: () => perluPengaturan ? lokasi.bukaPengaturan() : lokasi.aktifkan(),
              child: Text(perluPengaturan ? 'Pengaturan' : 'Aktifkan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Atribusi extends StatelessWidget {
  final bool tersembunyi;

  const _Atribusi({required this.tersembunyi});

  @override
  Widget build(BuildContext context) {
    if (tersembunyi) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse('https://www.openstreetmap.org/copyright'), mode: LaunchMode.externalApplication),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.75),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('© OpenStreetMap', style: TextStyle(fontSize: 10, color: Colors.black87)),
      ),
    );
  }
}

class _KartuPratinjau extends StatelessWidget {
  final Destinasi destinasi;
  final VoidCallback onTutup;
  final VoidCallback onDetail;
  final VoidCallback onRute;

  const _KartuPratinjau({
    required this.destinasi,
    required this.onTutup,
    required this.onDetail,
    required this.onRute,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final tripin = context.tripin;
    final jarak = context.watch<LokasiProvider>().jarakKe(destinasi);
    final rating = context.watch<ReviewProvider>().ratingTampil(destinasi);
    final kategori = context
        .read<DestinasiProvider>()
        .daftarKategori
        .where((k) => k.id == destinasi.kategoriId)
        .map((k) => k.nama)
        .firstOrNull;
    final warna = warnaKategori(destinasi.kategoriId, Theme.of(context).brightness);

    return GlassPanel(
      radius: Radii.xl,
      blur: true,
      bias: 0.2,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(konsentris(Radii.xl, 12)),
                child: DestinasiImage(aset: destinasi.fotoUtama, width: 78, height: 78),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destinasi.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.2),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(width: 9, height: 9, decoration: BoxDecoration(color: warna, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${kategori ?? ''} · ${destinasi.location}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, color: tripin.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        RatingStars(rating: rating, size: 14),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            jarak == null ? 'Lokasi belum aktif' : '${formatJarak(jarak)} dari kamu',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: angkaTabular.copyWith(fontSize: 12, color: scheme.primary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    if (destinasi.lokasiPerkiraan)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('Titik perkiraan (mewakili area)', style: TextStyle(fontSize: 11, color: tripin.textSecondary)),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Tutup',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, size: 20),
                onPressed: onTutup,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GlassButton(label: 'Detail', variant: GlassButtonVariant.plain, melebar: true, onPressed: onDetail),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GlassButton(
                  label: 'Rute',
                  icon: Icons.directions,
                  variant: GlassButtonVariant.prominent,
                  melebar: true,
                  onPressed: onRute,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DaftarTerdekat extends StatelessWidget {
  final List<Destinasi> daftar;
  final ValueChanged<Destinasi> onPilih;

  const _DaftarTerdekat({required this.daftar, required this.onPilih});

  @override
  Widget build(BuildContext context) {
    final lokasi = context.watch<LokasiProvider>();
    final tripin = context.tripin;
    final b = Theme.of(context).brightness;

    if (!lokasi.adaPosisi) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_searching, size: 32, color: context.colors.primary),
            const SizedBox(height: 10),
            const Text('Lokasimu belum diketahui', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              'Aktifkan lokasi untuk melihat tempat wisata terdekat dari posisimu.',
              textAlign: TextAlign.center,
              style: TextStyle(color: tripin.textSecondary),
            ),
            const SizedBox(height: 16),
            GlassButton(
              label: 'Aktifkan lokasi',
              variant: GlassButtonVariant.prominent,
              onPressed: () {
                Navigator.pop(context);
                lokasi.aktifkan();
              },
            ),
          ],
        ),
      );
    }

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: Text('Terdekat dari kamu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        ),
        for (final d in daftar)
          ListTile(
            onTap: () => onPilih(d),
            minVerticalPadding: 10,
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: warnaKategori(d.kategoriId, b), shape: BoxShape.circle),
              child: Icon(Icons.place, size: 20, color: b == Brightness.dark ? const Color(0xFF10201A) : Colors.white),
            ),
            title: Text(d.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(d.location, style: TextStyle(color: tripin.textSecondary)),
            trailing: Text(
              formatJarak(lokasi.jarakKe(d)!),
              style: angkaTabular.copyWith(color: context.colors.primary, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }
}
