import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'auth_service.dart';

class PushNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static late Function(Map<String, dynamic>) _onNotificationTap;
  static AuthService? _authService;
  static bool _initialized = false;

  static Future<void> initialize(
      AuthService authService,
      Function(Map<String, dynamic>) onNotificationTap,
      ) async {
    if (_initialized) {
      print('⚠️ PushNotificationService déjà initialisé');
      return;
    }

    _authService = authService;
    _onNotificationTap = onNotificationTap;

    print('🚀 Initialisation des notifications push...');

    // Initialiser Firebase (si pas déjà fait)
    try {
      await Firebase.initializeApp();
    } catch (e) {
      print('⚠️ Firebase déjà initialisé ou erreur: $e');
    }

    // Demander la permission (Android 13+)
    if (Platform.isAndroid) {
      await _requestAndroidPermission();
    }

    // Demander la permission (iOS)
    if (Platform.isIOS) {
      await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // Obtenir le token FCM
    await _getToken();

    // Configurer les notifications locales
    await _initLocalNotifications();

    // Écouter les notifications en premier plan
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Écouter quand l'utilisateur ouvre une notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Gérer la notification qui a ouvert l'app
    RemoteMessage? initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage.data);
    }

    _initialized = true;
  }

  // ✅ DEMANDER PERMISSION POUR ANDROID 13+
  static Future<void> _requestAndroidPermission() async {
    if (await _fcm.requestPermission() == AuthorizationStatus.authorized) {
      print('✅ Permission notifications accordée');
    } else {
      print('⚠️ Permission notifications refusée');
    }
  }

  static Future<void> reset() async {
    print('🔄 Réinitialisation du service de notifications push...');
    _initialized = false;
    _authService = null;
  }

  static Future<void> _getToken() async {
    try {
      print('🔄 Récupération du token FCM...');
      String? token = await _fcm.getToken();

      if (token != null) {
        print('✅ TOKEN FCM TROUVÉ:');
        print('📱 $token');
        print('📏 Longueur: ${token.length} caractères');
      } else {
        print('❌ Token FCM est NULL');
      }

      // Envoyer le token au serveur
      if (_authService != null && _authService!.isAuthenticated && token != null) {
        print('📤 Envoi du token au serveur...');
        await _sendTokenToServer(token);
      } else {
        print('⚠️ Token non envoyé:');
        print('   AuthService: ${_authService != null}');
        print('   Authentifié: ${_authService?.isAuthenticated}');
        print('   Token: ${token != null}');
      }

      // Écouter les changements de token
      _fcm.onTokenRefresh.listen((newToken) {
        print('🔄 Token FCM rafraîchi: $newToken');
        _sendTokenToServer(newToken);
      });
    } catch (e) {
      print('❌ Erreur getToken: $e');
    }
  }

  static Future<void> _sendTokenToServer(String token) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/notifications/register-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authService?.token}',
        },
        body: json.encode({
          'fcm_token': token,
          'device_type': Platform.isIOS ? 'ios' : 'android',
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Token FCM envoyé au serveur');
      } else {
        print('❌ Erreur envoi token: ${response.body}');
      }
    } catch (e) {
      print('❌ Exception envoi token: $e');
    }
  }

  // ✅ CRÉER LE CANAL DE NOTIFICATION (CORRIGÉ)
  static Future<void> _initLocalNotifications() async {
    // ✅ CRÉER LE CANAL DE NOTIFICATION POUR ANDROID
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'Notifications importantes',
        description: 'Ce canal est utilisé pour les notifications importantes',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
        showBadge: true,
      );

      await _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);

      print('✅ Canal de notification créé');
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          final data = json.decode(response.payload!);
          _onNotificationTap(data);
        }
      },
    );
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📨 Notification en premier plan: ${message.notification?.title}');

    final data = message.data;

    // Afficher la notification locale même en premier plan
    await _showLocalNotification(
      title: message.notification?.title ?? 'Nouvelle notification',
      body: message.notification?.body ?? '',
      payload: json.encode(data),
    );
  }

  static Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    print('📱 Notification ouverte: ${message.data}');
    _handleMessage(message.data);
  }

  static void _handleMessage(Map<String, dynamic> data) {
    _onNotificationTap(data);
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'high_importance_channel',
      'Notifications importantes',
      channelDescription: 'Ce canal est utilisé pour les notifications importantes',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // ✅ Méthode pour supprimer le token à la déconnexion
  static Future<void> unregisterToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null && _authService?.token != null) {
        await http.delete(
          Uri.parse('${AppConstants.baseUrl}/notifications/unregister-token'),
          headers: {
            'Authorization': 'Bearer ${_authService?.token}',
          },
          body: json.encode({'fcm_token': token}),
        );
        print('✅ Token FCM désenregistré');
      }
    } catch (e) {
      print('❌ Erreur désenregistrement token: $e');
    }
  }
}