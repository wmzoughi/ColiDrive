// lib/services/review_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/review.dart';
import '../utils/constants.dart';
import 'auth_service.dart';

class ReviewService extends ChangeNotifier {
  final AuthService _authService;

  bool _isLoading = false;
  String? _error;
  SupplierReviewsData? _supplierReviews;
  Map<String, dynamic>? _globalStats;

  bool get isLoading => _isLoading;
  String? get error => _error;
  SupplierReviewsData? get supplierReviews => _supplierReviews;
  Map<String, dynamic>? get globalStats => _globalStats;

  ReviewService(this._authService);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_authService.token != null) 'Authorization': 'Bearer ${_authService.token}',
  };

  // Obtenir les avis d'un fournisseur
  Future<bool> getSupplierReviews(int supplierId, {int page = 1}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/reviews/supplier/$supplierId?page=$page'),
        headers: _headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        _supplierReviews = SupplierReviewsData.fromJson(data['data']);
        _setLoading(false);
        return true;
      } else {
        _setError(data['message'] ?? 'Erreur');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Erreur réseau: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Ajouter ou mettre à jour un avis
  Future<Map<String, dynamic>> submitReview({
    required int supplierId,
    required int rating,
    String? comment,
    bool isAnonymous = false,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/reviews'),
        headers: _headers,
        body: json.encode({
          'supplier_id': supplierId,
          'rating': rating,
          'comment': comment,
          'is_anonymous': isAnonymous,
        }),
      );

      final data = json.decode(response.body);
      _setLoading(false);

      if (response.statusCode == 201 && data['success']) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      _setLoading(false);
      return {
        'success': false,
        'message': 'Erreur réseau: ${e.toString()}',
      };
    }
  }

  // Vérifier si l'utilisateur a déjà noté
  Future<Map<String, dynamic>> checkReview(int supplierId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/reviews/check/$supplierId'),
        headers: _headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'has_reviewed': data['data']['has_reviewed'],
          'review': data['data']['review'],
        };
      } else {
        return {
          'success': false,
          'has_reviewed': false,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'has_reviewed': false,
      };
    }
  }

  // Supprimer un avis
  Future<bool> deleteReview(int reviewId) async {
    _setLoading(true);

    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/reviews/$reviewId'),
        headers: _headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        _setLoading(false);
        return true;
      } else {
        _setError(data['message'] ?? 'Erreur');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Erreur réseau: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Obtenir les statistiques globales
  Future<bool> getGlobalStats() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/reviews/stats'),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        _globalStats = data['data'];
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }
}