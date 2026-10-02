import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../models/review.dart';
import '../../providers/auth_provider.dart';
import '../../providers/destinasi_provider.dart';
import '../../services/local_storage_service.dart';
import '../../theme/app_colors.dart';

class ReviewScreen extends StatefulWidget {
  final String destinasiId;

  const ReviewScreen({
    super.key,
    required this.destinasiId,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final LocalStorageService _storage = LocalStorageService();
  final TextEditingController _komentarController =
  TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  List<Review> _daftarReview = [];
  int _rating = 5;
  File? _foto;
  bool _sedangMemuat = true;
  bool _sedangMenyimpan = false;

  @override
  void initState() {
    super.initState();
    _muatReview();
  }

  @override
  void dispose() {
    _komentarController.dispose();
    super.dispose();
  }

  Future<void> _muatReview() async {
    try {
      final semuaReview = await _storage.muatReviews();

      if (!mounted) return;

      setState(() {
        _daftarReview = semuaReview
            .where(
              (review) =>
          review.destinasiId == widget.destinasiId,
        )
            .toList()
          ..sort(
                (a, b) => b.tanggal.compareTo(a.tanggal),
          );

        _sedangMemuat = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _sedangMemuat = false);
      _tampilkanPesan('Gagal memuat ulasan.');
    }
  }

  Future<void> _pilihFoto() async {
    try {
      final XFile? hasil = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (hasil == null || !mounted) return;

      setState(() {
        _foto = File(hasil.path);
      });
    } catch (e) {
      _tampilkanPesan('Gagal memilih foto dari galeri.');
    }
  }

  Future<String?> _simpanFoto() async {
    if (_foto == null) return null;

    final Directory folder =
    await getApplicationDocumentsDirectory();

    final String namaFile =
        'review_${DateTime.now().microsecondsSinceEpoch}.jpg';

    final File fotoTersimpan = await _foto!.copy(
      '${folder.path}/$namaFile',
    );

    return fotoTersimpan.path;
  }

  Future<void> _kirimReview() async {
    final String komentar = _komentarController.text.trim();

    if (komentar.isEmpty) {
      _tampilkanPesan('Komentar tidak boleh kosong.');
      return;
    }

    if (_sedangMenyimpan) return;

    final pengguna = context.read<AuthProvider>().currentUser;

    if (pengguna == null) {
      _tampilkanPesan('Silakan login terlebih dahulu.');
      return;
    }

    setState(() => _sedangMenyimpan = true);

    try {
      final String? fotoPath = await _simpanFoto();

      final Review reviewBaru = Review(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        destinasiId: widget.destinasiId,
        namaPengguna: pengguna.nama,
        rating: _rating,
        komentar: komentar,
        fotoPath: fotoPath,
        tanggal: DateTime.now(),
      );

      // Pertahankan ulasan dari semua destinasi.
      final List<Review> semuaReview =
      await _storage.muatReviews();

      semuaReview.add(reviewBaru);
      await _storage.simpanReviews(semuaReview);

      if (!mounted) return;

      _komentarController.clear();

      setState(() {
        _rating = 5;
        _foto = null;
        _daftarReview.insert(0, reviewBaru);
        _sedangMenyimpan = false;
      });

      _tampilkanPesan('Ulasan berhasil disimpan.');
    } catch (e) {
      if (!mounted) return;

      setState(() => _sedangMenyimpan = false);
      _tampilkanPesan(
        'Ulasan gagal disimpan. Silakan coba lagi.',
      );
    }
  }

  void _tampilkanPesan(String pesan) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatTanggal(DateTime tanggal) {
    final String hari = tanggal.day.toString().padLeft(2, '0');
    final String bulan = tanggal.month.toString().padLeft(2, '0');

    return '$hari/$bulan/${tanggal.year}';
  }

  Widget _bintangRating({
    required int rating,
    required double ukuran,
    required ValueChanged<int>? onPilih,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final int nilai = index + 1;

        return IconButton(
          onPressed: onPilih == null
              ? null
              : () => onPilih(nilai),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 36,
          ),
          icon: Icon(
            nilai <= rating
                ? Icons.star_rounded
                : Icons.star_outline_rounded,
            color: Colors.amber,
            size: ukuran,
          ),
        );
      }),
    );
  }

  Widget _formReview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bagikan Pengalamanmu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Berikan penilaian untuk destinasi ini.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          const Text(
            'Rating Destinasi',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _bintangRating(
                rating: _rating,
                ukuran: 30,
                onPilih: (nilai) {
                  setState(() => _rating = nilai);
                },
              ),
              const SizedBox(width: 8),
              Text(
                '$_rating/5',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _komentarController,
            maxLines: 4,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Ceritakan pengalamanmu...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 8),
          if (_foto != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _foto!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  setState(() => _foto = null);
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Hapus Foto'),
              ),
            ),
          ],
          OutlinedButton.icon(
            onPressed: _sedangMenyimpan ? null : _pilihFoto,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Pilih Foto dari Galeri'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed:
              _sedangMenyimpan ? null : _kirimReview,
              icon: _sedangMenyimpan
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(Icons.send_rounded),
              label: Text(
                _sedangMenyimpan
                    ? 'Menyimpan...'
                    : 'Kirim Ulasan',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemReview(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor:
                AppColors.primary.withValues(alpha: 0.12),
                child: const Icon(
                  Icons.person_outline,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.namaPengguna,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatTanggal(review.tanggal),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _bintangRating(
                rating: review.rating,
                ukuran: 17,
                onPilih: null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.komentar,
            style: const TextStyle(height: 1.5),
          ),
          if (review.fotoPath != null &&
              File(review.fotoPath!).existsSync()) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(review.fotoPath!),
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final destinasi = context
        .watch<DestinasiProvider>()
        .getById(widget.destinasiId);

    if (destinasi == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ulasan Destinasi'),
        ),
        body: const Center(
          child: Text('Data destinasi tidak ditemukan.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Ulasan Destinasi'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _sedangMemuat
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            destinasi.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            destinasi.location,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          _formReview(),
          const SizedBox(height: 24),
          Text(
            'Ulasan Pengunjung (${_daftarReview.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (_daftarReview.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Belum ada ulasan untuk destinasi ini.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            ..._daftarReview.map(_itemReview),
        ],
      ),
    );
  }
}