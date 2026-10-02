import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/theme_toggle_button.dart';

class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final primary = context.colors.primary;
    final tripin = context.tripin;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  color: tripin.softShadow,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: tripin.paleMint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, size: 36, color: primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.nama ?? 'Traveler',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '-',
                        style: TextStyle(color: tripin.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _TampilanTile(),
          const SizedBox(height: 12),
          _MenuItem(
            icon: Icons.map_outlined,
            label: 'Rencana Perjalanan Saya',
            onTap: () => Navigator.pushNamed(context, AppRoutes.rencanaList),
          ),
          const SizedBox(height: 12),
          _MenuItem(
            icon: Icons.favorite_border,
            label: 'Destinasi Favorit',
            onTap: () {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('Buka tab Favorit di bawah untuk melihatnya')),
              );
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tentang TRIPIN', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  'TRIPIN adalah aplikasi discovery & perencana wisata Sumatera Utara. '
                  'Dibangun sebagai tugas kelompok mata kuliah Pemrograman Mobile.',
                  style: TextStyle(color: tripin.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                context.read<AuthProvider>().logout();
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
              },
              icon: Icon(Icons.logout, color: context.colors.error),
              label: Text('Keluar', style: TextStyle(color: context.colors.error)),
              style: OutlinedButton.styleFrom(side: BorderSide(color: context.colors.error)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tile "Tampilan": switch terang/gelap + pilihan Sistem/Terang/Gelap.
class _TampilanTile extends StatelessWidget {
  const _TampilanTile();

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeProvider>().themeMode;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, color: context.colors.primary),
              const SizedBox(width: 12),
              const Expanded(child: Text('Mode Gelap')),
              const ThemeToggleButton(pill: true),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('Sistem')),
                ButtonSegment(value: ThemeMode.light, label: Text('Terang')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Gelap')),
              ],
              selected: {mode},
              onSelectionChanged: (pilihan) =>
                  context.read<ThemeProvider>().setThemeMode(pilihan.first),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: context.colors.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(label)),
            Icon(Icons.arrow_forward_ios, size: 14, color: context.tripin.textSecondary),
          ],
        ),
      ),
    );
  }
}
