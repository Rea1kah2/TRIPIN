class Destinasi {
  final String id;
  final String name;
  final String location;
  final String kategoriId;
  final double rating;
  final int price;
  /// Foto asli (aset). Kosong = belum ada foto; UI menampilkan penanda, bukan foto asal.
  final List<String> fotoAssets;
  final String description;
  /// Koordinat (WGS84). [lokasiPerkiraan] = titik mewakili area/kawasan, bukan pintu masuk pasti.
  final double lat;
  final double lng;
  final bool lokasiPerkiraan;
  final bool isFavorit;

  String? get fotoUtama => fotoAssets.isEmpty ? null : fotoAssets.first;

  const Destinasi({
    required this.id,
    required this.name,
    required this.location,
    required this.kategoriId,
    required this.rating,
    required this.price,
    this.fotoAssets = const [],
    required this.description,
    required this.lat,
    required this.lng,
    this.lokasiPerkiraan = false,
    this.isFavorit = false,
  });

  Destinasi copyWith({
    String? name,
    String? location,
    String? kategoriId,
    double? rating,
    int? price,
    List<String>? fotoAssets,
    String? description,
    double? lat,
    double? lng,
    bool? lokasiPerkiraan,
    bool? isFavorit,
  }) {
    return Destinasi(
      id: id,
      name: name ?? this.name,
      location: location ?? this.location,
      kategoriId: kategoriId ?? this.kategoriId,
      rating: rating ?? this.rating,
      price: price ?? this.price,
      fotoAssets: fotoAssets ?? this.fotoAssets,
      description: description ?? this.description,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      lokasiPerkiraan: lokasiPerkiraan ?? this.lokasiPerkiraan,
      isFavorit: isFavorit ?? this.isFavorit,
    );
  }
}
