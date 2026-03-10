// lib/widgets/bottom_nav_bar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../l10n/app_localizations.dart';
import '../services/cart_service.dart';
import '../services/auth_service.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context);
    final isFournisseur = authService.currentUser?.userType == 'fournisseur';
    final isCommercant = authService.currentUser?.userType == 'commercant';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
        ),
        items: _buildNavItems(localizations, isCommercant),
      ),
    );
  }

  List<BottomNavigationBarItem> _buildNavItems(
      AppLocalizations localizations,
      bool isCommercant
      ) {
    List<BottomNavigationBarItem> items = [
      // Accueil - pour tous
      BottomNavigationBarItem(
        icon: const Icon(Icons.home_outlined),
        activeIcon: const Icon(Icons.home),
        label: localizations.home,
      ),

      // Commandes - pour tous
      BottomNavigationBarItem(
        icon: const Icon(Icons.shopping_bag_outlined),
        activeIcon: const Icon(Icons.shopping_bag),
        label: localizations.orders,
      ),

      // Produits - pour tous
      BottomNavigationBarItem(
        icon: const Icon(Icons.inventory_outlined),
        activeIcon: const Icon(Icons.inventory),
        label: localizations.products,
      ),
    ];

    // Panier - UNIQUEMENT pour les commerçants
    if (isCommercant) {
      items.add(
        BottomNavigationBarItem(
          icon: Consumer<CartService>(
            builder: (context, cartService, child) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.shopping_cart_outlined),
                  if (cartService.totalItems > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Center(
                          child: Text(
                            '${cartService.totalItems}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          activeIcon: Consumer<CartService>(
            builder: (context, cartService, child) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.shopping_cart),
                  if (cartService.totalItems > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Center(
                          child: Text(
                            '${cartService.totalItems}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          label: localizations.cart,
        ),
      );
    }

    // Compte - pour tous (toujours en dernier)
    items.add(
      BottomNavigationBarItem(
        icon: const Icon(Icons.person_outline),
        activeIcon: const Icon(Icons.person),
        label: localizations.account,
      ),
    );

    return items;
  }
}