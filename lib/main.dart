// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
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


// 👇 NOUVEAUX IMPORTS POUR LE FLUX MULTIVENDEUR
import 'screens/commercant/supplier_products_screen.dart';
import 'screens/commercant/suppliers_screen.dart';
import 'screens/notifications_screen.dart';

// Services
import 'services/dashboard_service.dart';
import 'services/product_service.dart';
import 'services/merchant_service.dart';
import 'services/cart_service.dart';
import 'services/review_service.dart';
import 'services/notification_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = AuthService();
  await authService.init();

  final languageService = LanguageService();
  final cartService = CartService(authService);

  // ✅ Créer les services avant de les injecter
  final orderService = OrderService(authService, cartService);
  final dashboardService = DashboardService(authService);
  final productService = ProductService(authService);
  final merchantService = MerchantService(authService);
  final reviewService = ReviewService(authService);
  final notificationService = NotificationService(authService);

  // ✅ Injecter TOUS les services dans authService
  authService.setCartService(cartService);
  authService.setOrderService(orderService);
  authService.setDashboardService(dashboardService);

  runApp(
    MultiProvider(
      providers: [
        // Services de base
        ChangeNotifierProvider(create: (_) => authService),
        ChangeNotifierProvider(create: (_) => languageService),
        ChangeNotifierProvider(create: (_) => cartService),

        // Services déjà créés (plus besoin de ProxyProvider)
        ChangeNotifierProvider(create: (_) => orderService),
        ChangeNotifierProvider(create: (_) => dashboardService),
        ChangeNotifierProvider(create: (_) => productService),
        ChangeNotifierProvider(create: (_) => merchantService),
        ChangeNotifierProvider(create: (_) => reviewService),
        ChangeNotifierProvider(create: (_) => notificationService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);

    return MaterialApp(
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
        // Auth
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),

        // Routes commerçant
        '/merchant/dashboard': (context) => const DashboardCommercant(),
        '/merchant/orders': (context) => const OrdersScreen(),
        '/merchant/products': (context) => const ProductsScreen(),
        '/merchant/cart': (context) => const CartScreen(),
        '/merchant/account': (context) => const CompteScreenM(),
        '/merchant/checkout': (context) => const CheckoutScreen(),


        // 👇 NOUVELLES ROUTES POUR LE FLUX MULTIVENDEUR
        '/merchant/suppliers': (context) => const SuppliersScreen(),

        // Routes fournisseur
        '/supplier/dashboard': (context) => const DashboardFournisseur(),
        '/supplier/products': (context) => const GestionProduitsScreen(),
        '/supplier/account': (context) => const CompteScreenS(),
        '/supplier/orders': (context) => const SupplierOrdersScreen(),

        '/notifications': (context) => const NotificationsScreen(),

      },
      onGenerateRoute: (settings) {
        // Route avec paramètres pour les produits d'un fournisseur spécifique
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

        // Détail d'un produit
        if (settings.name == '/merchant/product-detail') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              product: args['product'],
            ),
          );
        }

        // Checkout (déjà géré par route, mais on garde pour la cohérence)
        if (settings.name == '/merchant/checkout') {
          return MaterialPageRoute(
            builder: (context) => const CheckoutScreen(),
          );
        }

        // Édition d'un produit (fournisseur)
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