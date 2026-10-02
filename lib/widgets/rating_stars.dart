import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;

  const RatingStars({super.key, required this.rating, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, size: size, color: context.tripin.ratingStar),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: size - 2),
        ),
      ],
    );
  }
}
