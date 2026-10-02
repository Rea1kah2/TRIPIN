import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/destinasi_provider.dart';
import '../../providers/rencana_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/chat/chat_bubble.dart';
import '../../widgets/confirm_delete_dialog.dart';

const _saran = [
  'Rekomendasi wisata alam yang murah',
  'Buatkan rencana 2 hari ke Danau Toba',
  'Tempat seru dekat Medan',
  'Wisata gratis apa saja?',
  'Cara membuat rencana perjalanan',
];

/// Layar chat dengan Asisten TRIPIN. [embedded] = dipakai sebagai tab
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
      );

  void _kirim(String teks) {
    final chat = context.read<ChatProvider>();
    if (teks.trim().isEmpty) return;
    if (chat.isStreaming) {
      showAppSnackbar(context, 'Tunggu balasan selesai dulu ya', isError: true);
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

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        titleSpacing: widget.embedded ? 20 : 0,
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
                'Asisten TRIPIN',
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
          const Text('Halo, aku Asisten TRIPIN 👋',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Aku bisa bantu memilih destinasi, menyusun rencana perjalanan, '
            'dan menjelaskan cara memakai aplikasi.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.tripin.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in _saran)
                ActionChip(
                  label: Text(s),
                  onPressed: () => onPilih(s),
                  backgroundColor: context.tripin.paleMint,
                  labelStyle: TextStyle(color: colors.primary, fontWeight: FontWeight.w600),
                  side: BorderSide.none,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

final _bentukInput = OutlineInputBorder(
  borderRadius: BorderRadius.circular(22),
  borderSide: BorderSide.none,
);

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

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
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
                    hintText: 'Tanya soal wisata…',
                    counterText: '',
                    fillColor: context.tripin.softMint,
                    border: _bentukInput,
                    enabledBorder: _bentukInput,
                    focusedBorder: _bentukInput,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              if (sedangMengetik)
                IconButton.filledTonal(
                  tooltip: 'Hentikan',
                  onPressed: onBatal,
                  icon: const Icon(Icons.stop_rounded),
                )
              else
                IconButton.filled(
                  tooltip: 'Kirim',
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
