import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/destinasi_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/destinasi_card.dart';
import '../../widgets/kategori_chip.dart';
import '../../widgets/theme_toggle_button.dart';
import '../../widgets/glass_scaffold.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/glass_insets.dart';
import '../../widgets/glass_alert.dart';
import '../../widgets/pressable_scale.dart';
import '../../widgets/glass_panel.dart';
import '../../theme/radii.dart';
import '../../providers/lokasi_provider.dart';
import '../../services/location_service.dart';
import '../../widgets/glass_button.dart';

final _bentukCari = OutlineInputBorder(
  borderRadius: BorderRadius.circular(999),
  borderSide: BorderSide.none,
);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final searchController = TextEditingController();
  String? selectedKategoriId;

  @override
  void initState() {
    super.initState();
    // Cek izin lokasi tanpa dialog; bila sudah diizinkan, ambil posisi sekali untuk jarak nyata.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<LokasiProvider>().muatAwal();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _logout() {
    context.read<AuthProvider>().logout();
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DestinasiProvider>();
    final hasilPencarian = provider.cari(
      query: searchController.text,
      kategoriId: selectedKategoriId,
    );
    final lokasi = context.watch<LokasiProvider>();
    final destinasiTerdekat =
        lokasi.urutTerdekat(provider.daftarDestinasi).take(3).toList();

    return GlassScaffold(
      appBar: GlassAppBar(
        tinggi: 68,
        paddingKiri: 28,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo, Traveler 👋',
              style:
                  TextStyle(fontSize: 14, color: context.tripin.textSecondary),
            ),
            const SizedBox(height: 3),
            const Text(
              'Mau pergi ke mana?',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            onPressed: () async {
              final keluar = await showGlassAlert<bool>(
                context,
                judul: 'Keluar',
                pesan: 'Apakah kamu yakin ingin keluar dari akun?',
                aksi: const [
                  GlassAlertAksi(label: 'Batal', nilai: false, utama: true),
                  GlassAlertAksi(
                      label: 'Keluar', nilai: true, destruktif: true),
                ],
              );
              if (keluar == true && mounted) _logout();
            },
            icon: Icon(Icons.logout_outlined, color: context.colors.primary),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding:
            EdgeInsets.fromLTRB(20, 12, 20, 30 + GlassInsets.bawahOf(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SEARCH: input memakai fill (bukan kaca), bentuk kapsul.
            TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Cari tempat wisata...',
                fillColor: context.colors.onSurface.withOpacity(0.07),
                prefixIcon: Icon(Icons.search, color: context.colors.primary),
                border: _bentukCari,
                enabledBorder: _bentukCari,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide:
                      BorderSide(color: context.colors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 25),

            // BANNER
            Container(
              height: 190,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Radii.xl),
                image: const DecorationImage(
                  image: AssetImage('assets/destinasi/banner/1.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Radii.xl),
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [
                      Colors.black.withOpacity(0.65),
                      Colors.transparent
                    ],
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jelajahi Keindahan\nSumatera Utara 🌿',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          height: 1.2),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Temukan destinasi menarik untuk perjalananmu.',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // KARTU TRIPY: kartu sorotan (kaca bertepi warna utama)
            Semantics(
              button: true,
              label: 'Bingung mau ke mana? Tanya Tripy',
              child: PressableScale(
                onTap: () => Navigator.pushNamed(context, AppRoutes.chat),
                child: GlassPanel(
                  radius: Radii.xl,
                  padding: const EdgeInsets.all(18),
                  rimColor: context.colors.primary.withOpacity(0.5),
                  child: Row(
                    children: [
                      Container(
                        width: 55,
                        height: 55,
                        decoration: BoxDecoration(
                          color: context.colors.primary,
                          borderRadius: BorderRadius.circular(
                              konsentris(Radii.xl, 18) + 4),
                        ),
                        child: Icon(Icons.auto_awesome,
                            color: context.colors.onPrimary, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Bingung mau ke mana?',
                                style: TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(
                              'Tanya Tripy, nanti dibantuin pilih tempatnya.',
                              style: TextStyle(
                                  color: context.tripin.textSecondary,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          size: 16, color: context.colors.primary),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // CATEGORY (sekarang benar-benar jadi filter)
            const Text('Kategori Wisata',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SemuaChip(
                      selected: selectedKategoriId == null,
                      onTap: () => setState(() => selectedKategoriId = null),
                    ),
                  ),
                  for (final kategori in provider.daftarKategori)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: KategoriChip(
                        kategori: kategori,
                        selected: selectedKategoriId == kategori.id,
                        onTap: () =>
                            setState(() => selectedKategoriId = kategori.id),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // REKOMENDASI (sekarang dari hasil pencarian/filter sungguhan)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Rekomendasi Untukmu',
                    style:
                        TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.destinasiList),
                  child: const Text('Lihat Semua'),
                ),
              ],
            ),

            const SizedBox(height: 10),

            if (hasilPencarian.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text('Tidak ada destinasi yang cocok.',
                    style: TextStyle(color: context.tripin.textSecondary)),
              )
            else
              SizedBox(
                height: 296,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount:
                      hasilPencarian.length > 6 ? 6 : hasilPencarian.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 15),
                  itemBuilder: (context, index) {
                    final destinasi = hasilPencarian[index];
                    return DestinasiCard(
                      destinasi: destinasi,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.destinasiDetail,
                          arguments: destinasi.id),
                      onFavoriteTap: () => provider.toggleFavorit(destinasi.id),
                    );
                  },
                ),
              ),

            const SizedBox(height: 30),

            // NEARBY
            const Text('Wisata di Sekitar Kamu 📍',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              'Temukan tempat menarik yang dekat dengan lokasimu.',
              style:
                  TextStyle(color: context.tripin.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 15),

            if (!lokasi.adaPosisi)
              _AjakanLokasi(lokasi: lokasi)
            else
              for (final destinasi in destinasiTerdekat) ...[
                DestinasiCard(
                  destinasi: destinasi,
                  dense: true,
                  onTap: () => Navigator.pushNamed(
                      context, AppRoutes.destinasiDetail,
                      arguments: destinasi.id),
                  onFavoriteTap: () => provider.toggleFavorit(destinasi.id),
                ),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }
}

/// Ajakan mengaktifkan lokasi (menggantikan jarak palsu): jelaskan manfaatnya dan beri aksi.
class _AjakanLokasi extends StatelessWidget {
  final LokasiProvider lokasi;

  const _AjakanLokasi({required this.lokasi});

  @override
  Widget build(BuildContext context) {
    final ditolakPermanen = lokasi.izin == IzinLokasi.ditolakPermanen;
    final layananMati = lokasi.izin == IzinLokasi.layananMati;
    final pesan = layananMati
        ? 'Layanan lokasi di HP sedang mati. Nyalakan agar Tripy bisa menunjukkan tempat terdekat.'
        : ditolakPermanen
            ? 'Izin lokasi ditolak. Buka pengaturan aplikasi untuk mengizinkannya.'
            : 'Aktifkan lokasi untuk melihat tempat wisata terdekat dan jarak sebenarnya dari posisimu.';
    return GlassPanel(
      radius: Radii.lg,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_searching, color: context.colors.primary),
              const SizedBox(width: 10),
              const Expanded(
                  child: Text('Lokasi belum aktif',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16))),
            ],
          ),
          const SizedBox(height: 8),
          Text(pesan,
              style:
                  TextStyle(color: context.tripin.textSecondary, height: 1.4)),
          const SizedBox(height: 14),
          GlassButton(
            label: lokasi.sedangMencari
                ? 'Mencari posisi…'
                : (ditolakPermanen || layananMati
                    ? 'Buka pengaturan'
                    : 'Aktifkan lokasi'),
            icon: Icons.my_location,
            onPressed: lokasi.sedangMencari
                ? null
                : () => (ditolakPermanen || layananMati)
                    ? lokasi.bukaPengaturan()
                    : lokasi.aktifkan(),
          ),
        ],
      ),
    );
  }
}
