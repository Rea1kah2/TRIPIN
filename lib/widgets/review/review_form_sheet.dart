import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/destinasi.dart';
import '../../models/review.dart';
import '../../providers/auth_provider.dart';
import '../../providers/review_provider.dart';
import '../../theme/app_colors.dart';
import '../app_snackbar.dart';
import '../glass_button.dart';
import '../glass_sheet.dart';
import 'rating_picker.dart';

/// Membuka form ulasan (baru, atau mengubah ulasan milik pengguna).
Future<void> bukaFormUlasan(BuildContext context, Destinasi destinasi) {
  return showGlassSheet<void>(context, builder: (_) => _FormUlasan(destinasi: destinasi, rootContext: context));
}

class _FormUlasan extends StatefulWidget {
  final Destinasi destinasi;
  final BuildContext rootContext;

  const _FormUlasan({required this.destinasi, required this.rootContext});

  @override
  State<_FormUlasan> createState() => _FormUlasanState();
}

class _FormUlasanState extends State<_FormUlasan> {
  late final TextEditingController _komentar;
  int _nilai = 0;
  bool _menyimpan = false;
  String? _galat;
  bool _mengedit = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    final lama = context.read<ReviewProvider>().milik(widget.destinasi.id, user?.id);
    _mengedit = lama != null;
    _nilai = lama?.rating ?? 0;
    _komentar = TextEditingController(text: lama?.komentar ?? '');
  }

  @override
  void dispose() {
    _komentar.dispose();
    super.dispose();
  }

  Future<void> _kirim() async {
    if (_menyimpan) return;
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) {
      setState(() => _galat = 'Masuk dulu untuk menulis ulasan.');
      return;
    }
    setState(() {
      _menyimpan = true;
      _galat = null;
    });
    final provider = context.read<ReviewProvider>();
    final galat = await provider.simpan(
      destinasiId: widget.destinasi.id,
      userId: user.id,
      namaPenulis: user.nama,
      rating: _nilai,
      komentar: _komentar.text,
    );
    if (!mounted) return;
    if (galat != null) {
      setState(() {
        _menyimpan = false;
        _galat = galat;
      });
      return;
    }
    Navigator.pop(context);
    if (widget.rootContext.mounted) {
      showAppSnackbar(widget.rootContext, _mengedit ? 'Ulasanmu diperbarui' : 'Terima kasih atas ulasanmu!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _mengedit ? 'Ubah ulasanmu' : 'Tulis ulasan',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            widget.destinasi.name,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.tripin.textSecondary),
          ),
          const SizedBox(height: 14),
          RatingPicker(nilai: _nilai, onChanged: (v) => setState(() {
                _nilai = v;
                _galat = null;
              })),
          const SizedBox(height: 14),
          TextField(
            controller: _komentar,
            minLines: 3,
            maxLines: 6,
            maxLength: Review.maksKomentar,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Ceritakan pengalamanmu (opsional)',
              fillColor: scheme.onSurface.withOpacity(0.07),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          if (_galat != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Semantics(
                liveRegion: true,
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 18, color: scheme.error),
                    const SizedBox(width: 6),
                    Expanded(child: Text(_galat!, style: TextStyle(color: scheme.error, fontSize: 13))),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 14),
          GlassButton(
            label: _menyimpan ? 'Menyimpan…' : (_mengedit ? 'Simpan perubahan' : 'Kirim ulasan'),
            variant: GlassButtonVariant.prominent,
            besar: true,
            melebar: true,
            onPressed: _menyimpan ? null : _kirim,
          ),
        ],
      ),
    );
  }
}
