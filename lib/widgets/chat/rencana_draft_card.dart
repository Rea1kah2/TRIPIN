import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat_message.dart';
import '../../providers/chat_provider.dart';
import '../../providers/destinasi_provider.dart';
import '../../providers/rencana_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../theme/radii.dart';
import '../app_snackbar.dart';
import '../glass_button.dart';
import '../glass_panel.dart';

/// Kartu draf rencana dari asisten. Tidak menyimpan apa pun sebelum
/// pengguna menekan "Simpan sebagai rencana".
class RencanaDraftCard extends StatelessWidget {
  final String messageId;
  final DraftRencana draft;

  const RencanaDraftCard({super.key, required this.messageId, required this.draft});

  @override
  Widget build(BuildContext context) {
    final destinasi = context.watch<DestinasiProvider>();
    final rencana = context.watch<RencanaProvider>();
    final colors = context.colors;
    final tripin = context.tripin;

    final nama = [
      for (final id in draft.destinasiIds)
        if (destinasi.getById(id) != null) destinasi.getById(id)!.name,
    ];
    final mulai = draft.tanggalMulai;
    final tanggal = mulai == null
        ? '${draft.jumlahHari} hari'
        : '${formatTanggal(mulai)} · ${draft.jumlahHari} hari';
    final rencanaTersimpan = draft.rencanaId == null ? null : rencana.getById(draft.rencanaId!);

    // Kartu sorotan: kaca dengan tepi warna utama tipis.
    return SizedBox(
      width: double.infinity,
      child: GlassPanel(
        radius: Radii.xl,
        padding: const EdgeInsets.all(16),
        rimColor: colors.primary.withOpacity(0.5),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.map_outlined, size: 18, color: colors.primary),
              const SizedBox(width: 6),
              Text(
                'Draf rencana',
                style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(draft.judul, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(tanggal, style: TextStyle(color: tripin.textSecondary, fontSize: 12)),
          const SizedBox(height: 10),
          for (var i = 0; i < nama.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('${i + 1}. ${nama[i]}', style: const TextStyle(fontSize: 13)),
            ),
          if (draft.catatan.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(draft.catatan, style: TextStyle(color: tripin.textSecondary, fontSize: 12, height: 1.4)),
          ],
          const SizedBox(height: 12),
          if (draft.tersimpan)
            rencanaTersimpan == null
                ? Text('Rencana ini sudah dihapus.', style: TextStyle(color: tripin.textSecondary, fontSize: 12))
                : GlassButton(
                    melebar: true,
                    icon: Icons.check_circle,
                    label: 'Tersimpan · Lihat rencana',
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.rencanaDetail,
                      arguments: rencanaTersimpan.id,
                    ),
                  )
          else
            GlassButton(
              melebar: true,
              variant: GlassButtonVariant.prominent,
              icon: Icons.bookmark_add_outlined,
              label: 'Simpan sebagai rencana',
              onPressed: nama.isEmpty
                  ? null
                  : () {
                      final baru = context.read<ChatProvider>().simpanDraft(
                            messageId,
                            rencana: context.read<RencanaProvider>(),
                            destinasi: context.read<DestinasiProvider>(),
                          );
                      if (baru != null) {
                        showAppSnackbar(context, 'Rencana "${baru.judul}" disimpan');
                      }
                    },
            ),
        ],
        ),
      ),
    );
  }
}
