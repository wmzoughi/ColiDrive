// lib/models/review.dart

import 'dart:convert';

class Review {
  final int id;
  final String merchantName;
  final int rating;
  final String? comment;
  final bool isAnonymous;
  final String createdAt;
  final DateTime createdAtRaw;

  Review({
    required this.id,
    required this.merchantName,
    required this.rating,
    this.comment,
    required this.isAnonymous,
    required this.createdAt,
    required this.createdAtRaw,
  });

  // Fonctions utilitaires pour la conversion
  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  static bool _toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return false;
  }

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: _toInt(json['id']),
      merchantName: json['merchant_name'] ?? '',
      rating: _toInt(json['rating']),
      comment: json['comment'],
      isAnonymous: _toBool(json['is_anonymous']),
      createdAt: json['created_at'] ?? '',
      createdAtRaw: DateTime.tryParse(json['created_at_raw'] ?? '') ?? DateTime.now(),
    );
  }

  String get ratingStars => '⭐' * rating;
  double get ratingPercent => rating / 5;
}

class SupplierReviewsData {
  final SupplierInfo supplier;
  final List<Review> reviews;
  final PaginationInfo pagination;

  SupplierReviewsData({
    required this.supplier,
    required this.reviews,
    required this.pagination,
  });

  factory SupplierReviewsData.fromJson(Map<String, dynamic> json) {
    return SupplierReviewsData(
      supplier: SupplierInfo.fromJson(json['supplier'] ?? {}),
      reviews: (json['reviews'] as List? ?? [])
          .map((r) => Review.fromJson(r as Map<String, dynamic>))
          .toList(),
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),
    );
  }
}

class SupplierInfo {
  final int id;
  final String name;
  final double averageRating;
  final int reviewsCount;
  final Map<int, int> ratingDistribution;

  SupplierInfo({
    required this.id,
    required this.name,
    required this.averageRating,
    required this.reviewsCount,
    required this.ratingDistribution,
  });

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  factory SupplierInfo.fromJson(Map<String, dynamic> json) {
    // Conversion sécurisée de ratingDistribution
    Map<int, int> distribution = {};
    if (json['rating_distribution'] != null) {
      try {
        final dist = json['rating_distribution'] as Map;
        dist.forEach((key, value) {
          int k = _toInt(key);
          int v = _toInt(value);
          distribution[k] = v;
        });
      } catch (e) {
        print('❌ Erreur parsing rating_distribution: $e');
      }
    }

    return SupplierInfo(
      id: _toInt(json['id']),
      name: json['name'] ?? '',
      averageRating: _toDouble(json['average_rating']),
      reviewsCount: _toInt(json['reviews_count']),
      ratingDistribution: distribution,
    );
  }
}

class PaginationInfo {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  PaginationInfo({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: _toInt(json['current_page']),
      lastPage: _toInt(json['last_page']),
      perPage: _toInt(json['per_page']),
      total: _toInt(json['total']),
    );
  }
}