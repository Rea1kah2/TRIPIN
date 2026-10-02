import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/destinasi_provider.dart';
import '../../providers/rencana_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/chat/chat_bubble.dart';
import '../../widgets/confirm_delete_dialog.dart';
import '../../widgets/glass_scaffold.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/glass_insets.dart';
import '../../widgets/pressable_scale.dart';
import '../../providers/lokasi_provider.dart';

const _saran = [
  'Rekomendasi wisata alam yang murah',
  'Buatkan rencana 2 hari ke Danau Toba',
  'Tempat seru dekat Medan',
  'Wisata gratis apa saja?',
  'Cara membuat rencana perjalanan',
];

/// Layar chat dengan Tripy. [embedded] = dipakai sebagai tab
/// (tanpa tombol kembali); [promptAwal] dikirim otomatis saat layar dibuka.
class ChatScreen extends StatefulWidget {
  final bool embedded;
  final String? promptAwal;

  const ChatScreen({super.key, this.embedded = false, this.promptAwal});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _dekatBawah = true;
  String _tandaKonten = '';

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (!_scroll.hasClients) return;
      _dekatBawah = _scroll.position.maxScrollExtent - _scroll.offset < 160;
    });
    _input.addListener(() => setState(() {}));

    final awal = widget.promptAwal;
    if (awal != null && awal.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _kirim(awal);
      });
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Map<String, dynamic> _konteks() => bangunKonteks(
        context.read<DestinasiProvider>(),
        context.read<RencanaProvider>(),
        posisi: context.read<LokasiProvider>().posisi,
      );

  void _kirim(String teks) {
    final chat = context.read<ChatProvider>();
    if (teks.trim().isEmpty) return;
    if (chat.isStreaming) {
      showAppSnackbar(context, 'Tunggu Tripy selesai jawab dulu ya', isError: true);
      return;
    }
    _input.clear();
    _dekatBawah = true;
    chat.kirim(teks, konteks: _konteks());
  }

  void _scrollKeBawahJikaPerlu(ChatProvider chat) {
    final msgs = chat.messages;
    final terakhir = msgs.isEmpty ? null : msgs.last;
    final tanda = '${msgs.length}:${terakhir?.text.length}:${terakhir?.destinasiIds.length}:'
        '${terakhir?.draft != null}:${terakhir?.error}';
    if (tanda == _tandaKonten) return;
    _tandaKonten = tanda;
    if (!_dekatBawah) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _hapusRiwayat() async {
    final chat = context.read<ChatProvider>();
    final ya = await showConfirmDeleteDialog(context, judul: 'Percakapan ini');
    if (ya) chat.hapusRiwayat();
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final msgs = chat.messages;
    final colors = context.colors;
    _scrollKeBawahJikaPerlu(chat);

    return GlassScaffold(
      appBar: GlassAppBar(
        otomatisKembali: !widget.embedded,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: context.tripin.paleMint, shape: BoxShape.circle),
              child: Icon(Icons.auto_awesome, size: 18, color: colors.primary),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'Tripy',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          if (msgs.isNotEmpty)
            IconButton(
              tooltip: 'Hapus percakapan',
              icon: const Icon(Icons.delete_outline),
              onPressed: _hapusRiwayat,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: msgs.isEmpty
                ? _Kosong(onPilih: _kirim)
                : ListView.separated(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemCount: msgs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final m = msgs[i];
                      final terakhir = i == msgs.length - 1;
                      return ChatBubble(
                        key: ValueKey(m.id),
                        message: m,
                        sedangMengetik: terakhir && chat.isStreaming,
                        onUlangi: terakhir && !chat.isStreaming && m.error != null
                            ? () => chat.ulangi(konteks: _konteks())
                            : null,
                      );
                    },
                  ),
          ),
          _Komposer(
            controller: _input,
            sedangMengetik: chat.isStreaming,
            onKirim: () => _kirim(_input.text),
            onBatal: chat.batal,
          ),
        ],
      ),
    );
  }
}

class _Kosong extends StatelessWidget {
  final void Function(String) onPilih;

  const _Kosong({required this.onPilih});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: context.tripin.paleMint,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Icons.auto_awesome, size: 38, color: colors.primary),
          ),
          const SizedBox(height: 16),
          const Text('Halo, aku Tripy 👋 Mau healing ke mana nih?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Aku bisa bantu milih destinasi, nyusun rencana perjalanan, '
            'dan jelasin cara pakai aplikasi ini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.tripin.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in _saran) _SaranChip(label: s, onTap: () => onPilih(s)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Chip saran: kapsul kaca tipis (tinggi 44 untuk area sentuh).
class _SaranChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SaranChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: PressableScale(
        onTap: onTap,
        skala: 0.96,
        child: GlassPanel(
          radius: 999,
          bias: -0.25,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.colors.primary),
          ),
        ),
      ),
    );
  }
}

final _bentukInput = OutlineInputBorder(
  borderRadius: BorderRadius.circular(22),
  borderSide: BorderSide.none,
);

/// Komposer kapsul kaca yang melayang di atas tab bar. Input memakai fill (bukan kaca)
/// supaya tidak ada kaca di atas kaca.
class _Komposer extends StatelessWidget {
  final TextEditingController controller;
  final bool sedangMengetik;
  final VoidCallback onKirim;
  final VoidCallback onBatal;

  const _Komposer({
    required this.controller,
    required this.sedangMengetik,
    required this.onKirim,
    required this.onBatal,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bisaKirim = controller.text.trim().isNotEmpty && !sedangMengetik;
    final inset = GlassInsets.bawahOf(context);

    return SafeArea(
      top: false,
      bottom: inset == 0,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 4, 12, 8 + inset),
        child: GlassPanel(
          blur: true,
          radius: 30,
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: 2000,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: 'Tanya Tripy soal wisata…',
                    counterText: '',
                    fillColor: colors.onSurface.withOpacity(0.06),
                    border: _bentukInput,
                    enabledBorder: _bentukInput,
                    focusedBorder: _bentukInput,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              if (sedangMengetik)
                IconButton.filledTonal(
                  tooltip: 'Hentikan',
                  style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: onBatal,
                  icon: const Icon(Icons.stop_rounded),
                )
              else
                IconButton.filled(
                  tooltip: 'Kirim',
                  style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: bisaKirim ? onKirim : null,
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
