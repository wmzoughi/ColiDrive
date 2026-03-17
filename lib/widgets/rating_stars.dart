// lib/widgets/rating_stars.dart

import 'package:flutter/material.dart';
import '../utils/constants.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final bool showNumber;
  final Color color;

  const RatingStars({
    Key? key,
    required this.rating,
    this.size = 16,
    this.showNumber = true,
    this.color = Colors.amber,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Étoiles pleines
        ...List.generate(fullStars, (index) => Icon(
          Icons.star,
          color: color,
          size: size,
        )),

        // Demi-étoile
        if (hasHalfStar)
          Icon(
            Icons.star_half,
            color: color,
            size: size,
          ),

        // Étoiles vides
        ...List.generate(5 - fullStars - (hasHalfStar ? 1 : 0), (index) => Icon(
          Icons.star_border,
          color: color,
          size: size,
        )),

        if (showNumber)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              rating.toStringAsFixed(1),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }
}

class StarRatingSelector extends StatelessWidget {
  final int rating;
  final Function(int) onRatingChanged;
  final double size;

  const StarRatingSelector({
    Key? key,
    required this.rating,
    required this.onRatingChanged,
    this.size = 32,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () => onRatingChanged(index + 1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              index < rating ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: size,
            ),
          ),
        );
      }),
    );
  }
}