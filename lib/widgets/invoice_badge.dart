// lib/widgets/invoice_badge.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/invoice_service.dart';
import '../screens/commercant/invoices_screen.dart';

class InvoiceBadge extends StatelessWidget {
  final Color color;
  final double size;

  const InvoiceBadge({
    Key? key,
    this.color = Colors.grey,
    this.size = 24,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<InvoiceService>(
      builder: (context, service, child) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(Icons.receipt_long_outlined, color: color, size: size),
              onPressed: () async {
                // ✅ Marquer comme vu quand on ouvre
                await service.markInvoicesAsViewed();

                // ✅ Naviguer vers l'écran des factures
                Navigator.pushNamed(context, '/merchant/invoices');
              },
            ),
            if (service.hasNewInvoices)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// Version avec compteur (optionnel)
class InvoiceBadgeWithCount extends StatelessWidget {
  final Color color;
  final double size;

  const InvoiceBadgeWithCount({
    Key? key,
    this.color = Colors.grey,
    this.size = 24,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<InvoiceService>(
      builder: (context, service, child) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(Icons.receipt_long_outlined, color: color, size: size),
              onPressed: () async {
                await service.markInvoicesAsViewed();
                Navigator.pushNamed(context, '/merchant/invoices');
              },
            ),
            if (service.newInvoicesCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Center(
                    child: Text(
                      service.newInvoicesCount > 9
                          ? '9+'
                          : '${service.newInvoicesCount}',
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
    );
  }
}