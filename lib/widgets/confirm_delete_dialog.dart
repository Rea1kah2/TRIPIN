import 'package:flutter/material.dart';
import 'glass_alert.dart';

Future<bool> showConfirmDeleteDialog(BuildContext context,
    {required String judul}) async {
  final hasil = await showGlassAlert<bool>(
    context,
    judul: 'Hapus?',
    pesan: '"$judul" akan dihapus permanen.',
    aksi: const [
      GlassAlertAksi(label: 'Batal', nilai: false, utama: true),
      GlassAlertAksi(label: 'Hapus', nilai: true, destruktif: true),
    ],
  );
  return hasil ?? false;
}
