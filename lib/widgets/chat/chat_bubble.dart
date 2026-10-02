import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat_message.dart';
import '../../providers/destinasi_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../utils/mini_markdown.dart';
import '../destinasi_card.dart';
import 'rencana_draft_card.dart';
import 'typing_indicator.dart';

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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: SelectableText(
            message.text,
            style: TextStyle(color: colors.onPrimary, height: 1.35),
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
            if (adaTeks || menunggu)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border.all(color: colors.outlineVariant),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: menunggu
                    ? const TypingIndicator()
                    : SelectableText.rich(
                        miniMarkdown(
                          message.text,
                          TextStyle(color: colors.onSurface, height: 1.4),
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
