class RencanaPerjalanan {
  final String id;
  final String judul;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final List<String> daftarDestinasiId;
  final String catatan;

  const RencanaPerjalanan({
    required this.id,
    required this.judul,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.daftarDestinasiId,
    this.catatan = '',
  });

  RencanaPerjalanan copyWith({
    String? judul,
    DateTime? tanggalMulai,
    DateTime? tanggalSelesai,
    List<String>? daftarDestinasiId,
    String? catatan,
  }) {
    return RencanaPerjalanan(
      id: id,
      judul: judul ?? this.judul,
      tanggalMulai: tanggalMulai ?? this.tanggalMulai,
      tanggalSelesai: tanggalSelesai ?? this.tanggalSelesai,
      daftarDestinasiId: daftarDestinasiId ?? this.daftarDestinasiId,
      catatan: catatan ?? this.catatan,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'judul': judul,
        'tanggalMulai': tanggalMulai.toIso8601String(),
        'tanggalSelesai': tanggalSelesai.toIso8601String(),
        'daftarDestinasiId': daftarDestinasiId,
        'catatan': catatan,
      };

  factory RencanaPerjalanan.fromJson(Map<String, dynamic> json) => RencanaPerjalanan(
        id: json['id'] as String,
        judul: json['judul'] as String,
        tanggalMulai: DateTime.parse(json['tanggalMulai'] as String),
        tanggalSelesai: DateTime.parse(json['tanggalSelesai'] as String),
        daftarDestinasiId: List<String>.from(json['daftarDestinasiId'] as List),
        catatan: json['catatan'] as String? ?? '',
      );
}