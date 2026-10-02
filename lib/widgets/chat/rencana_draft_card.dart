import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat_message.dart';
import '../../providers/chat_provider.dart';
import '../../providers/destinasi_provider.dart';
import '../../providers/rencana_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../app_snackbar.dart';

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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tripin.softMint,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.primary.withOpacity(0.35)),
      ),
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
          Text(draft.judul, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                : SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.rencanaDetail,
                        arguments: rencanaTersimpan.id,
                      ),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Tersimpan · Lihat rencana'),
                    ),
                  )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
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
                icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                label: const Text('Simpan sebagai rencana'),
              ),
            ),
        ],
      ),
    );
  }
}
