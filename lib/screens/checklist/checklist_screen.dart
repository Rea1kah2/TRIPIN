import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/checklist_item.dart';
import '../../providers/auth_provider.dart';
import '../../services/local_storage_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/radii.dart';
import '../../theme/typography.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/glass_insets.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/glass_scaffold.dart';
import '../../widgets/keadaan_kosong.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final TextEditingController _controller = TextEditingController();
  final LocalStorageService _storage = LocalStorageService();

  List<ChecklistItem> _items = [];
  bool _memuat = true;
  bool _sudahInit = false;
  String? _userId;

  String? _bacaUserIdAman(BuildContext context) {
    try {
      return context.watch<AuthProvider>().currentUser?.id;
    } on ProviderNotFoundException {
      return null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userBaru = _bacaUserIdAman(context);
    if (_sudahInit && userBaru == _userId) return;
    _sudahInit = true;
    _userId = userBaru;
    _muatChecklist();
  }

  Future<void> _muatChecklist() async {
    final targetUser = _userId;
    final dimuat = await _storage.muatChecklist(userId: targetUser);
    if (!mounted || targetUser != _userId) return;
    setState(() {
      _items = dimuat;
      _memuat = false;
    });
  }

  Future<void> _simpan() async {
    await _storage.simpanChecklist(_items, userId: _userId);
  }

  Future<void> _tambahBarang() async {
    final nama = _controller.text.trim();
    if (nama.isEmpty) {
      showAppSnackbar(
        context,
        'Masukkan nama perlengkapan terlebih dahulu',
        isError: true,
      );
      return;
    }

    setState(() {
      _items = [
        ..._items,
        ChecklistItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          nama: nama,
        ),
      ];
      _controller.clear();
    });
    FocusScope.of(context).unfocus();
    await _simpan();
    if (!mounted) return;
    showAppSnackbar(context, '$nama ditambahkan ke checklist');
  }

  Future<void> _toggleBarang(int index) async {
    final item = _items[index];
    setState(() {
      _items = [
        for (var i = 0; i < _items.length; i++)
          if (i == index) item.copyWith(selesai: !item.selesai) else _items[i],
      ];
    });
    await _simpan();
  }

  Future<void> _hapusBarang(int index) async {
    final item = _items[index];
    setState(() {
      _items = [
        for (var i = 0; i < _items.length; i++)
          if (i != index) _items[i],
      ];
    });
    await _simpan();
    if (!mounted) return;
    showAppSnackbar(context, '${item.nama} dihapus');
  }

  Future<void> _resetCentang() async {
    setState(() {
      _items = [
        for (final item in _items) item.copyWith(selesai: false),
      ];
    });
    await _simpan();
    if (!mounted) return;
    showAppSnackbar(context, 'Semua centang direset');
  }

  Future<void> _muatDaftarBawaan() async {
    final bawaan = ChecklistItem.bawaanAwal();
    setState(() {
      _items = bawaan;
    });
    await _simpan();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final tripin = context.tripin;
    final total = _items.length;
    final selesai = _items.where((item) => item.selesai).length;
    final progres = total == 0 ? 0.0 : selesai / total;

    return GlassScaffold(
      appBar: const GlassAppBar(judul: 'Checklist Persiapan'),
      body: _memuat
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                24 + GlassInsets.bawahOf(context),
              ),
              children: [
                // Ringkasan progres persiapan
                GlassPanel(
                  radius: Radii.xl,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Persiapan Liburan',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: tripin.paleMint,
                              borderRadius: BorderRadius.circular(Radii.full),
                            ),
                            child: Text(
                              '${(progres * 100).round()}%',
                              style: angkaTabular.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: scheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        total == 0
                            ? 'Belum ada daftar perlengkapan'
                            : '$selesai dari $total perlengkapan siap',
                        style: angkaTabular.copyWith(
                          fontSize: 13,
                          color: tripin.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(Radii.full),
                        child: LinearProgressIndicator(
                          value: progres,
                          minHeight: 8,
                          backgroundColor: scheme.onSurface.withOpacity(0.08),
                          color: scheme.primary,
                        ),
                      ),
                      if (selesai > 0) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _resetCentang,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              minimumSize: const Size(0, 36),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.restart_alt_rounded, size: 17),
                            label: const Text('Reset centang'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Input tambah perlengkapan
                GlassPanel(
                  radius: Radii.lg,
                  padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _tambahBarang(),
                          decoration: const InputDecoration(
                            hintText: 'Tambah perlengkapan...',
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton.filled(
                        tooltip: 'Tambah perlengkapan',
                        style: IconButton.styleFrom(
                          minimumSize: const Size(44, 44),
                        ),
                        onPressed: _tambahBarang,
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Daftar Perlengkapan',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),

                if (_items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: KeadaanKosong(
                      ikon: Icons.checklist_rtl_rounded,
                      judul: 'Checklist masih kosong',
                      pesan:
                          'Tambahkan perlengkapan penting agar tidak ada yang tertinggal sebelum berangkat.',
                      labelAksi: 'Muat daftar bawaan',
                      onAksi: _muatDaftarBawaan,
                    ),
                  )
                else
                  GlassPanel(
                    radius: Radii.lg,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        for (var i = 0; i < _items.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              indent: 52,
                              endIndent: 16,
                              color: scheme.outlineVariant.withOpacity(0.45),
                            ),
                          _BarisChecklist(
                            item: _items[i],
                            onToggle: () => _toggleBarang(i),
                            onHapus: () => _hapusBarang(i),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _BarisChecklist extends StatelessWidget {
  final ChecklistItem item;
  final VoidCallback onToggle;
  final VoidCallback onHapus;

  const _BarisChecklist({
    required this.item,
    required this.onToggle,
    required this.onHapus,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final tripin = context.tripin;

    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          children: [
            Checkbox(
              value: item.selesai,
              onChanged: (_) => onToggle(),
              activeColor: scheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            Expanded(
              child: Text(
                item.nama,
                style: TextStyle(
                  fontSize: 15,
                  color: item.selesai ? tripin.textSecondary : scheme.onSurface,
                  decoration: item.selesai
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  decorationColor: tripin.textSecondary,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Hapus ${item.nama}',
              onPressed: onHapus,
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: tripin.favoriteActive.withOpacity(0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
