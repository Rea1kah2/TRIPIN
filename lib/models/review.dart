/// Ulasan satu pengguna untuk satu destinasi (bintang wajib, komentar opsional).
class Review {
  static const maksKomentar = 500;

  final String destinasiId;
  final String userId;
  final String namaPenulis;
  final int rating; // 1..5
  final String komentar;
  final DateTime dibuat;
  final DateTime diubah;

  const Review({
    required this.destinasiId,
    required this.userId,
    required this.namaPenulis,
    required this.rating,
    this.komentar = '',
    required this.dibuat,
    required this.diubah,
  });

  /// Satu ulasan per pengguna per destinasi.
  String get id => '${destinasiId}_$userId';

  bool get diedit => diubah.isAfter(dibuat);

  Review copyWith({int? rating, String? komentar, DateTime? diubah, String? namaPenulis}) => Review(
        destinasiId: destinasiId,
        userId: userId,
        namaPenulis: namaPenulis ?? this.namaPenulis,
        rating: rating ?? this.rating,
        komentar: komentar ?? this.komentar,
        dibuat: dibuat,
        diubah: diubah ?? this.diubah,
      );

  Map<String, dynamic> toJson() => {
        'destinasiId': destinasiId,
        'userId': userId,
        'namaPenulis': namaPenulis,
        'rating': rating,
        'komentar': komentar,
        'dibuat': dibuat.toIso8601String(),
        'diubah': diubah.toIso8601String(),
      };

  /// Mengembalikan null untuk data rusak (dilewati, tidak membuat aplikasi crash).
  static Review? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final destinasiId = json['destinasiId'];
    final userId = json['userId'];
    final rating = json['rating'];
    if (destinasiId is! String || userId is! String || rating is! num) return null;
    final r = rating.toInt();
    if (r < 1 || r > 5) return null;
    final dibuat = DateTime.tryParse('${json['dibuat']}') ?? DateTime.now();
    return Review(
      destinasiId: destinasiId,
      userId: userId,
      namaPenulis: (json['namaPenulis'] as String?)?.trim().isNotEmpty == true ? json['namaPenulis'] as String : 'Traveler',
      rating: r,
      komentar: (json['komentar'] as String?) ?? '',
      dibuat: dibuat,
      diubah: DateTime.tryParse('${json['diubah']}') ?? dibuat,
    );
  }
}

/// Ringkasan ulasan satu destinasi.
class RingkasanUlasan {
  final int jumlah;
  final double rataRata; // 0 bila belum ada ulasan
  final List<int> sebaran; // indeks 0..4 = jumlah untuk 1..5 bintang

  const RingkasanUlasan({required this.jumlah, required this.rataRata, required this.sebaran});

  static const kosong = RingkasanUlasan(jumlah: 0, rataRata: 0, sebaran: [0, 0, 0, 0, 0]);

  factory RingkasanUlasan.dari(Iterable<Review> ulasan) {
    final sebaran = [0, 0, 0, 0, 0];
    var total = 0;
    var n = 0;
    for (final u in ulasan) {
      sebaran[u.rating - 1]++;
      total += u.rating;
      n++;
    }
    return n == 0 ? kosong : RingkasanUlasan(jumlah: n, rataRata: total / n, sebaran: sebaran);
  }
}
