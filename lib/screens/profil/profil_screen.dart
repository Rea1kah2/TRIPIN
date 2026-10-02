import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/radii.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/glass_button.dart';
import '../../widgets/glass_insets.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/glass_scaffold.dart';
import '../../widgets/pressable_scale.dart';
import '../../widgets/theme_toggle_button.dart';
import '../destinasi/favorit_screen.dart';
import 'kredit_foto_screen.dart';

class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final primary = context.colors.primary;
    final tripin = context.tripin;

    return GlassScaffold(
      appBar: const GlassAppBar(judul: 'Profil'),
      body: ListView(
        padding:
            EdgeInsets.fromLTRB(20, 12, 20, 20 + GlassInsets.bawahOf(context)),
        children: [
          GlassPanel(
            radius: Radii.xl,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                      color: tripin.paleMint, shape: BoxShape.circle),
                  child: Icon(Icons.person, size: 36, color: primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.nama ?? 'Traveler',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w600),
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
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavoritScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _MenuItem(
            icon: Icons.photo_library_outlined,
            label: 'Kredit Foto',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const KreditFotoScreen()),
            ),
          ),
          const SizedBox(height: 12),
          GlassPanel(
            radius: Radii.lg,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tentang TRIPIN',
                    style: TextStyle(fontWeight: FontWeight.w600)),
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
          GlassButton(
            label: 'Keluar',
            icon: Icons.logout,
            variant: GlassButtonVariant.destructive,
            melebar: true,
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pushNamedAndRemoveUntil(
                  context, AppRoutes.login, (route) => false);
            },
          ),
        ],
      ),
    );
  }
}

/// Grup "Tampilan" (permukaan solid ala pengaturan iOS): mode tema, transparansi kaca,
/// dan toggle Kurangi transparansi.
class _TampilanTile extends StatelessWidget {
  const _TampilanTile();

  @override
  Widget build(BuildContext context) {
    final tema = context.watch<ThemeProvider>();
    final scheme = context.colors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, color: scheme.primary),
              const SizedBox(width: 12),
              const Expanded(
                  child: Text('Mode Gelap',
                      style: TextStyle(fontWeight: FontWeight.w500))),
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
              selected: {tema.themeMode},
              onSelectionChanged: (pilihan) =>
                  context.read<ThemeProvider>().setThemeMode(pilihan.first),
            ),
          ),
          const SizedBox(height: 18),
          Divider(height: 1, color: scheme.outlineVariant),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.blur_on, color: scheme.primary),
              const SizedBox(width: 12),
              const Expanded(
                  child: Text('Transparansi kaca',
                      style: TextStyle(fontWeight: FontWeight.w500))),
              Text(
                '${(tema.glassIntensity * 100).round()}%',
                style: TextStyle(
                    color: context.tripin.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ],
          ),
          Slider(
            value: tema.glassIntensity,
            semanticFormatterCallback: (v) => '${(v * 100).round()} persen',
            onChanged: tema.reduceTransparency
                ? null
                : (v) => context
                    .read<ThemeProvider>()
                    .setGlassIntensity(v, simpan: false),
            onChangeEnd: (_) =>
                context.read<ThemeProvider>().simpanGlassIntensity(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Bening',
                  style: TextStyle(
                      fontSize: 12, color: context.tripin.textSecondary)),
              Text('Tebal',
                  style: TextStyle(
                      fontSize: 12, color: context.tripin.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          const _PratinjauKaca(),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Kurangi transparansi',
                style: TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(
              'Ganti kaca dengan permukaan solid agar lebih mudah dibaca.',
              style:
                  TextStyle(fontSize: 12, color: context.tripin.textSecondary),
            ),
            value: tema.reduceTransparency,
            onChanged: (v) =>
                context.read<ThemeProvider>().setReduceTransparency(v),
          ),
        ],
      ),
    );
  }
}

/// Pratinjau langsung: panel kaca di atas latar berwarna agar efek slider terlihat.
class _PratinjauKaca extends StatelessWidget {
  const _PratinjauKaca();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.md),
        child: Container(
          height: 84,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              scheme.primary,
              scheme.primary.withOpacity(0.35),
              scheme.tertiary
            ]),
          ),
          alignment: Alignment.center,
          child: const GlassPanel(
            blur: true,
            radius: Radii.lg,
            padding: EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            child: Text('Pratinjau kaca',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: PressableScale(
        onTap: onTap,
        child: GlassPanel(
          radius: Radii.lg,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: context.colors.primary),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(label,
                      style: const TextStyle(fontWeight: FontWeight.w500))),
              Icon(Icons.arrow_forward_ios,
                  size: 14, color: context.tripin.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
