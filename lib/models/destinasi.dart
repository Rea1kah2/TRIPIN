class Destinasi {
  final String id;
  final String name;
  final String location;
  final String kategoriId;
  final double rating;
  final int price;
  final String imageUrl;
  final String description;
  final double distnaceKm;
  final bool isFavorit;

  const Destinasi({
    required this.id,
    required this.name,
    required this.location,
    required this.kategoriId,
    required this.rating,
    required this.price,
    required this.imageUrl,
    required this.description,
    required this.distnaceKm,
    this.isFavorit = false,
  });

  Destinasi copyWith({
    String? name,
    String? location,
    String? kategoriId,
    double? rating,
    int? price,
    String? imageUrl,
    String? description,
    double? distanceKm,
    bool? isFavorit,
  }) {
    return Destinasi(
      id: id,
      name: name ?? this.name,
      location: location ?? this.location,
      kategoriId: kategoriId ?? this.kategoriId,
      rating: rating ?? this.rating,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      distnaceKm: distanceKm ?? this.distnaceKm,
      isFavorit: isFavorit ?? this.isFavorit,
    );
  }
}
