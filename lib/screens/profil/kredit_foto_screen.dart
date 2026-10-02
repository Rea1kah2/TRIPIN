import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/destinasi_provider.dart';
import '../../services/kredit_foto.dart';
import '../../theme/app_colors.dart';
import '../../theme/radii.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/glass_scaffold.dart';

/// Daftar atribusi foto (syarat lisensi CC BY / CC BY-SA). Lisensi hanya berlaku untuk foto.
class KreditFotoScreen extends StatelessWidget {
  const KreditFotoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final destinasi = context.watch<DestinasiProvider>();
    return GlassScaffold(
      appBar: const GlassAppBar(judul: 'Kredit Foto'),
      body: FutureBuilder<Map<String, List<KreditFoto>>>(
        future: KreditFotoService.muat(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data ?? {};
          final baris = <MapEntry<String, KreditFoto>>[
            for (final e in data.entries)
              for (final k in e.value) MapEntry(e.key == 'banner' ? 'Banner Beranda' : (destinasi.getById(e.key)?.name ?? e.key), k),
          ];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                child: Text(
                  'Foto destinasi berasal dari Wikimedia Commons dan dipakai sesuai lisensinya '
                  '(CC BY / CC BY-SA). Terima kasih kepada para fotografer.',
                  style: TextStyle(color: context.tripin.textSecondary, height: 1.4),
                ),
              ),
              for (final b in baris)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassPanel(
                    radius: Radii.lg,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text('Foto: ${b.value.fotografer}', style: const TextStyle(fontSize: 13)),
                        Text(
                          '${b.value.lisensi} · ${b.value.judul}',
                          style: TextStyle(fontSize: 12, color: context.tripin.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
