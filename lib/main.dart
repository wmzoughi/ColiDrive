import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'l10n/app_localizations.dart';

// Auth
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'services/auth_service.dart';
import 'services/language_service.dart';

// Dashboard
import 'screens/commercant/dashboard_commercant.dart';
import 'screens/fournisseur/dashboard_fournisseur.dart';
import 'screens/fournisseur/compte_screen.dart';
import 'screens/commercant/compte_screen.dart';

// Gestion produits
import 'screens/fournisseur/gestion_produits.dart';
import 'screens/fournisseur/add_edit_product_screen.dart';
import 'screens/commercant/cart_screen.dart';
import 'screens/commercant/orders_screen.dart';
import 'screens/commercant/products_screen.dart';
import 'screens/commercant/product_detail_screen.dart';
import 'screens/commercant/checkout_screen.dart';
import 'services/order_service.dart';
import 'screens/fournisseur/SupplierOrdersScreen.dart';
import 'screens/commercant/product_reviews_screen.dart';

// Flux multivendeur
import 'screens/commercant/supplier_products_screen.dart';
import 'screens/commercant/suppliers_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/commercant/invoice_detail_screen.dart';
import 'screens/commercant/invoices_screen.dart';

// Services
import 'services/dashboard_service.dart';
import 'services/product_service.dart';
import 'services/merchant_service.dart';
import 'services/cart_service.dart';
import 'services/review_service.dart';
import 'services/notification_service.dart';
import 'services/invoice_service.dart';
import 'services/barcode_service.dart';
import 'utils/constants.dart';
import 'services/push_notification_service.dart';

