import 'package:flutter/material.dart';

Future<bool> showConfirmDeleteDialog(BuildContext context,
    {required String judul}) async {
  final hasil = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Hapus?'),
        content: Text('"$judul" akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    },
  );
  return hasil ?? false;
}
