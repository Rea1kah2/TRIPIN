import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/rencana_perjalanan.dart';
import '../../providers/destinasi_provider.dart';
import '../../providers/rencana_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_snackbar.dart';

class TambahRencanaScreen extends StatefulWidget {
  const TambahRencanaScreen({super.key});

  @override
  State<TambahRencanaScreen> createState() => _TambahRencanaScreenState();
}

class _TambahRencanaScreenState extends State<TambahRencanaScreen> {
  final _formKey = GlobalKey<FormState>();
  final judulController = TextEditingController();
  final catatanController = TextEditingController();

  DateTime tanggalMulai = DateTime.now();
  DateTime tanggalSelesai = DateTime.now().add(const Duration(days: 1));
  final Set<String> destinasiTerpilih = {};

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

  void simpan() {
    if (!_formKey.currentState!.validate()) return;

    if (destinasiTerpilih.isEmpty) {
      showAppSnackbar(context, 'Pilih minimal 1 destinasi', isError: true);
      return;
    }

    if (tanggalSelesai.isBefore(tanggalMulai)) {
      showAppSnackbar(
          context, 'Tanggal selesai tak boleh sebelum tanggal mulai',
          isError: true);
      return;
    }

    context.read<RencanaProvider>().tambahRencana(
          RencanaPerjalanan(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            judul: judulController.text,
            tanggalMulai: tanggalMulai,
            tanggalSelesai: tanggalSelesai,
            daftarDestinasiId: destinasiTerpilih.toList(),
            catatan: catatanController.text.trim(),
          ),
        );

    showAppSnackbar(context, 'Rencana perjalanan dibuat');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context){
    final daftarDestinasi = context.watch<DestinasiProvider>().daftarDestinasi;

    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Rencana Perjalanan')),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: judulController,
              decoration: const InputDecoration(labelText: 'Judul Rencana'),
              validator: (value){
                if(value == null || value.trim().isEmpty){
                  return 'Judul wajib diisi!';
                }
                if(value.trim().length < 3){
                  return 'Judul minimal 3 karakter';
                }
                return null;
              },
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
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            const Text('Pilih Destinasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              '${destinasiTerpilih.length} destinasi terpilih',
              style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...daftarDestinasi.map((destinasi){
              final terpilih = destinasiTerpilih.contains(destinasi.id);
              return CheckboxListTile(
                value: terpilih,
                onChanged: (value){
                  setState((){
                    if(value == true){
                      destinasiTerpilih.add(destinasi.id);
                    } else {
                      destinasiTerpilih.remove(destinasi.id);
                    }
                  });
                },
                title: Text(destinasi.name),
                subtitle: Text(destinasi.location),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              );
            }),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: simpan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('Simpan Rencana', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
