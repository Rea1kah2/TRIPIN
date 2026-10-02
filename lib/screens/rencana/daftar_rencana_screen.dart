import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/rencana_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/confirm_delete_dialog.dart';
import '../../widgets/rencana_card.dart';

class DaftarRencanaScreen extends StatelessWidget {
  const DaftarRencanaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RencanaProvider>();
    final daftar = provider.daftarRencana;

    return Scaffold(
      appBar: AppBar(title: const Text('Rencana Perjalanan')),
      body: daftar.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Belum ada rencana perjalanan.\nTap tombol + untuk membuat satu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.tripin.textSecondary),
                ),
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
                      child: Icon(Icons.delete_outline, color: context.colors.onError),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.rencanaTambah),
        child: const Icon(Icons.add),
      ),
    );
  }
}