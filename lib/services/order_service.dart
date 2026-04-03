// lib/services/order_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/order.dart';
import '../models/order_request.dart';
import '../utils/constants.dart';
import 'auth_service.dart';
import 'cart_service.dart';

class OrderService extends ChangeNotifier {
  final AuthService _authService;
  final CartService _cartService;

  bool _isLoading = false;
  String? _error;
  Order? _lastOrder;
  List<Order> _orders = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  Order? get lastOrder => _lastOrder;
  List<Order> get orders => List.unmodifiable(_orders);

  OrderService(this._authService, this._cartService);

  // Déterminer le bon endpoint selon le type d'utilisateur
  String get _baseOrderEndpoint {
    if (_authService.currentUser?.userType == 'fournisseur') {
      return '${AppConstants.baseUrl}/supplier/orders';
    } else {
      return '${AppConstants.baseUrl}/merchant/orders';
    }
  }

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_authService.token != null) {
      headers['Authorization'] = 'Bearer ${_authService.token}';
    }

    return headers;
  }

  Future<Map<String, dynamic>> createOrder(OrderRequest orderRequest) async {
    _setLoading(true);
    _clearError();

    try {
      print('📤 Création de commande...');
      print('📤 Endpoint: $_baseOrderEndpoint');

      final response = await http.post(
        Uri.parse(_baseOrderEndpoint),
        headers: _headers,
        body: json.encode(orderRequest.toJson()),
      );

      print('📥 Statut: ${response.statusCode}');
      print('📥 Réponse brute: ${response.body}');

      // Vérifier si la réponse est vide
      if (response.body.isEmpty) {
        _setError('Réponse vide du serveur');
        _setLoading(false);
        return {
          'success': false,
          'message': 'Réponse vide du serveur',
        };
      }

      // Essayer de parser le JSON
      dynamic data;
      try {
        data = json.decode(response.body);
      } catch (e) {
        print('💥 Erreur de parsing JSON: $e');
        _setError('Erreur de format de réponse');
        _setLoading(false);
        return {
          'success': false,
          'message': 'Erreur de format de réponse',
        };
      }

      // Vérifier que data est bien un Map
      if (data is! Map<String, dynamic>) {
        print('💥 La réponse n\'est pas un Map: ${data.runtimeType}');
        _setError('Format de réponse invalide');
        _setLoading(false);
        return {
          'success': false,
          'message': 'Format de réponse invalide',
        };
      }

      if (response.statusCode == 201 && data['success'] == true) {
        // ✅ CORRECTION: Gérer correctement la réponse avec "orders" (liste)
        List<Order> createdOrders = [];

        if (data['data'] != null) {
          // Cas où la réponse contient "orders" (liste)
          if (data['data']['orders'] != null && data['data']['orders'] is List) {
            final ordersList = data['data']['orders'] as List;
            print('📦 Nombre de commandes créées: ${ordersList.length}');

            for (var orderJson in ordersList) {
              try {
                // ✅ Créer une copie modifiable du JSON
                Map<String, dynamic> orderMap = Map<String, dynamic>.from(orderJson);

                // ✅ S'assurer que 'supplier' existe (peut être null)
                if (!orderMap.containsKey('supplier')) {
                  orderMap['supplier'] = null;
                }

                final order = Order.fromJson(orderMap);
                createdOrders.add(order);
                print('✅ Commande parsée: ${order.orderNumber}');
              } catch (e) {
                print('❌ Erreur parsing commande individuelle: $e');
              }
            }

            if (createdOrders.isNotEmpty) {
              _lastOrder = createdOrders.first;
            }
          }
          // Cas où la réponse contient "order" (objet unique)
          else if (data['data']['order'] != null) {
            _lastOrder = Order.fromJson(data['data']['order']);
            createdOrders.add(_lastOrder!);
          }
        }

        // ✅ VIDER LE PANIER LOCAL APRÈS COMMANDE RÉUSSIE
        _cartService.clearLocalCart();

        // ✅ FORCER LE RECHARGEMENT DU PANIER DEPUIS L'API
        await _cartService.loadCart();

        _setLoading(false);

        // ✅ Retourner les informations des commandes créées
        return {
          'success': true,
          'order': _lastOrder,
          'orders': createdOrders,
          'order_count': createdOrders.length,
          'order_number': createdOrders.isNotEmpty ? createdOrders.first.orderNumber : null,
          'order_numbers': createdOrders.map((o) => o.orderNumber).toList(),
        };
      } else {
        String errorMessage = data['message'] ?? 'Erreur lors de la création de la commande';
        _setError(errorMessage);
        _setLoading(false);
        return {
          'success': false,
          'message': errorMessage,
          'errors': data['errors'] ?? null,
        };
      }
    } catch (e) {
      print('💥 Exception: $e');
      print('💥 Type: ${e.runtimeType}');
      _setError('Erreur réseau: ${e.toString()}');
      _setLoading(false);
      return {
        'success': false,
        'message': 'Erreur réseau: ${e.toString()}',
      };
    }
  }

  Future<List<Order>> getMyOrders({String? status}) async {
    _setLoading(true);
    _clearError();

    try {
      String url = _baseOrderEndpoint;
      if (status != null && status.isNotEmpty) {
        url += '?status=$status';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        final List<dynamic> ordersJson = data['data']['data'] ?? data['data'] ?? [];
        _orders = ordersJson.map((json) => Order.fromJson(json)).toList();
        _setLoading(false);
        return _orders;
      } else {
        _setError(data['message'] ?? 'Erreur');
        _setLoading(false);
        return [];
      }
    } catch (e) {
      _setError('Erreur réseau: ${e.toString()}');
      _setLoading(false);
      return [];
    }
  }

  Future<Order?> getOrderDetails(int orderId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await http.get(
        Uri.parse('$_baseOrderEndpoint/$orderId'),
        headers: _headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        final order = Order.fromJson(data['data']);
        _setLoading(false);
        return order;
      } else {
        _setError(data['message'] ?? 'Commande non trouvée');
        _setLoading(false);
        return null;
      }
    } catch (e) {
      _setError('Erreur réseau: ${e.toString()}');
      _setLoading(false);
      return null;
    }
  }

  Future<bool> cancelOrder(int orderId, String reason) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await http.post(
        Uri.parse('$_baseOrderEndpoint/$orderId/cancel'),
        headers: _headers,
        body: json.encode({'reason': reason}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        await getMyOrders(); // Recharger les commandes
        _setLoading(false);
        return true;
      } else {
        _setError(data['message'] ?? 'Erreur lors de l\'annulation');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Erreur réseau: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> prepareOrder(int orderId) async {
    _setLoading(true);
    _clearError();

    try {
      String prepareEndpoint = '$_baseOrderEndpoint/$orderId/prepare';
      print('📤 Préparation de commande: $prepareEndpoint');

      final response = await http.post(
        Uri.parse(prepareEndpoint),
        headers: _headers,
      );

      print('📥 Statut: ${response.statusCode}');
      print('📥 Réponse: ${response.body}');

      if (response.body.isEmpty) {
        _setError('Réponse vide du serveur');
        _setLoading(false);
        return false;
      }

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        await getMyOrders(); // Recharger les commandes
        _setLoading(false);
        return true;
      } else {
        _setError(data['message'] ?? 'Erreur lors du passage en préparation');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      print('💥 Exception: $e');
      _setError('Erreur réseau: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deliverOrder(int orderId) async {
    _setLoading(true);
    _clearError();

    try {
      String deliverEndpoint = '$_baseOrderEndpoint/$orderId/deliver';
      print('📤 Mise en livraison: $deliverEndpoint');

      final response = await http.post(
        Uri.parse(deliverEndpoint),
        headers: _headers,
      );

      print('📥 Statut: ${response.statusCode}');
      print('📥 Réponse: ${response.body}');

      if (response.body.isEmpty) {
        _setError('Réponse vide du serveur');
        _setLoading(false);
        return false;
      }

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        await getMyOrders(); // Recharger les commandes
        _setLoading(false);
        return true;
      } else {
        _setError(data['message'] ?? 'Erreur lors de la mise en livraison');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      print('💥 Exception: $e');
      _setError('Erreur réseau: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> confirmOrder(int orderId) async {
    _setLoading(true);
    _clearError();

    try {
      String confirmEndpoint = '$_baseOrderEndpoint/$orderId/confirm';
      print('📤 Confirmation de commande: $confirmEndpoint');

      final response = await http.post(
        Uri.parse(confirmEndpoint),
        headers: _headers,
      );

      print('📥 Statut: ${response.statusCode}');
      print('📥 Réponse: ${response.body}');

      // Vérifier si la réponse est vide
      if (response.body.isEmpty) {
        _setError('Réponse vide du serveur');
        _setLoading(false);
        return false;
      }

      // Parser le JSON
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        await getMyOrders(); // Recharger les commandes
        _setLoading(false);
        return true;
      } else {
        _setError(data['message'] ?? 'Erreur lors de la confirmation');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      print('💥 Exception: $e');
      _setError('Erreur réseau: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<Map<String, dynamic>> getOrderStats() async {
    try {
      String statsEndpoint = _authService.currentUser?.userType == 'fournisseur'
          ? '${AppConstants.baseUrl}/supplier/orders/stats'
          : '${AppConstants.baseUrl}/merchant/orders/stats';

      print('📊 Stats endpoint: $statsEndpoint');

      final response = await http.get(
        Uri.parse(statsEndpoint),
        headers: _headers,
      );

      print('📥 Stats response: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print('✅ Stats reçues: ${data['data']}');
        return data['data'] ?? {};
      } else {
        print('❌ Erreur stats: ${data['message']}');
        return {};
      }
    } catch (e) {
      print('❌ Exception stats: $e');
      return {};
    }
  }

  Future<List<Order>> getRecentOrders() async {
    try {
      String recentEndpoint = _authService.currentUser?.userType == 'fournisseur'
          ? '${AppConstants.baseUrl}/supplier/orders/recent'
          : '${AppConstants.baseUrl}/merchant/orders/recent';

      final response = await http.get(
        Uri.parse(recentEndpoint),
        headers: _headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        final List<dynamic> ordersJson = data['data'];
        return ordersJson.map((json) => Order.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> trackOrder(String orderNumber) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/orders/track/$orderNumber'),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Commande non trouvée',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur réseau: ${e.toString()}',
      };
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    // ✅ Différer la notification pour éviter les erreurs de build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }


  void _clearError() {
    _error = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
  void _setError(String error) {
    _error = error;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}