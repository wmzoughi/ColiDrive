// lib/models/category.dart
class Category {
  final int id;
  final String name;
  final String? completeName;
  final int? parentId;
  final String? description;
  final int? popularRank;
  final bool? isFeatured;
  final String? imageUrl;

  Category({
    required this.id,
    required this.name,
    this.completeName,
    this.parentId,
    this.description,
    this.popularRank,
    this.isFeatured,
    this.imageUrl,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'] ?? '',
      completeName: json['complete_name'],
      parentId: json['parent_id'],
      description: json['description'],
      popularRank: json['popular_rank'],
      isFeatured: json['is_featured'],
      imageUrl: json['image_url'],
    );
  }
}