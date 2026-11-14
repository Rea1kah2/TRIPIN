import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/rencana_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/radii.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/confirm_delete_dialog.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/glass_scaffold.dart';
import '../../widgets/keadaan_kosong.dart';
import '../../widgets/pressable_scale.dart';
import '../../widgets/rencana_card.dart';

class DaftarRencanaScreen extends StatelessWidget {
  const DaftarRencanaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RencanaProvider>();
    final daftar = provider.daftarRencana;

    return GlassScaffold(
      appBar: GlassAppBar(
        judul: 'Rencana Perjalanan',
        actions: [
          IconButton(
            tooltip: 'Checklist Persiapan',
            icon: Icon(
              Icons.checklist_rounded,
              color: context.colors.primary,
            ),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.checklist),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Semantics(
              button: true,
              label: 'Checklist Persiapan Perjalanan',
              child: PressableScale(
                onTap: () => Navigator.pushNamed(context, AppRoutes.checklist),
                child: GlassPanel(
                  radius: Radii.lg,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: context.tripin.paleMint,
                          borderRadius: BorderRadius.circular(Radii.sm),
                        ),
                        child: Icon(
                          Icons.checklist_rounded,
                          color: context.colors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Checklist Persiapan Perjalanan',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Pastikan barang bawaan & dokumen siap',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.tripin.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: context.tripin.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Daftar rencana perjalanan
          Expanded(
            child: daftar.isEmpty
                ? KeadaanKosong(
                    ikon: Icons.map_outlined,
                    judul: 'Belum ada rencana',
                    pesan:
                        'Susun perjalanan pertamamu, atau minta Tripy menyusunnya.',
                    labelAksi: 'Buat rencana',
                    onAksi: () => Navigator.pushNamed(
                      context,
                      AppRoutes.rencanaTambah,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: daftar.length,
                    itemBuilder: (context, index) {
                      final rencana = daftar[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Dismissible(
                          key: ValueKey(rencana.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: context.colors.error,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.delete_outline,
                              color: context.colors.onError,
                            ),
                          ),
                          confirmDismiss: (_) => showConfirmDeleteDialog(
                            context,
                            judul: rencana.judul,
                          ),
                          onDismissed: (_) {
                            provider.hapusRencana(rencana.id);
                            showAppSnackbar(context, 'Rencana dihapus');
                          },
                          child: RencanaCard(
                            rencana: rencana,
                            jumlahDestinasi: rencana.daftarDestinasiId.length,
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.rencanaDetail,
                              arguments: rencana.id,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(
          context,
          AppRoutes.rencanaTambah,
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
