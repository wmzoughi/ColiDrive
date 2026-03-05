// lib/services/auth_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../utils/constants.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _currentUser != null;

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
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        await _saveAuthData(data['data']);
        _setLoading(false);
        return true;
      } else {
        _setError(data['message'] ?? 'Erreur de connexion');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Erreur réseau: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    _setLoading(true);
    _clearError();

    try {
      // ✅ CHOISIR LE BON ENDPOINT SELON LE TYPE
      String endpoint;
      if (userData['user_type'] == 'fournisseur') {
        endpoint = '${AppConstants.baseUrl}/auth/register/fournisseur';
      } else {
        endpoint = '${AppConstants.baseUrl}/auth/register/commercant';
      }

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201 && data['success']) {
        await _saveAuthData(data['data']);
        _setLoading(false);
        return {'success': true};
      } else {
        _setLoading(false);
        return {
          'success': false,
          'errors': data['errors'] ?? {'general': [data['message'] ?? 'Erreur']}
        };
      }
    } catch (e) {
      _setLoading(false);
      return {
        'success': false,
        'errors': {'general': ['Erreur réseau: ${e.toString()}']}
      };
    }
  }

  Future<void> logout() async {
    if (_token != null) {
      try {
        await http.post(
          Uri.parse('${AppConstants.baseUrl}/auth/logout'),
          headers: _headers,
        );
      } catch (e) {
        debugPrint('Logout error: $e');
      }
    }
    await _clearAuthData();  // ✅ Efface le token et les données utilisateur
    notifyListeners();        // ✅ Notifie les widgets du changement
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