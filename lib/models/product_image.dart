// lib/models/product_image.dart
import '../utils/constants.dart';
class ProductImage {
  final int id;
  final int productId;
  final String imagePath;
  final bool isPrimary;
  final int sortOrder;

  ProductImage({
    required this.id,
    required this.productId,
    required this.imagePath,
    required this.isPrimary,
    required this.sortOrder,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'],
      productId: json['product_id'],
      imagePath: json['image_path'],
      isPrimary: json['is_primary'] ?? false,
      sortOrder: json['sort_order'] ?? 0,
    );
  }

  String get fullUrl {
    final baseUrl = AppConstants.baseUrl.replaceFirst('/api', '');
    if (imagePath.startsWith('http')) return imagePath;
    if (imagePath.startsWith('/storage/')) return '$baseUrl$imagePath';
    return '$baseUrl/storage/$imagePath';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'image_path': imagePath,
      'is_primary': isPrimary,
      'sort_order': sortOrder,
    };
  }
}