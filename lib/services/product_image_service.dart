// lib/services/product_image_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/product_image.dart';
import '../utils/constants.dart';
import 'auth_service.dart';

class ProductImageService extends ChangeNotifier {
  final AuthService _authService;
  List<ProductImage> _images = [];
  bool _isLoading = false;
  String? _error;

  List<ProductImage> get images => _images;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ProductImageService(this._authService);

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Authorization': 'Bearer ${_authService.token}',
  };

  Future<List<ProductImage>> loadProductImages(int productId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/supplier/products/$productId/images'),
        headers: _headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        _images = (data['data']['images'] as List)
            .map((img) => ProductImage.fromJson(img))
            .toList();
        notifyListeners();
        return _images;
      }
      return [];
    } catch (e) {
      _setError('Erreur réseau: ${e.toString()}');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> uploadImages(
      int productId,
      List<File> imageFiles, {
        int? primaryIndex,
      }) async {
    _setLoading(true);

    try {
      var uri = Uri.parse('${AppConstants.baseUrl}/supplier/products/$productId/images');
      var request = http.MultipartRequest('POST', uri);

      for (int i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];
        if (!await file.exists()) continue;

        request.files.add(
          await http.MultipartFile.fromPath(
            'images[]',
            file.path,
            contentType: MediaType('image', _getExtension(file.path)),
          ),
        );
      }

      if (primaryIndex != null) {
        request.fields['is_primary'] = primaryIndex.toString();
      }

      request.headers['Authorization'] = 'Bearer ${_authService.token}';
      request.headers['Accept'] = 'application/json';

      final response = await request.send();
      final responseData = await http.Response.fromStream(response);
      final data = json.decode(responseData.body);

      if (response.statusCode == 201 && data['success']) {
        await loadProductImages(productId);
        return {'success': true};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> setPrimaryImage(int productId, int imageId) async {
    _setLoading(true);

    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/supplier/products/$productId/images/$imageId/primary'),
        headers: _headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        await loadProductImages(productId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _setLoading(false);
    }
  }
// lib/services/product_image_service.dart (suite)

  Future<bool> deleteImage(int productId, int imageId) async {
    _setLoading(true);

    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/supplier/products/$productId/images/$imageId'),
        headers: _headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        _images.removeWhere((img) => img.id == imageId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> reorderImages(int productId, List<Map<String, dynamic>> orders) async {
    _setLoading(true);

    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/supplier/products/$productId/images/reorder'),
        headers: _headers,
        body: json.encode({'orders': orders}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        await loadProductImages(productId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _setLoading(false);
    }
  }

  String _getExtension(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg': return 'jpeg';
      case 'jpeg': return 'jpeg';
      case 'png': return 'png';
      case 'gif': return 'gif';
      default: return 'jpeg';
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
