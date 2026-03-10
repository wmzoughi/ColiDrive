// lib/widgets/cart_icon_with_badge.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_service.dart';

class CartIconWithBadge extends StatelessWidget {
  final double iconSize;
  final Color iconColor;

  const CartIconWithBadge({
    Key? key,
    this.iconSize = 24,
    this.iconColor = const Color(0xFF2D3A4F),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Icône du panier
        Icon(
          Icons.shopping_cart_outlined,
          size: iconSize,
          color: iconColor,
        ),

        // Badge avec le nombre
        Positioned(
          right: -6,
          top: -6,
          child: Consumer<CartService>(
            builder: (context, cartService, child) {
              if (cartService.totalItems == 0) return const SizedBox();

              return Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
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
              );
            },
          ),
        ),
      ],
    );
  }
}