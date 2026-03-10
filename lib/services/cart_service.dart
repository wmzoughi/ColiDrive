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

  // Charger le panier depuis l'API
  Future<void> loadCart() async {
    print('🔄 ===== CHARGEMENT DU PANIER =====');
    print('📤 Session ID: $_sessionId');
    print('📤 Token: ${_authService.token}');
    print('📤 Headers: $_headers');

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

        print('✅ Panier chargé: ${_items.length} articles');
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

  // Ajouter au panier
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

  // Mettre à jour la quantité
  Future<bool> updateQuantity(int cartItemId, int quantity) async {
    if (quantity <= 0) {
      return removeFromCart(cartItemId);
    }

    _setLoading(true);

    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/cart/items/$cartItemId'),
        headers: _headers,
        body: json.encode({'quantity': quantity}),
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

  // Supprimer du panier
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

  // Vider le panier
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

  Map<String, double> getCheckoutSummary() {
    final subtotal = this.subtotal;
    final tax = subtotal * 0.20; // TVA 20%
    final shippingCost = 50.0; // Frais fixes
    final total = subtotal + tax + shippingCost;

    return {
      'subtotal': subtotal,
      'tax': tax,
      'shipping': shippingCost,
      'total': total,
    };
  }

  // Méthodes locales (sans API) pour mise à jour instantanée
  void incrementQuantity(int cartItemId) {
    final index = _items.indexWhere((item) => item.id == cartItemId);
    if (index >= 0) {
      _items[index].quantity++;
      notifyListeners();
      // Sauvegarde en base via API
      updateQuantity(cartItemId, _items[index].quantity);
    }
  }

  void decrementQuantity(int cartItemId) {
    final index = _items.indexWhere((item) => item.id == cartItemId);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
        notifyListeners();
        updateQuantity(cartItemId, _items[index].quantity);
      } else {
        removeFromCart(cartItemId);
      }
    }
  }

  bool get isEmpty => _items.isEmpty;

  // ✅ NOUVELLE MÉTHODE POUR VIDER LE PANIER LOCAL
  void clearLocalCart() {
    _items.clear();
    _cartId = null;
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

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }
}