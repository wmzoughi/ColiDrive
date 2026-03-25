// lib/services/cart_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../utils/constants.dart';
import 'auth_service.dart';

class CartService extends ChangeNotifier {
  List<CartItem> _items = [];
  String? _sessionId;
  bool _isLoading = false;
  String? _error;
  int? _cartId;

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.length;
  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  bool get isLoading => _isLoading;
  String? get error => _error;

  final AuthService _authService;

  CartService(this._authService) {
    _loadSessionId();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadCart();
    });
  }

  Future<void> _loadSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionId = prefs.getString('cart_session_id');
  }

  Future<void> _saveSessionId(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cart_session_id', sessionId);
    _sessionId = sessionId;
  }



  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_authService.token != null) {
      headers['Authorization'] = 'Bearer ${_authService.token}';
    }

    if (_sessionId != null) {
      headers['X-Session-ID'] = _sessionId!;
    }

    return headers;
  }

  // ✅ REGROUPER LES ARTICLES PAR FOURNISSEUR
  Map<int, Map<String, dynamic>> getItemsBySupplier() {
    Map<int, Map<String, dynamic>> result = {};

    for (var item in _items) {
      int supplierId = item.product.supplierId;
      String supplierName = item.product.supplierName ?? 'Fournisseur';

      if (!result.containsKey(supplierId)) {
        result[supplierId] = {
          'supplier_id': supplierId,
          'supplier_name': supplierName,
          'items': <CartItem>[],
          'subtotal': 0.0,
          'item_count': 0,
        };
      }

      result[supplierId]!['items'].add(item);
      result[supplierId]!['subtotal'] += item.totalPrice;
      result[supplierId]!['item_count'] += item.quantity;
    }

    return result;
  }

  // ✅ OBTENIR LE NOMBRE DE FOURNISSEURS DANS LE PANIER
  int get supplierCount {
    return getItemsBySupplier().length;
  }

  // ✅ OBTENIR LE SOUS-TOTAL PAR FOURNISSEUR
  Map<int, double> getSubtotalsBySupplier() {
    Map<int, double> result = {};

    for (var item in _items) {
      int supplierId = item.product.supplierId;
      result[supplierId] = (result[supplierId] ?? 0) + item.totalPrice;
    }

    return result;
  }

  // ✅ VÉRIFIER SI LE PANIER CONTIENT DES PRODUITS D'UN FOURNISSEUR SPÉCIFIQUE
  bool hasProductsFromSupplier(int supplierId) {
    return _items.any((item) => item.product.supplierId == supplierId);
  }

  // ✅ OBTENIR LES ARTICLES D'UN FOURNISSEUR SPÉCIFIQUE
  List<CartItem> getItemsBySupplierId(int supplierId) {
    return _items.where((item) => item.product.supplierId == supplierId).toList();
  }

  // ✅ SUPPRIMER TOUS LES ARTICLES D'UN FOURNISSEUR
  Future<void> removeSupplierItems(int supplierId) async {
    final itemsToRemove = getItemsBySupplierId(supplierId);

    for (var item in itemsToRemove) {
      await removeFromCart(item.id);
    }
  }

  // ✅ OBTENIR LE RÉCAPITULATIF PAR FOURNISSEUR POUR LE CHECKOUT
  List<Map<String, dynamic>> getCheckoutSummaryBySupplier() {
    Map<int, Map<String, dynamic>> bySupplier = {};

    for (var item in _items) {
      int supplierId = item.product.supplierId;

      if (!bySupplier.containsKey(supplierId)) {
        bySupplier[supplierId] = {
          'supplier_id': supplierId,
          'supplier_name': item.product.supplierName ?? 'Fournisseur',
          'items': <CartItem>[],
          'subtotal': 0.0,
          'tax': 0.0,
          'shipping': 50.0, // Frais de livraison par fournisseur
          'total': 0.0,
        };
      }

      bySupplier[supplierId]!['items'].add(item);
      bySupplier[supplierId]!['subtotal'] += item.totalPrice;
    }

    // Calculer les totaux pour chaque fournisseur
    return bySupplier.values.map((supplier) {
      double subtotal = supplier['subtotal'];
      double tax = subtotal * 0.20; // TVA 20%
      double shipping = supplier['shipping'];
      double total = subtotal + tax + shipping;

      return {
        'supplier_id': supplier['supplier_id'],
        'supplier_name': supplier['supplier_name'],
        'items': supplier['items'],
        'subtotal': subtotal,
        'tax': tax,
        'shipping': shipping,
        'total': total,
        'item_count': supplier['items'].fold(0, (sum, item) => sum + item.quantity),
      };
    }).toList();
  }

  // ✅ CHARGER LE PANIER DEPUIS L'API

  Future<void> loadCart() async {
    print('🔄 ===== CHARGEMENT DU PANIER =====');
    print('📤 Session ID: $_sessionId');
    print('📤 Token: ${_authService.token}');

    _setLoading(true);
    _clearError();

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/cart'),
        headers: _headers,
      );

      print('📥 Status code: ${response.statusCode}');
      print('📥 Réponse: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        final cartData = data['data']['cart'];
        _cartId = cartData['id'];

        if (data['data']['session_id'] != null && _sessionId == null) {
          print('✅ Nouveau session_id reçu: ${data['data']['session_id']}');
          await _saveSessionId(data['data']['session_id']);
        }

        _items = (cartData['items'] as List).map((itemJson) {
          return CartItem.fromJson(itemJson);
        }).toList();

        // Afficher les détails des conditionnements
        for (var item in _items) {
          if (item.packagingName != null) {
            print('   📦 ${item.product.name} - ${item.quantityDisplay} - ${item.totalPrice.toStringAsFixed(2)} MAD');
          }
        }

        print('✅ Panier chargé: ${_items.length} articles de $supplierCount fournisseur(s)');
        notifyListeners();
      } else {
        print('❌ Erreur chargement panier: ${data['message']}');
      }
    } catch (e) {
      print('💥 Exception: $e');
      _setError('Erreur réseau: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // ✅ AJOUTER AU PANIER
  Future<bool> addToCart(Product product, {int quantity = 1}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/cart/items'),
        headers: _headers,
        body: json.encode({
          'product_id': product.id,
          'quantity': quantity,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        if (data['data']['session_id'] != null && _sessionId == null) {
          await _saveSessionId(data['data']['session_id']);
        }

        await loadCart(); // Recharger le panier complet
        return true;
      } else {
        _setError(data['message'] ?? 'Erreur');
        return false;
      }
    } catch (e) {
      _setError('Erreur réseau: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ METTRE À JOUR LA QUANTITÉ
  Future<bool> updateQuantity(int cartItemId, int quantity, {double? priceAtTime}) async {
    if (quantity <= 0) {
      return removeFromCart(cartItemId);
    }

    _setLoading(true);

    try {
      final Map<String, dynamic> body = {'quantity': quantity};

      // 👈 SI UN PRIX EST FOURNI, L'AJOUTER À LA REQUÊTE
      if (priceAtTime != null) {
        body['price_at_time'] = priceAtTime;
      }

      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/cart/items/$cartItemId'),
        headers: _headers,
        body: json.encode(body),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        await loadCart();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _setLoading(false);
    }
  }

// ✅ INCRÉMENTER AVEC LE BON PRIX
  void incrementQuantity(int productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      final item = _items[index];
      final newQuantity = item.quantity + 1;
      _items[index].quantity = newQuantity;
      notifyListeners();
      // 👈 PASSER LE PRIX EFFECTIF DU CONDITIONNEMENT
      updateQuantity(item.id, newQuantity, priceAtTime: item.effectivePrice);
    }
  }

// ✅ DÉCRÉMENTER AVEC LE BON PRIX
  void decrementQuantity(int productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      final item = _items[index];
      if (item.quantity > 1) {
        final newQuantity = item.quantity - 1;
        _items[index].quantity = newQuantity;
        notifyListeners();
        // 👈 PASSER LE PRIX EFFECTIF DU CONDITIONNEMENT
        updateQuantity(item.id, newQuantity, priceAtTime: item.effectivePrice);
      } else {
        removeFromCart(item.id);
      }
    }
  }

  // ✅ SUPPRIMER DU PANIER
  Future<bool> removeFromCart(int cartItemId) async {
    _setLoading(true);

    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/cart/items/$cartItemId'),
        headers: _headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        await loadCart();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ VIDER LE PANIER
  Future<bool> clearCart() async {
    _setLoading(true);

    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/cart/clear'),
        headers: _headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        _items.clear();
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

  Future<bool> addToCartWithPackaging(Map<String, dynamic> item) async {
    final product = item['product'] as Product;
    final quantity = item['quantity'] as int;
    final packaging = item['packaging'] as ProductPackaging?;
    final totalPieces = item['total_pieces'] as int;
    final unitPrice = item['unit_price'] as double;

    print('🛒 AJOUT AU PANIER AVEC CONDITIONNEMENT');
    print('   Produit: ${product.name}');
    print('   Conditionnement: ${packaging?.name ?? "Pièce unitaire"}');
    print('   Quantité: $quantity');
    print('   Total pièces: $totalPieces');
    print('   Prix unitaire: $unitPrice');

    _setLoading(true);
    _clearError();

    try {
      final cartItem = {
        'product_id': product.id,
        'quantity': quantity,
        'packaging_id': packaging?.id,
        'packaging_name': packaging?.name,
        'packaging_quantity': packaging?.quantity ?? 1,
        'total_pieces': totalPieces,
        'unit_price': unitPrice,
      };

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/cart/items'),
        headers: _headers,
        body: json.encode(cartItem),
      );

      print('📥 Status: ${response.statusCode}');
      print('📥 Réponse: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        if (data['data']['session_id'] != null && _sessionId == null) {
          await _saveSessionId(data['data']['session_id']);
        }
        await loadCart();
        return true;
      } else {
        _setError(data['message'] ?? 'Erreur lors de l\'ajout');
        return false;
      }
    } catch (e) {
      print('💥 Exception: $e');
      _setError('Erreur réseau: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ RÉCAPITULATIF GLOBAL
  Map<String, double> getCheckoutSummary() {
    final subtotal = this.subtotal;
    final tax = subtotal * 0.20; // TVA 20%
    final shippingCost = 50.0 * supplierCount; // Frais fixes par fournisseur
    final total = subtotal + tax + shippingCost;

    return {
      'subtotal': subtotal,
      'tax': tax,
      'shipping': shippingCost,
      'total': total,
      'supplier_count': supplierCount.toDouble(),
    };
  }


  bool get isEmpty => _items.isEmpty;

  // ✅ VIDER LE PANIER LOCAL
  void clearLocalCart() {
    _items.clear();
    _cartId = null;
    notifyListeners();
    print('✅ Panier local vidé');
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