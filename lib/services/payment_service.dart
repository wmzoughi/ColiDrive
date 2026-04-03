// lib/services/payment_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';
import '../utils/constants.dart';
import 'auth_service.dart';

class PaymentService {
  final AuthService _authService;

  PaymentService(this._authService);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_authService.token != null) 'Authorization': 'Bearer ${_authService.token}',
  };

  Future<Map<String, dynamic>> payWithStripe(int orderId) async {
    try {
      print('💰 Début paiement Stripe pour commande: $orderId');
      print('🔑 Token: ${_authService.token}');

      // 1. Créer le PaymentIntent sur le backend
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/payment/create-intent'),
        headers: _headers,
        body: json.encode({'order_id': orderId}),
      );

      print('📥 Status code: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      // ✅ Vérifier si la réponse est valide
      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Réponse vide du serveur',
        };
      }

      final data = json.decode(response.body);

      // ✅ Vérifier si 'success' existe et est un booléen
      final bool isSuccess = data['success'] == true;

      if (!isSuccess) {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la création du paiement',
        };
      }

      // ✅ Vérifier que clientSecret existe
      final clientSecret = data['clientSecret'];
      if (clientSecret == null || clientSecret.isEmpty) {
        return {
          'success': false,
          'message': 'ClientSecret manquant',
        };
      }

      final paymentIntentId = data['paymentIntentId'];

      // 2. Initialiser la feuille de paiement
      try {
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'ColiDrive',
            style: ThemeMode.light,
            allowsDelayedPaymentMethods: true,
          ),
        );
      } catch (e) {
        print('❌ Erreur initPaymentSheet: $e');
        return {
          'success': false,
          'message': 'Erreur d\'initialisation du paiement: $e',
        };
      }

      // 3. Ouvrir le formulaire de paiement
      try {
        await Stripe.instance.presentPaymentSheet();
      } catch (e) {
        print('❌ Erreur presentPaymentSheet: $e');
        return {
          'success': false,
          'message': 'Paiement annulé ou échoué: $e',
        };
      }

      // 4. Paiement réussi - Confirmer sur le backend
      final confirmResponse = await http.post(
        Uri.parse('${AppConstants.baseUrl}/payment/confirm'),
        headers: _headers,
        body: json.encode({
          'payment_intent_id': paymentIntentId,
        }),
      );

      final confirmData = json.decode(confirmResponse.body);

      // ✅ Vérifier la confirmation
      final bool confirmSuccess = confirmData['success'] == true;

      if (confirmSuccess) {
        return {
          'success': true,
          'message': 'Paiement réussi',
          'order_id': confirmData['order_id'],
        };
      }

      return {
        'success': false,
        'message': confirmData['message'] ?? 'Paiement non confirmé'
      };

    } catch (e) {
      print('❌ Erreur paiement: $e');
      return {
        'success': false,
        'message': 'Erreur: ${e.toString()}',
      };
    }
  }
}