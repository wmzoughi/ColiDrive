// lib/widgets/image_carousel.dart

import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'product_image.dart';

class ImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final double height;
  final int? productId;

  const ImageCarousel({
    Key? key,
    required this.imageUrls,
    this.height = 300,
    this.productId,
  }) : super(key: key);

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty && widget.productId == null) {
      return Container(
        height: widget.height,
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
        ),
      );
    }

    if (widget.imageUrls.isEmpty && widget.productId != null) {
      return Container(
        height: widget.height,
        color: Colors.white,
        child: ProductImage(
          productId: widget.productId,
          width: double.infinity,
          height: widget.height,
          fit: BoxFit.contain,
        ),
      );
    }

    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: widget.height,
            viewportFraction: 1,
            enableInfiniteScroll: widget.imageUrls.length > 1,
            autoPlay: widget.imageUrls.length > 1,
            autoPlayInterval: const Duration(seconds: 3),
            onPageChanged: (index, reason) {
              setState(() => _currentIndex = index);
            },
          ),
          items: widget.imageUrls.map((url) {
            return Builder(
              builder: (BuildContext context) {
                return ProductImage(
                  imageUrl: url,
                  width: double.infinity,
                  height: widget.height,
                  fit: BoxFit.contain,
                );
              },
            );
          }).toList(),
        ),
        if (widget.imageUrls.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.imageUrls.asMap().entries.map((entry) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (_currentIndex == entry.key)
                        ? Colors.blue
                        : Colors.grey.shade300,
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}