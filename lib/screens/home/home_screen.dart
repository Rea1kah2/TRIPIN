import 'package:flutter/material.dart';
import '../../widgets/category_item.dart';
import '../../widgets/destination_card.dart';
import '../../widgets/nearby_card.dart';
import '../auth/login_screen.dart';

// ======================================================
// HOME PAGE / BERANDA
// ======================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Set<String> favoritePlaces = {};

  void toggleFavorite(String place) {
    setState(() {
      if (favoritePlaces.contains(place)) {
        favoritePlaces.remove(place);
      } else {
        favoritePlaces.add(place);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Mau pergi ke mana?',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          // tombol logout
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Keluar'),
                    content: const Text(
                      'Apakah kamu yakin ingin keluar dari akun?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);

                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                                (route) => false,
                          );
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
            icon: const Icon(
              Icons.logout_outlined,
              color: Color(0xFF2E7D6B),
            ),
            tooltip: 'Logout',
          ),

          // icon profil yang sebelumnya
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: CircleAvatar(
              backgroundColor: const Color(0xFFE1F1EC),
              child: IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF2E7D6B),
                ),
              ),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 5, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // SEARCH
            // ==================================================

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
                decoration: InputDecoration(
                  hintText: 'Cari tempat wisata...',
                  hintStyle: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF2E7D6B),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.tune),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(17),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // ==================================================
            // BANNER
            // ==================================================

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
                    colors: [
                      Colors.black.withOpacity(0.65),
                      Colors.transparent,
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
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Temukan destinasi menarik untuk perjalananmu.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ==================================================
            // AI CARD
            // ==================================================

            Container(
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
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 14),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bingung mau ke mana?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tanya TRIPIN AI untuk rekomendasi wisata.',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Color(0xFF2E7D6B),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ==================================================
            // CATEGORY
            // ==================================================

            const Text(
              'Kategori Wisata',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              height: 95,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  CategoryItem(
                    icon: Icons.forest_outlined,
                    title: 'Alam',
                  ),
                  CategoryItem(
                    icon: Icons.beach_access_outlined,
                    title: 'Pantai',
                  ),
                  CategoryItem(
                    icon: Icons.museum_outlined,
                    title: 'Budaya',
                  ),
                  CategoryItem(
                    icon: Icons.restaurant_outlined,
                    title: 'Kuliner',
                  ),
                  CategoryItem(
                    icon: Icons.hiking_outlined,
                    title: 'Adventure',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ==================================================
            // RECOMMENDATION
            // ==================================================

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Rekomendasi Untukmu',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Lihat Semua',
                    style: TextStyle(
                      color: Color(0xFF2E7D6B),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 280,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  DestinationCard(
                    name: 'Danau Toba',
                    location: 'Sumatera Utara',
                    rating: '4.8',
                    price: 'Rp 20.000',
                    imageUrl:
                    'https://images.unsplash.com/photo-1604999333679-b86d54738315?auto=format&fit=crop&w=700&q=80',
                    isFavorite:
                    favoritePlaces.contains('Danau Toba'),
                    onFavorite: () {
                      toggleFavorite('Danau Toba');
                    },
                  ),

                  const SizedBox(width: 15),

                  DestinationCard(
                    name: 'Bukit Lawang',
                    location: 'Langkat',
                    rating: '4.7',
                    price: 'Rp 15.000',
                    imageUrl:
                    'https://images.unsplash.com/photo-1516026672322-bc52d61a55d5?auto=format&fit=crop&w=700&q=80',
                    isFavorite:
                    favoritePlaces.contains('Bukit Lawang'),
                    onFavorite: () {
                      toggleFavorite('Bukit Lawang');
                    },
                  ),

                  const SizedBox(width: 15),

                  DestinationCard(
                    name: 'Berastagi',
                    location: 'Karo',
                    rating: '4.6',
                    price: 'Rp 10.000',
                    imageUrl:
                    'https://images.unsplash.com/photo-1500534623283-312aade485b7?auto=format&fit=crop&w=700&q=80',
                    isFavorite:
                    favoritePlaces.contains('Berastagi'),
                    onFavorite: () {
                      toggleFavorite('Berastagi');
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ==================================================
            // NEARBY
            // ==================================================

            const Text(
              'Wisata di Sekitar Kamu 📍',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Temukan tempat menarik yang dekat dengan lokasimu.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 15),

            NearbyCard(
              name: 'Taman Cadika',
              location: 'Medan',
              distance: '3.2 km',
              imageUrl:
              'https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?auto=format&fit=crop&w=700&q=80',
            ),

            const SizedBox(height: 12),

            NearbyCard(
              name: 'Istana Maimun',
              location: 'Medan',
              distance: '5.1 km',
              imageUrl:
              'https://images.unsplash.com/photo-1564507592333-c60657eea523?auto=format&fit=crop&w=700&q=80',
            ),
          ],
        ),
      ),

      // ==================================================
      // BOTTOM NAVIGATION
      // ==================================================

      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE1F1EC),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Jelajah',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorit',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
