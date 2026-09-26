import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/destinasi.dart';
import '../../providers/destinasi_provider.dart';
import '../../providers/rencana_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/confirm_delete_dialog.dart';
import '../../widgets/destinasi_card.dart';

class DetailRencanaScreen extends StatefulWidget {
  final String rencanaId;

  const DetailRencanaScreen({super.key, required this.rencanaId});

  @override
  State<DetailRencanaScreen> createState() => _DetailRencanaScreenState();
}

class _DetailRencanaScreenState extends State<DetailRencanaScreen> {
  bool editMode = false;
  bool sudahDiinisialisasi = false;

  final judulController = TextEditingController();
  final catatanController = TextEditingController();
  DateTime tanggalMulai = DateTime.now();
  DateTime tanggalSelesai = DateTime.now();

  @override
  void dispose() {
    judulController.dispose();
    catatanController.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal({required bool mulai}) async {
    final hasil = await showDatePicker(
      context: context,
      initialDate: mulai ? tanggalMulai : tanggalSelesai,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (hasil == null) return;
    setState(() {
      if (mulai) {
        tanggalMulai = hasil;
      } else {
        tanggalSelesai = hasil;
      }
    });
  }

  void _simpanEdit() {
    if (judulController.text.trim().isEmpty) {
      showAppSnackbar(context, 'Judul wajib diisi', isError: true);
      return;
    }
    if (tanggalSelesai.isBefore(tanggalMulai)) {
      showAppSnackbar(context, 'Tanggal selesai tidak boleh sebelum tanggal mulai', isError: true);
      return;
    }

    final provider = context.read<RencanaProvider>();
    final rencana = provider.getById(widget.rencanaId)!;
    provider.perbaruiRencana(
      rencana.copyWith(
        judul: judulController.text.trim(),
        tanggalMulai: tanggalMulai,
        tanggalSelesai: tanggalSelesai,
        catatan: catatanController.text.trim(),
      ),
    );

    showAppSnackbar(context, 'Rencana diperbarui');
    setState(() => editMode = false);
  }

  void _bukaTambahDestinasi(BuildContext context, List<String> idSudahAda) {
    final destinasiProvider = context.read<DestinasiProvider>();
    final rencanaProvider = context.read<RencanaProvider>();
    final belumAda = destinasiProvider.daftarDestinasi
        .where((d) => !idSudahAda.contains(d.id))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tambah Destinasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (belumAda.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Semua destinasi sudah ada di rencana ini.', style: TextStyle(color: Colors.grey)),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: belumAda.length,
                      itemBuilder: (context, index) {
                        final destinasi = belumAda[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(destinasi.name),
                          subtitle: Text(destinasi.location),
                          trailing: const Icon(Icons.add_circle_outline),
                          onTap: () {
                            rencanaProvider.tambahDestinasiKeRencana(widget.rencanaId, destinasi.id);
                            Navigator.pop(sheetContext);
                            showAppSnackbar(context, '${destinasi.name} ditambahkan');
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rencanaProvider = context.watch<RencanaProvider>();
    final destinasiProvider = context.watch<DestinasiProvider>();
    final rencana = rencanaProvider.getById(widget.rencanaId);

    if (rencana == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.pop(context));
      return const SizedBox.shrink();
    }

    if (!sudahDiinisialisasi) {
      sudahDiinisialisasi = true;
      judulController.text = rencana.judul;
      catatanController.text = rencana.catatan;
      tanggalMulai = rencana.tanggalMulai;
      tanggalSelesai = rencana.tanggalSelesai;
    }

    final daftarDestinasi = rencana.daftarDestinasiId
        .map((id) => destinasiProvider.getById(id))
        .whereType<Destinasi>()
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(editMode ? 'Edit Rencana' : rencana.judul),
        actions: [
          if (!editMode)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => editMode = true),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final konfirmasi = await showConfirmDeleteDialog(context, judul: rencana.judul);
              if (!context.mounted || !konfirmasi) return;
              rencanaProvider.hapusRencana(rencana.id);
              showAppSnackbar(context, 'Rencana dihapus');
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (editMode) ...[
            TextFormField(
              controller: judulController,
              decoration: const InputDecoration(labelText: 'Judul Rencana'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pilihTanggal(mulai: true),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text('Mulai: ${formatTanggal(tanggalMulai)}'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pilihTanggal(mulai: false),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text('Selesai: ${formatTanggal(tanggalSelesai)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: catatanController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => editMode = false),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _simpanEdit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Simpan'),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '${formatTanggal(rencana.tanggalMulai)} - ${formatTanggal(rencana.tanggalSelesai)}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            if (rencana.catatan.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(rencana.catatan, style: const TextStyle(height: 1.5)),
            ],
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Destinasi (${daftarDestinasi.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () => _bukaTambahDestinasi(context, rencana.daftarDestinasiId),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (daftarDestinasi.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Belum ada destinasi di rencana ini.', style: TextStyle(color: Colors.grey)),
            )
          else
            ...daftarDestinasi.map((destinasi) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: DestinasiCard(
                        destinasi: destinasi,
                        dense: true,
                        onTap: () {},
                        onFavoriteTap: () => destinasiProvider.toggleFavorit(destinasi.id),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.favoriteActive),
                      onPressed: () {
                        rencanaProvider.hapusDestinasiDariRencana(rencana.id, destinasi.id);
                        showAppSnackbar(context, '${destinasi.name} dikeluarkan dari rencana');
                      },
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}