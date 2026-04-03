import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../utils/constants.dart';
import 'cart_service.dart';
import 'order_service.dart';
import 'dashboard_service.dart';
import 'notification_service.dart';
import 'push_notification_service.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _error;

  // Références aux services
  CartService? _cartService;
  OrderService? _orderService;
  DashboardService? _dashboardService;
  NotificationService? _notificationService;
  PushNotificationService? _pushNotificationService;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _currentUser != null;

  void setCartService(CartService cartService) {
    _cartService = cartService;
  }

  void setOrderService(OrderService orderService) {
    _orderService = orderService;
  }

  void setDashboardService(DashboardService dashboardService) {
    _dashboardService = dashboardService;
  }

  void setNotificationService(NotificationService notificationService) {
    _notificationService = notificationService;
  }

  void setPushNotificationService(PushNotificationService pushNotificationService) {
    _pushNotificationService = pushNotificationService;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      if (_token != null) {
        final userJson = prefs.getString('user_data');
        if (userJson != null) {
          _currentUser = User.fromJson(json.decode(userJson));
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Init error: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      String? sessionId;
      final prefs = await SharedPreferences.getInstance();
      sessionId = prefs.getString('cart_session_id');

      print('🔐 Tentative de login avec session_id: $sessionId');

      final Map<String, String> headers = {'Content-Type': 'application/json'};
      if (sessionId != null) {
        headers['X-Session-ID'] = sessionId;
      }

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/login'),
        headers: headers,
        body: json.encode({'email': email, 'password': password}),
      );

      print('📥 Réponse login: ${response.body}');
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        await _saveAuthData(data['data']);

        if (data['data']['cart']?['session_id'] != null) {
          await prefs.setString('cart_session_id', data['data']['cart']['session_id']);
          print('✅ Nouveau session_id sauvegardé: ${data['data']['cart']['session_id']}');
        }

        // Recharger les données après connexion
        if (_cartService != null) {
          print('🔄 Rechargement du panier après login...');
          await _cartService!.loadCart();
        }

        if (_orderService != null) {
          print('🔄 Rechargement des commandes après login...');
          await _orderService!.getMyOrders();
        }

        if (_dashboardService != null) {
          print('🔄 Rechargement du dashboard après login...');
          await _dashboardService!.loadDashboardData();
        }

        if (_notificationService != null) {
          print('🔔 Chargement des notifications après login...');
          await _notificationService!.loadNotifications(reset: true);
          _notificationService!.startListening();
        }

        // ✅ NOTIFIER LES ÉCOUTEURS APRÈS CONNEXION RÉUSSIE
        notifyListeners();

        _setLoading(false);
        return true;
      } else {
        _setError(data['message'] ?? 'Erreur de connexion');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      print('💥 Exception login: $e');
      _setError('Erreur réseau: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<Map<String, dynamic>> sendVerificationCode(Map<String, dynamic> userData) async {
    _setLoading(true);
    _clearError();

    try {
      String? sessionId;
      final prefs = await SharedPreferences.getInstance();
      sessionId = prefs.getString('cart_session_id');

      final Map<String, String> headers = {'Content-Type': 'application/json'};
      if (sessionId != null) {
        headers['X-Session-ID'] = sessionId;
      }

      print('📤 Envoi des données: ${json.encode(userData)}');

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/send-verification-code'),
        headers: headers,
        body: json.encode(userData),
      );

      print('📥 Statut: ${response.statusCode}');
      print('📥 Réponse: ${response.body}');

      if (response.body.trim().startsWith('<!DOCTYPE')) {
        print('❌ Erreur HTML reçue');
        _setLoading(false);
        return {
          'success': false,
          'message': 'Erreur serveur. Vérifiez les logs.',
        };
      }

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        _setLoading(false);
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        _setLoading(false);

        String errorMessage = data['message'] ?? 'Erreur lors de l\'envoi';
        if (data['errors'] != null) {
          final errors = data['errors'] as Map;
          if (errors['general'] != null) {
            errorMessage = errors['general'][0];
          } else {
            final firstKey = errors.keys.first;
            errorMessage = errors[firstKey][0];
          }
        }

        return {
          'success': false,
          'message': errorMessage,
          'errors': data['errors'],
        };
      }
    } catch (e) {
      print('❌ Exception: $e');
      _setLoading(false);
      return {
        'success': false,
        'message': 'Erreur réseau: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> verifyCodeAndRegister(String email, String code) async {
    _setLoading(true);
    _clearError();

    try {
      String? sessionId;
      final prefs = await SharedPreferences.getInstance();
      sessionId = prefs.getString('cart_session_id');

      final Map<String, String> headers = {'Content-Type': 'application/json'};
      if (sessionId != null) {
        headers['X-Session-ID'] = sessionId;
      }

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/verify-code'),
        headers: headers,
        body: json.encode({'email': email, 'code': code}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201 && data['success']) {
        await _saveAuthData(data['data']);

        if (_cartService != null) {
          if (data['data']['cart']?['session_id'] != null) {
            await prefs.setString('cart_session_id', data['data']['cart']['session_id']);
          }
          await _cartService!.loadCart();
        }

        if (_notificationService != null) {
          print('🔔 Chargement des notifications après inscription...');
          await _notificationService!.loadNotifications(reset: true);
          _notificationService!.startListening();
        }

        // ✅ NOTIFIER LES ÉCOUTEURS APRÈS INSCRIPTION RÉUSSIE
        notifyListeners();

        _setLoading(false);
        return {'success': true, 'message': data['message']};
      } else {
        _setLoading(false);
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur de vérification',
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

  Future<Map<String, dynamic>> resendCode(String email) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/resend-code'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      final data = json.decode(response.body);

      _setLoading(false);
      return {
        'success': data['success'] ?? false,
        'message': data['message'],
        'data': data['data'],
      };
    } catch (e) {
      _setLoading(false);
      return {
        'success': false,
        'message': 'Erreur réseau: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      final data = json.decode(response.body);
      _setLoading(false);

      if (response.statusCode == 200 && data['success']) {
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

  Future<Map<String, dynamic>> verifyResetCode(String email, String code) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/verify-reset-code'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'code': code}),
      );

      final data = json.decode(response.body);
      _setLoading(false);

      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'code': code,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Code invalide',
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

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String password,
    required String passwordConfirmation,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      print('📤 Tentative de réinitialisation pour: $email avec code: $code');

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'code': code,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      print('📥 Statut: ${response.statusCode}');
      print('📥 Réponse: ${response.body}');

      if (response.body.trim().startsWith('<!DOCTYPE')) {
        print('❌ Erreur HTML reçue - vérifiez les logs Laravel');
        _setLoading(false);
        return {
          'success': false,
          'message': 'Erreur serveur. Vérifiez les logs.',
        };
      }

      final data = json.decode(response.body);
      _setLoading(false);

      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'message': data['message'] ?? 'Mot de passe modifié'
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la réinitialisation',
        };
      }
    } catch (e) {
      print('❌ Exception: $e');
      _setLoading(false);
      return {
        'success': false,
        'message': 'Erreur réseau: ${e.toString()}',
      };
    }
  }

  Future<void> logout() async {
    _setLoading(true);

    try {
      // ✅ Réinitialiser le service de notifications push
      if (_pushNotificationService != null) {
        await PushNotificationService.reset();
      }

      if (_token != null) {
        try {
          await http.post(
            Uri.parse('${AppConstants.baseUrl}/auth/logout'),
            headers: _headers,
          ).timeout(const Duration(seconds: 5));
          print('✅ Déconnexion API réussie');
        } catch (e) {
          print('⚠️ Erreur déconnexion API (ignorée): $e');
        }
      }

      _token = null;
      _currentUser = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_data');
      await prefs.remove('cart_session_id');

      print('✅ Préférences locales nettoyées');

      if (_cartService != null) {
        _cartService!.clearLocalCart();
        print('✅ Panier local vidé');
      }

      if (_notificationService != null) {
        _notificationService!.clearLocalNotifications();
        print('✅ Notifications locales vidées');
      }

      _setLoading(false);
      print('🎉 Déconnexion complète réussie');

    } catch (e) {
      print('💥 Erreur critique lors de la déconnexion: $e');
      _token = null;
      _currentUser = null;
    } finally {
      notifyListeners();
    }
  }

  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    _token = data['access_token'];
    _currentUser = User.fromJson(data['user']);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', _token!);
    await prefs.setString('user_data', json.encode(data['user']));
    notifyListeners();
  }

  Future<void> _clearAuthData() async {
    _token = null;
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}