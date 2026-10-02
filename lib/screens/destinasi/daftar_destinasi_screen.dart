import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/destinasi_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/destinasi_card.dart';
import '../../widgets/kategori_chip.dart';
import '../../widgets/glass_scaffold.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/glass_insets.dart';
import '../../widgets/keadaan_kosong.dart';

class DaftarDestinasiScreen extends StatefulWidget {
  const DaftarDestinasiScreen({super.key});

  @override
  State<DaftarDestinasiScreen> createState() => _DaftarDestinasiScreenState();
}

class _DaftarDestinasiScreenState extends State<DaftarDestinasiScreen> {
  final searchController = TextEditingController();
  String? selectedKategoriId;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DestinasiProvider>();
    final daftar = provider.cari(
      query: searchController.text,
      kategoriId: selectedKategoriId,
    );

    return GlassScaffold(
      appBar: const GlassAppBar(judul: 'Jelajah'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Cari destinasi...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SemuaChip(
                    selected: selectedKategoriId == null,
                    onTap: () => setState(() => selectedKategoriId = null),
                  ),
                ),
                for (final kategori in provider.daftarKategori)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: KategoriChip(
                      kategori: kategori,
                      selected: selectedKategoriId == kategori.id,
                      onTap: () =>
                          setState(() => selectedKategoriId = kategori.id),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: daftar.isEmpty
                ? KeadaanKosong(
                    ikon: Icons.search_off,
                    judul: 'Tidak ada yang cocok',
                    pesan: 'Coba kata kunci lain atau hapus filter kategori.',
                    labelAksi: 'Hapus filter',
                    onAksi: () => setState(() {
                      searchController.clear();
                      selectedKategoriId = null;
                    }),
                  )
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + GlassInsets.bawahOf(context)),
                    itemCount: daftar.length,
                    itemBuilder: (context, index) {
                      final destinasi = daftar[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DestinasiCard(
                          destinasi: destinasi,
                          dense: true,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.destinasiDetail,
                            arguments: destinasi.id,
                          ),
                          onFavoriteTap: () =>
                              provider.toggleFavorit(destinasi.id),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
