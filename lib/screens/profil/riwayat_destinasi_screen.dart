
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/destinasi_provider.dart';
import '../../models/destinasi.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/radii.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/glass_scaffold.dart';
import '../../widgets/app_snackbar.dart';

class RiwayatDestinasiScreen extends StatefulWidget {
  const RiwayatDestinasiScreen({super.key});

  @override
  State<RiwayatDestinasiScreen> createState() =>
      _RiwayatDestinasiScreenState();
}

class _RiwayatDestinasiScreenState
    extends State<RiwayatDestinasiScreen> {
  bool _memuat = true;

  @override
  void initState() {
    super.initState();
    _muatRiwayat();
  }

  Future<void> _muatRiwayat() async {
    final userId = context.read<AuthProvider>().currentUser?.id;

    if (userId != null) {
      await context
          .read<DestinasiProvider>()
          .muatRiwayatKunjungan(userId);
    }

    if (!mounted) return;

    setState(() {
      _memuat = false;
    });
  }

  String _formatTanggal(DateTime tanggal) {
    const bulan = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return '${tanggal.day} ${bulan[tanggal.month - 1]} ${tanggal.year}';
  }

  Future<void> _hapusRiwayat(
      String userId,
      Destinasi destinasi,
      ) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Riwayat?'),
          content: Text(
            'Apakah kamu yakin ingin menghapus '
                '${destinasi.name} dari riwayat kunjungan?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'Hapus',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (konfirmasi != true || !mounted) return;

    await context
        .read<DestinasiProvider>()
        .batalkanKunjungan(userId, destinasi.id);

    if (!mounted) return;

    showAppSnackbar(
      context,
      'Riwayat ${destinasi.name} berhasil dihapus.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DestinasiProvider>();
    final userId = context.watch<AuthProvider>().currentUser?.id;

    final daftarRiwayat = provider.daftarRiwayatKunjungan;

    return GlassScaffold(
      appBar: const GlassAppBar(
        judul: 'Riwayat Destinasi',
      ),
      body: _memuat
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : userId == null
          ? const Center(
        child: Text('Silakan login terlebih dahulu.'),
      )
          : daftarRiwayat.isEmpty
          ? _tampilanKosong(context)
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: daftarRiwayat.length,
        separatorBuilder: (_, __) =>
        const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final destinasi = daftarRiwayat[index];

          final tanggal =
          provider.tanggalKunjungan(destinasi.id);

          return _KartuRiwayat(
            destinasi: destinasi,
            tanggal: tanggal == null
                ? '-'
                : _formatTanggal(tanggal),
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.destinasiDetail,
                arguments: destinasi.id,
              );
            },
            onHapus: () {
              _hapusRiwayat(userId, destinasi);
            },
          );
        },
      ),
    );
  }

  Widget _tampilanKosong(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 76,
              color: context.colors.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Riwayat Destinasi',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Destinasi yang sudah kamu kunjungi '
                  'dan tandai akan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.tripin.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KartuRiwayat extends StatelessWidget {
  final Destinasi destinasi;
  final String tanggal;
  final VoidCallback onTap;
  final VoidCallback onHapus;

  const _KartuRiwayat({
    required this.destinasi,
    required this.tanggal,
    required this.onTap,
    required this.onHapus,
  });

  @override
  Widget build(BuildContext context) {
    final String? foto = destinasi.fotoUtama;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.lg),
      child: GlassPanel(
        radius: Radii.lg,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 100,
                height: 100,
                child: foto != null && foto.isNotEmpty
                    ? Image.asset(
                  foto,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return _gambarPengganti(context);
                  },
                )
                    : _gambarPengganti(context),
              ),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 15,
                        color: context.tripin.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          destinasi.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.tripin.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        size: 15,
                        color: context.colors.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          tanggal,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Hapus riwayat',
              onPressed: onHapus,
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gambarPengganti(BuildContext context) {
    return Container(
      color: context.colors.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        size: 35,
        color: context.tripin.textSecondary,
      ),
    );
  }
}