// ✅ Gestionnaire de messages en arrière-plan
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("📨 Notification en arrière-plan: ${message.notification?.title}");
  print("📨 Corps: ${message.notification?.body}");
  print("📨 Données: ${message.data}");

  // Initialiser Firebase (nécessaire en isolate)
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialiser Firebase
  await Firebase.initializeApp();

  // ✅ Enregistrer le gestionnaire de messages en arrière-plan
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialisation de Stripe
  try {
    Stripe.publishableKey = AppConstants.stripePublishableKey;
    await Stripe.instance.applySettings();
    print('✅ Stripe initialisé avec succès');
  } catch (e) {
    print('❌ Erreur initialisation Stripe: $e');
  }

  final authService = AuthService();
  await authService.init();

  final languageService = LanguageService();
  final cartService = CartService(authService);

  // Créer les services
  final orderService = OrderService(authService, cartService);
  final dashboardService = DashboardService(authService);
  final productService = ProductService(authService);
  final merchantService = MerchantService(authService);
  final reviewService = ReviewService(authService);
  final notificationService = NotificationService(authService);
  final invoiceService = InvoiceService(authService);
  final barcodeService = BarcodeService(authService);
  final pushNotificationService = PushNotificationService();

  // Injecter les services dans authService
  authService.setCartService(cartService);
  authService.setOrderService(orderService);
  authService.setDashboardService(dashboardService);
  authService.setNotificationService(notificationService);
  authService.setPushNotificationService(pushNotificationService);

  runApp(
    MultiProvider(
      providers: [
        // Services de base
        ChangeNotifierProvider(create: (_) => authService),
        ChangeNotifierProvider(create: (_) => languageService),
        ChangeNotifierProvider(create: (_) => cartService),

        // Autres services
        ChangeNotifierProvider(create: (_) => orderService),
        ChangeNotifierProvider(create: (_) => dashboardService),
        ChangeNotifierProvider(create: (_) => productService),
        ChangeNotifierProvider(create: (_) => merchantService),
        ChangeNotifierProvider(create: (_) => reviewService),
        ChangeNotifierProvider(create: (_) => notificationService),
        ChangeNotifierProvider(create: (_) => invoiceService),
        ChangeNotifierProvider(create: (_) => barcodeService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  bool _pushNotificationsInitialized = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
      _setupAuthListener();
    });
  }

  void _initializeServices() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final authService = Provider.of<AuthService>(context, listen: false);
    final notificationService = Provider.of<NotificationService>(context, listen: false);

    if (authService.isAuthenticated) {
      await notificationService.loadNotifications(reset: true);
      notificationService.startListening();
      await _initializePushNotifications();
    }
  }

  void _setupAuthListener() {
    final authService = Provider.of<AuthService>(context, listen: false);

    authService.addListener(() async {
      print('🔐 Changement d\'authentification détecté');
      print('   Connecté: ${authService.isAuthenticated}');
      print('   Utilisateur: ${authService.currentUser?.email}');
      print('   Type: ${authService.currentUser?.userType}');
      print('   _pushNotificationsInitialized: $_pushNotificationsInitialized');

      if (authService.isAuthenticated && !_pushNotificationsInitialized) {
        print('📱 Initialisation des notifications push après connexion...');
        await _initializePushNotifications();
      }
      else if (!authService.isAuthenticated && _pushNotificationsInitialized) {
        print('🚪 Déconnexion détectée, réinitialisation des notifications push...');
        _pushNotificationsInitialized = false;
        await PushNotificationService.reset();
      }
    });
  }

  Future<void> _initializePushNotifications() async {
    if (_pushNotificationsInitialized) {
      print('⚠️ Notifications push déjà initialisées');
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);

    if (!authService.isAuthenticated) {
      print('⚠️ Utilisateur non connecté, impossible d\'initialiser');
      return;
    }

    print('🚀 ===== INITIALISATION NOTIFICATIONS PUSH =====');
    print('📧 Email: ${authService.currentUser?.email}');
    print('👤 Type: ${authService.currentUser?.userType}');
    print('🆔 ID: ${authService.currentUser?.id}');

    await PushNotificationService.initialize(
      authService,
      _onNotificationTap,
    );

    _pushNotificationsInitialized = true;
    print('✅ Notifications push initialisées avec succès');
  }

  void _onNotificationTap(Map<String, dynamic> data) {
    print('🔔 Notification tapée: $data');

    if (data.containsKey('type')) {
      final type = data['type'];
      final authService = Provider.of<AuthService>(navigatorKey.currentContext!, listen: false);

      if (type == 'new_order' && authService.currentUser?.userType == 'fournisseur') {
        navigatorKey.currentState?.pushNamed('/supplier/orders');
      } else if (type == 'order_confirmed' && authService.currentUser?.userType == 'commercant') {
        navigatorKey.currentState?.pushNamed('/merchant/orders');
      } else if (type == 'order_shipped') {
        navigatorKey.currentState?.pushNamed('/merchant/orders');
      } else if (type == 'order_delivered') {
        navigatorKey.currentState?.pushNamed('/merchant/orders');
      } else if (type == 'order_cancelled') {
        navigatorKey.currentState?.pushNamed('/merchant/orders');
      }
    }

    final notificationService = Provider.of<NotificationService>(
      navigatorKey.currentContext!,
      listen: false,
    );
    notificationService.refresh();
  }

  @override
  void dispose() {
    final authService = Provider.of<AuthService>(context, listen: false);
    authService.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);

    return MaterialApp(
      navigatorKey: _MyAppState.navigatorKey,
      title: 'ColiDrive',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Poppins',
        textTheme: TextTheme(
          bodyLarge: TextStyle(
            fontWeight: languageService.isArabic ? FontWeight.w600 : FontWeight.normal,
          ),
          bodyMedium: TextStyle(
            fontWeight: languageService.isArabic ? FontWeight.w600 : FontWeight.normal,
          ),
          labelLarge: TextStyle(
            fontWeight: languageService.isArabic ? FontWeight.w700 : FontWeight.w600,
          ),
          titleLarge: TextStyle(
            fontWeight: languageService.isArabic ? FontWeight.w800 : FontWeight.bold,
          ),
          titleMedium: TextStyle(
            fontWeight: languageService.isArabic ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
      locale: languageService.currentLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr'),
        Locale('ar'),
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        return const Locale('fr');
      },
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/merchant/dashboard': (context) => const DashboardCommercant(),
        '/merchant/orders': (context) => const OrdersScreen(),
        '/merchant/products': (context) => const ProductsScreen(),
        '/merchant/cart': (context) => const CartScreen(),
        '/merchant/account': (context) => const CompteScreenM(),
        '/merchant/checkout': (context) => const CheckoutScreen(),
        '/merchant/suppliers': (context) => const SuppliersScreen(),
        '/supplier/dashboard': (context) => const DashboardFournisseur(),
        '/supplier/products': (context) => const GestionProduitsScreen(),
        '/supplier/account': (context) => const CompteScreenS(),
        '/supplier/orders': (context) => const SupplierOrdersScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/merchant/invoices': (context) => const InvoicesScreen(),
        '/merchant/invoice-detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return InvoiceDetailScreen(invoiceId: args['invoice_id']);
        },
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/merchant/supplier-products') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => SupplierProductsScreen(
              supplierId: args['supplier_id'],
              supplierName: args['supplier_name'],
            ),
          );
        }

        if (settings.name == '/merchant/product-reviews') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ProductReviewsScreen(
              product: args['product'],
            ),
          );
        }

        if (settings.name == '/merchant/product-detail') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              product: args['product'],
            ),
          );
        }

        if (settings.name == '/supplier/product/edit') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => AddEditProductScreen(
              product: args['product'],
              categories: args['categories'],
              onProductAdded: args['onProductAdded'],
            ),
          );
        }

        return null;
      },
    );
  }
}