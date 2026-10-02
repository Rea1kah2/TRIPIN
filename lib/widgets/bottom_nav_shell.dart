import 'package:flutter/material.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/destinasi/daftar_destinasi_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/peta/peta_screen.dart';
import '../screens/profil/profil_screen.dart';
import 'glass_insets.dart';
import 'glass_tab_bar.dart';

class BottomNavShell extends StatefulWidget {
  const BottomNavShell({super.key});

  @override
  State<BottomNavShell> createState() => _BottomNavShellState();
}

class _BottomNavShellState extends State<BottomNavShell> {
  int _selectedIndex = 0;

  static const _items = [
    GlassTabItem(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Beranda'),
    GlassTabItem(icon: Icons.explore_outlined, selectedIcon: Icons.explore, label: 'Jelajah'),
    GlassTabItem(icon: Icons.map_outlined, selectedIcon: Icons.map, label: 'Peta'),
    GlassTabItem(icon: Icons.auto_awesome_outlined, selectedIcon: Icons.auto_awesome, label: 'Tripy'),
    GlassTabItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    // Dibaca di atas Scaffold: Scaffold menghapus viewInsets dari MediaQuery anaknya.
    final keyboardTerbuka = MediaQuery.viewInsetsOf(context).bottom > 0;
    final inset = keyboardTerbuka ? 0.0 : GlassTabBar.tinggiTotal(context);

    return Scaffold(
      body: GlassInsets(
        bawah: inset,
        child: Stack(
          children: [
            Positioned.fill(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  const HomePage(),
                  const DaftarDestinasiScreen(),
                  // Pelacakan GPS hanya hidup saat tab Peta terlihat.
                  PetaScreen(aktif: _selectedIndex == 2),
                  const ChatScreen(embedded: true),
                  const ProfilScreen(),
                ],
              ),
            ),
            if (!keyboardTerbuka)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: GlassTabBar(
                  items: _items,
                  index: _selectedIndex,
                  onSelect: (i) => setState(() => _selectedIndex = i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
