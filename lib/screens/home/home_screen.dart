import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/destinasi_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/destinasi_card.dart';
import '../../widgets/kategori_chip.dart';

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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo, Traveler 👋',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            SizedBox(height: 3),
            Text(
              'Mau pergi ke mana?',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
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
                        child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _logout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D6B),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  );
                },
              );
            },
            icon: const Icon(Icons.logout_outlined, color: Color(0xFF2E7D6B)),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(17),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    color: Colors.black.withOpacity(0.05),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Cari tempat wisata...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Color(0xFF2E7D6B)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(17)),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
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
              onTap: () => Navigator.pushNamed(context, AppRoutes.destinasiList),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4F0),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D6B),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bingung mau ke mana?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text(
                            'Jelajahi semua destinasi di TRIPIN.',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF2E7D6B)),
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
                    child: ChoiceChip(
                      label: const Text('Semua'),
                      selected: selectedKategoriId == null,
                      onSelected: (_) => setState(() => selectedKategoriId = null),
                      showCheckmark: false,
                      selectedColor: const Color(0xFF2E7D6B),
                      labelStyle: TextStyle(
                        color: selectedKategoriId == null ? Colors.white : const Color(0xFF2E7D6B),
                        fontWeight: FontWeight.w600,
                      ),
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
                  child: const Text('Lihat Semua', style: TextStyle(color: Color(0xFF2E7D6B))),
                ),
              ],
            ),

            const SizedBox(height: 10),

            if (hasilPencarian.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('Tidak ada destinasi yang cocok.', style: TextStyle(color: Colors.grey)),
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
            const Text(
              'Temukan tempat menarik yang dekat dengan lokasimu.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
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