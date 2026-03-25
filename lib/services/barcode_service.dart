// lib/services/barcode_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/product_offer.dart';
import '../utils/constants.dart';
import 'auth_service.dart';

class BarcodeService extends ChangeNotifier {
  final AuthService _authService;

  ScannedProduct? _scannedProduct;
  bool _isLoading = false;
  String? _error;

  ScannedProduct? get scannedProduct => _scannedProduct;
  bool get isLoading => _isLoading;
  String? get error => _error;

  BarcodeService(this._authService);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_authService.token != null) 'Authorization': 'Bearer ${_authService.token}',
  };

  Future<bool> scanBarcode(String barcode) async {
    _setLoading(true);
    _clearError();

    try {
      print('📸 Scan du code-barres: $barcode');

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/products/barcode/$barcode'),
        headers: _headers,
      );

      print('📥 Statut: ${response.statusCode}');
      print('📥 Réponse: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        _scannedProduct = ScannedProduct.fromJson(data['data']);
        _setLoading(false);
        return true;
      } else {
        _error = data['message'] ?? 'Produit non trouvé';
        _scannedProduct = null;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      print('❌ Erreur: $e');
      _error = 'Erreur réseau: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  Future<List<ProductOffer>> getOffers(int productId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/products/$productId/offers'),
        headers: _headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        final offers = (data['data']['offers'] as List)
            .map((o) => ProductOffer.fromJson(o))
            .toList();
        return offers;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  void clear() {
    _scannedProduct = null;
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}