import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/destinasi_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/destinasi_card.dart';
import '../../widgets/kategori_chip.dart';
import '../../widgets/theme_toggle_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final searchController = TextEditingController();
  String? selectedKategoriId;

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
    final destinasiTerdekat = provider.destinasiTerdekat.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo, Traveler 👋',
              style: TextStyle(fontSize: 14, color: context.tripin.textSecondary),
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
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Keluar'),
                    content: const Text('Apakah kamu yakin ingin keluar dari akun?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Batal', style: TextStyle(color: context.tripin.textSecondary)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _logout();
                        },
                        child: const Text('Logout'),
                      ),
                    ],
                  );
                },
              );
            },
            icon: Icon(Icons.logout_outlined, color: context.colors.primary),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 5, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SEARCH
            Container(
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(17),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    color: context.tripin.softShadow,
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Cari tempat wisata...',
                  prefixIcon: Icon(Icons.search, color: context.colors.primary),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(17)),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(17)),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(17)),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // BANNER
            Container(
              height: 190,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1530789253388-582c481c54b0?auto=format&fit=crop&w=1000&q=80',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [Colors.black.withOpacity(0.65), Colors.transparent],
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jelajahi Keindahan\nSumatera Utara 🌿',
                      style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold, height: 1.2),
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

            // DESTINASI CARD
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.chat),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: context.tripin.softMint,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color: context.colors.primary,
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Icon(Icons.auto_awesome, color: context.colors.onPrimary, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bingung mau ke mana?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            'Tanya Asisten TRIPIN, kami bantu pilihkan.',
                            style: TextStyle(color: context.tripin.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: context.colors.primary),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // CATEGORY (sekarang benar-benar jadi filter)
            const Text('Kategori Wisata', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
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
                        onTap: () => setState(() => selectedKategoriId = kategori.id),
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
                const Text('Rekomendasi Untukmu', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.destinasiList),
                  child: const Text('Lihat Semua'),
                ),
              ],
            ),

            const SizedBox(height: 10),

            if (hasilPencarian.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text('Tidak ada destinasi yang cocok.', style: TextStyle(color: context.tripin.textSecondary)),
              )
            else
              SizedBox(
                height: 280,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: hasilPencarian.length > 6 ? 6 : hasilPencarian.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 15),
                  itemBuilder: (context, index) {
                    final destinasi = hasilPencarian[index];
                    return DestinasiCard(
                      destinasi: destinasi,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.destinasiDetail, arguments: destinasi.id),
                      onFavoriteTap: () => provider.toggleFavorit(destinasi.id),
                    );
                  },
                ),
              ),

            const SizedBox(height: 30),

            // NEARBY
            const Text('Wisata di Sekitar Kamu 📍', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              'Temukan tempat menarik yang dekat dengan lokasimu.',
              style: TextStyle(color: context.tripin.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 15),

            for (final destinasi in destinasiTerdekat) ...[
              DestinasiCard(
                destinasi: destinasi,
                dense: true,
                onTap: () => Navigator.pushNamed(context, AppRoutes.destinasiDetail, arguments: destinasi.id),
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