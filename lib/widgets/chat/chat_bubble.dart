import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat_message.dart';
import '../../providers/destinasi_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../utils/mini_markdown.dart';
import '../destinasi_card.dart';
import 'rencana_draft_card.dart';
import '../glass_panel.dart';
import 'assistant_status.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  /// True bila ini balasan terakhir dan masih diterima (streaming).
  final bool sedangMengetik;
  final VoidCallback? onUlangi;

  const ChatBubble({
    super.key,
    required this.message,
    this.sedangMengetik = false,
    this.onUlangi,
  });

  @override
  Widget build(BuildContext context) {
    return message.role == ChatRole.user ? _buildUser(context) : _buildModel(context);
  }

  Widget _buildUser(BuildContext context) {
    final colors = context.colors;
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
        // Bubble pengguna = kaca bertint warna utama; ekor kecil di sudut kanan bawah.
        child: GlassPanel(
          accent: true,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(6),
          ),
          child: SelectableText(
            message.text,
            style: TextStyle(color: colors.onPrimary, height: 1.35, fontSize: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildModel(BuildContext context) {
    final colors = context.colors;
    final destinasi = context.watch<DestinasiProvider>();
    final adaTeks = message.text.isNotEmpty;
    final menunggu = sedangMengetik && !adaTeks;
    final kartu = [
      for (final id in message.destinasiIds)
        if (destinasi.getById(id) != null) destinasi.getById(id)!,
    ];

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.92),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (menunggu)
              AssistantStatus(teks: message.status ?? 'Tripy lagi mikir…')
            else if (adaTeks)
              // Balasan AI = permukaan solid (badan teks tidak dibuat kaca agar mudah dibaca).
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border.all(color: colors.outlineVariant),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(6),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: SelectableText.rich(
                  miniMarkdown(
                    message.text,
                    TextStyle(color: colors.onSurface, height: 1.4, fontSize: 15),
                  ),
                ),
              ),
            for (final d in kartu)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: DestinasiCard(
                    destinasi: d,
                    dense: true,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.destinasiDetail,
                      arguments: d.id,
                    ),
                    onFavoriteTap: () => destinasi.toggleFavorit(d.id),
                  ),
                ),
              ),
            if (message.draft != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: RencanaDraftCard(messageId: message.id, draft: message.draft!),
              ),
            // Balasan masih mengalir: tetap ada tanda Tripy bekerja sampai selesai.
            if (sedangMengetik && !menunggu)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: AssistantStatus(teks: message.status ?? 'Menulis…', kecil: true),
              ),
            if (message.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _GalatBaris(pesan: message.error!, onUlangi: onUlangi),
              ),
          ],
        ),
      ),
    );
  }
}

class _GalatBaris extends StatelessWidget {
  final String pesan;
  final VoidCallback? onUlangi;

  const _GalatBaris({required this.pesan, this.onUlangi});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline, size: 18, color: colors.error),
        const SizedBox(width: 6),
        Flexible(
          child: Text(pesan, style: TextStyle(color: colors.error, fontSize: 13, height: 1.3)),
        ),
        if (onUlangi != null)
          TextButton(
            onPressed: onUlangi,
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 32),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('Ulangi'),
          ),
      ],
    );
  }
}
