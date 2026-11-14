import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/destinasi.dart';
import '../../providers/auth_provider.dart';
import '../../providers/destinasi_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/radii.dart';
import '../../theme/typography.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/confirm_delete_dialog.dart';
import '../../widgets/destinasi_image.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/glass_insets.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/glass_scaffold.dart';
import '../../widgets/keadaan_kosong.dart';
import '../../widgets/pressable_scale.dart';

class RiwayatDestinasiScreen extends StatefulWidget {
  const RiwayatDestinasiScreen({super.key});

  @override
  State<RiwayatDestinasiScreen> createState() =>
      _RiwayatDestinasiScreenState();
}

class _RiwayatDestinasiScreenState extends State<RiwayatDestinasiScreen> {
  bool _memuat = true;

  @override
  void initState() {
    super.initState();
    _muatRiwayat();
  }

  Future<void> _muatRiwayat() async {
    String? userId;
    try {
      userId = context.read<AuthProvider>().currentUser?.id;
    } on ProviderNotFoundException {
      userId = null;
    }

    if (userId != null) {
      await context.read<DestinasiProvider>().muatRiwayatKunjungan(userId);
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
    final konfirmasi = await showConfirmDeleteDialog(
      context,
      judul: 'Riwayat ${destinasi.name}',
    );

    if (!konfirmasi || !mounted) return;

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
    String? userId;
    try {
      userId = context.watch<AuthProvider>().currentUser?.id;
    } on ProviderNotFoundException {
      userId = null;
    }

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
              ? const KeadaanKosong(
                  ikon: Icons.lock_outline_rounded,
                  judul: 'Masuk terlebih dahulu',
                  pesan: 'Riwayat kunjungan tersimpan di akunmu.',
                )
              : daftarRiwayat.isEmpty
                  ? KeadaanKosong(
                      ikon: Icons.history_rounded,
                      judul: 'Belum Ada Riwayat Destinasi',
                      pesan:
                          'Tandai destinasi yang sudah pernah kamu kunjungi di halaman detail wisata.',
                      labelAksi: 'Jelajahi Destinasi',
                      onAksi: () => Navigator.pushNamed(
                        context,
                        AppRoutes.pencarianRekomendasi,
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        24 + GlassInsets.bawahOf(context),
                      ),
                      itemCount: daftarRiwayat.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final destinasi = daftarRiwayat[index];
                        final tanggal = provider.tanggalKunjungan(destinasi.id);

                        return _KartuRiwayat(
                          destinasi: destinasi,
                          tanggal:
                              tanggal == null ? '-' : _formatTanggal(tanggal),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.destinasiDetail,
                              arguments: destinasi.id,
                            );
                          },
                          onHapus: () {
                            _hapusRiwayat(userId!, destinasi);
                          },
                        );
                      },
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
    final radiusFoto = konsentris(Radii.lg, 10);

    return PressableScale(
      onTap: onTap,
      child: GlassPanel(
        radius: Radii.lg,
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(radiusFoto),
              child: DestinasiImage(
                aset: destinasi.fotoUtama,
                width: 96,
                height: 96,
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
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
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
                        size: 14,
                        color: context.colors.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          tanggal,
                          style: angkaTabular.copyWith(
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
              tooltip: 'Hapus riwayat ${destinasi.name}',
              onPressed: onHapus,
              icon: Icon(
                Icons.delete_outline_rounded,
                color: context.tripin.favoriteActive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
