
class Review {
  final String id;
  final String destinasiId;
  final String namaPengguna;
  final int rating;
  final String komentar;
  final String? fotoPath;
  final DateTime tanggal;

  const Review({
    required this.id,
    required this.destinasiId,
    required this.namaPengguna,
    required this.rating,
    required this.komentar,
    this.fotoPath,
    required this.tanggal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'destinasiId': destinasiId,
      'namaPengguna': namaPengguna,
      'rating': rating,
      'komentar': komentar,
      'fotoPath': fotoPath,
      'tanggal': tanggal.toIso8601String(),
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'] as String,
      destinasiId: map['destinasiId'] as String,
      namaPengguna: map['namaPengguna'] as String,
      rating: (map['rating'] as num).toInt(),
      komentar: map['komentar'] as String,
      fotoPath: map['fotoPath'] as String?,
      tanggal: DateTime.parse(map['tanggal'] as String),
    );
  }
}