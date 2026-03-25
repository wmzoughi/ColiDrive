// lib/services/product_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Pour MediaType
import '../models/product.dart';
import '../models/category.dart';
import '../utils/constants.dart';
import 'auth_service.dart';
import '../l10n/app_localizations.dart';

class ProductService extends ChangeNotifier {
  List<Product> _products = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  List<Product> get products => _products;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  final AuthService _authService;

  ProductService(this._authService);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer ${_authService.token}',
  };

  // ===== PRODUITS =====

// Pour le commerçant (tous les produits)
  Future<void> loadProducts({String? search, int? categoryId, bool reset = false}) async {
    if (reset) {
      _products = [];
      _currentPage = 1;
      _hasMore = true;
    }

    if (!_hasMore || _isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      String url = '${AppConstants.baseUrl}/products?page=$_currentPage&per_page=20';
      if (search != null && search.isNotEmpty) {
        url += '&search=$search';
      }
      if (categoryId != null) {
        url += '&categ_id=$categoryId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        final List productsJson = data['data']['data'] ?? data['data'] ?? [];
        final newProducts = productsJson.map((p) => Product.fromJson(p)).toList();

        _products.addAll(newProducts);
        _currentPage++;
        _hasMore = newProducts.length == 20;

        notifyListeners();
      } else {
        _setError(data['message'] ?? 'Erreur de chargement');
      }
    } catch (e) {
      _setError('Erreur réseau: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

// ✅ NOUVELLE MÉTHODE POUR LE FOURNISSEUR (ses propres produits)
  Future<void> loadSupplierProducts({String? search, int? categoryId, bool reset = false}) async {
    print('🚀 CHARGEMENT DES PRODUITS FOURNISSEUR');
    print('👤 User ID: ${_authService.currentUser?.id}');

    if (reset) {
      _products = [];
      _currentPage = 1;
      _hasMore = true;
    }

    if (!_hasMore || _isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      String url = '${AppConstants.baseUrl}/supplier/products?page=$_currentPage&per_page=20';
      print('🔍 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      print('📥 Status: ${response.statusCode}');
      print('📥 Réponse: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        final List productsJson = data['data']['data'] ?? data['data'] ?? [];
        print('📦 Produits reçus: ${productsJson.length}');

        final newProducts = productsJson.map((p) => Product.fromJson(p)).toList();

        _products.addAll(newProducts);
        _currentPage++;
        _hasMore = newProducts.length == 20;

        notifyListeners();
      } else {
        _setError(data['message'] ?? 'Erreur de chargement');
      }
    } catch (e) {
      print('❌ Erreur: $e');
      _setError('Erreur réseau: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  Future<List<Product>> getProductsBySupplier(int supplierId, {int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/products/supplier/$supplierId?page=$page'),
        headers: _headers,
      );
      final data = json.decode(response.body);
      if (data['success']) {
        final List productsJson = data['data']['data'] ?? [];
        return productsJson.map((p) => Product.fromJson(p)).toList();
      }
      return [];
    } catch (e) {
      print('Erreur: $e');
      return [];
    }
  }

  String formatMAD(double amount, BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    // Format: 1.234,56 MAD ou ١٬٢٣٤٫٥٦ درهم
    return '${amount.toStringAsFixed(2).replaceAll('.', ',')} ${localizations.currency}';
  }
  Future<Product?> getProduct(int id) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/products/$id'),
        headers: _headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return Product.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting product: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> addProduct(Map<String, dynamic> productData) async {
    _setLoading(true);
    _clearError();

    try {
      print('🚀 DÉBUT addProduct');
      print('📤 URL: ${AppConstants.baseUrl}/supplier/products');
      print('📤 Headers: $_headers');
      print('📤 Données envoyées: ${json.encode(productData)}');

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/supplier/products'),
        headers: _headers,
        body: json.encode(productData),
      );

      print('📥 Status code: ${response.statusCode}');
      print('📥 Réponse brute: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 201 && data['success']) {
        print('✅ Succès !');
        _products = [];
        _currentPage = 1;
        await loadProducts();
        return {'success': true, 'product': Product.fromJson(data['data'])};
      } else {
        print('❌ Échec: ${data['message']}');
        print('❌ Erreurs: ${data['errors']}');
        return {
          'success': false,
          'errors': data['errors'] ?? {'general': [data['message'] ?? 'Erreur']}
        };
      }
    } catch (e) {
      print('💥 Exception: $e');
      return {
        'success': false,
        'errors': {'general': ['Erreur réseau: ${e.toString()}']}
      };
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> updateProduct(int id, Map<String, dynamic> productData) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/supplier/products/$id'),
        headers: _headers,
        body: json.encode(productData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        // Mettre à jour dans la liste locale
        final index = _products.indexWhere((p) => p.id == id);
        if (index != -1) {
          _products[index] = Product.fromJson(data['data']);
          notifyListeners();
        }
        return {'success': true, 'product': Product.fromJson(data['data'])};
      } else {
        return {
          'success': false,
          'errors': data['errors'] ?? {'general': [data['message'] ?? 'Erreur']}
        };
      }
    } catch (e) {
      return {
        'success': false,
        'errors': {'general': ['Erreur réseau: ${e.toString()}']}
      };
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteProduct(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/supplier/products/$id'),
        headers: _headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        _products.removeWhere((p) => p.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting product: $e');
      return false;
    }
  }

  // ===== CATÉGORIES =====

  Future<void> loadCategories() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/categories'),
        headers: _headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        _categories = (data['data'] as List)
            .map((c) => Category.fromJson(c))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  Future<Map<String, dynamic>> addCategory(Map<String, dynamic> categoryData) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/categories'),
        headers: _headers,
        body: json.encode(categoryData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201 && data['success']) {
        await loadCategories(); // Recharger les catégories
        return {'success': true, 'category': data['data']};
      } else {
        return {
          'success': false,
          'errors': data['errors'] ?? {'general': [data['message'] ?? 'Erreur']}
        };
      }
    } catch (e) {
      return {
        'success': false,
        'errors': {'general': ['Erreur réseau: ${e.toString()}']}
      };
    }
  }

  // lib/services/product_service.dart

  Future<Map<String, dynamic>> uploadProductImage(int productId, File imageFile) async {
    _setLoading(true);

    try {
      print('📤 Uploading image for product $productId');

      var uri = Uri.parse('${AppConstants.baseUrl}/supplier/products/$productId/image');
      var request = http.MultipartRequest('POST', uri);

      // 👉 Vérifie que le fichier existe
      if (!await imageFile.exists()) {
        return {'success': false, 'message': 'Fichier introuvable'};
      }

      // 👉 Ajoute l'image avec la clé 'image' (important)
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',  // Cette clé doit correspondre à ce que Laravel attend
          imageFile.path,
        ),
      );

      // 👉 Ajoute le token
      request.headers['Authorization'] = 'Bearer ${_authService.token}';
      request.headers['Accept'] = 'application/json';

      var response = await request.send();
      var responseData = await http.Response.fromStream(response);
      var data = json.decode(responseData.body);

      print('📥 Status: ${response.statusCode}');
      print('📥 Response: ${responseData.body}');

      if (response.statusCode == 200) {
        return {'success': true, 'image_url': data['data']['image_url']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur'};
      }
    } catch (e) {
      print('❌ Error: $e');
      return {'success': false, 'message': e.toString()};
    } finally {
      _setLoading(false);
    }
  }


  Future<Map<String, dynamic>> addPackaging(int productId, Map<String, dynamic> packagingData) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/supplier/products/$productId/packagings'),
        headers: _headers,
        body: json.encode(packagingData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201 && data['success']) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'errors': data['errors'] ?? {'general': [data['message'] ?? 'Erreur']}
        };
      }
    } catch (e) {
      return {
        'success': false,
        'errors': {'general': ['Erreur réseau: ${e.toString()}']}
      };
    } finally {
      _setLoading(false);
    }
  }

  Future<List<dynamic>> getProductPackagings(int productId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/supplier/products/$productId/packagings'),
        headers: _headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return data['data']['packagings'] ?? [];
      }
      return [];
    } catch (e) {
      print('Erreur chargement conditionnements: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> updatePackaging(int productId, int packagingId, Map<String, dynamic> packagingData) async {
    _setLoading(true);

    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/supplier/products/$productId/packagings/$packagingId'),
        headers: _headers,
        body: json.encode(packagingData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'errors': data['errors'] ?? {'general': [data['message'] ?? 'Erreur']}
        };
      }
    } catch (e) {
      return {
        'success': false,
        'errors': {'general': ['Erreur réseau: ${e.toString()}']}
      };
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deletePackaging(int productId, int packagingId) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/supplier/products/$productId/packagings/$packagingId'),
        headers: _headers,
      );

      final data = json.decode(response.body);
      return response.statusCode == 200 && data['success'];
    } catch (e) {
      print('Erreur suppression conditionnement: $e');
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