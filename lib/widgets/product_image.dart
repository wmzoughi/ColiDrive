// lib/widgets/product_image.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/constants.dart';

class ProductImage extends StatelessWidget {
  final int? productId;
  final String? imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final bool useCached;

  const ProductImage({
    Key? key,
    this.productId,
    this.imageUrl,
    this.width = 100,
    this.height = 100,
    this.fit = BoxFit.cover,
    this.useCached = true,
  }) : super(key: key);

  String? _getFullUrl() {
    final baseUrl = AppConstants.baseUrl.replaceFirst('/api', '');

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      if (imageUrl!.startsWith('http')) return imageUrl;
      if (imageUrl!.startsWith('/storage/')) return '$baseUrl$imageUrl';
      return '$baseUrl/$imageUrl';
    }

    if (productId != null) {
      return '$baseUrl/products/${productId}/image';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final fullUrl = _getFullUrl();

    if (fullUrl == null) {
      return _buildPlaceholder();
    }

    if (useCached) {
      return CachedNetworkImage(
        imageUrl: fullUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => _buildLoading(),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    }

    return Image.network(
      fullUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildLoading();
      },
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
    );
  }

  Widget _buildLoading() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Icon(
        Icons.image_not_supported,
        color: Colors.grey[400],
        size: width * 0.4,
      ),
    );
  }
}