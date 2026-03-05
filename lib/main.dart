import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';  // 👈 Notez le nom du fichier

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
import 'services/cart_service.dart';

// Gestion produits
import 'screens/fournisseur/gestion_produits.dart';
import 'screens/fournisseur/add_edit_product_screen.dart';
import 'screens/commercant/cart_screen.dart';
import 'screens/commercant/orders_screen.dart';
import 'screens/commercant/products_screen.dart';

// Services
import 'services/dashboard_service.dart';
import 'services/product_service.dart';
import 'services/merchant_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = AuthService();
  await authService.init();
  final languageService = LanguageService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => authService),
        ChangeNotifierProvider(create: (_) => languageService),
        ChangeNotifierProvider(create: (_) => CartService()),
        ChangeNotifierProxyProvider<AuthService, DashboardService>(
          create: (context) => DashboardService(authService),
          update: (context, authService, previous) => DashboardService(authService),
        ),
        ChangeNotifierProxyProvider<AuthService, ProductService>(
          create: (context) => ProductService(authService),
          update: (context, authService, previous) => ProductService(authService),
        ),
        ChangeNotifierProxyProvider<AuthService, MerchantService>(
          create: (context) => MerchantService(authService),
          update: (context, authService, previous) => MerchantService(authService),
        ),
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
        // 👇 AJOUTE ÇA POUR QUE TOUS LES TEXTES SOIENT PLUS GRAS EN ARABE
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
        '/merchant/account': (context) => const CompteScreenM(),
        '/merchant/orders': (context) => const OrdersScreen(),
        '/merchant/products': (context) => const ProductsScreen(),
        '/merchant/cart': (context) => const CartScreen(),
        '/supplier/dashboard': (context) => const DashboardFournisseur(),
        '/supplier/products': (context) => const GestionProduitsScreen(),
        '/supplier/account': (context) => const CompteScreenS(),
      },
    );
  }
}