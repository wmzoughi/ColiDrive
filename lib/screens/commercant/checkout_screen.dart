// lib/screens/commercant/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/cart_service.dart';
import '../../services/order_service.dart';
import '../../services/auth_service.dart';
import '../../services/payment_service.dart'; // 👈 AJOUTER CET IMPORT
import '../../models/order_request.dart';
import '../../utils/constants.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../l10n/app_localizations.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedPaymentMethod = 'cash';
  bool _isLoading = false;

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Pré-remplir avec les infos de l'utilisateur si disponibles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      if (user?.phone != null && user!.phone!.isNotEmpty) {
        _phoneController.text = user.phone!;
      }
    });
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final orderService = Provider.of<OrderService>(context, listen: false);
    final cartService = Provider.of<CartService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final localizations = AppLocalizations.of(context)!;

    if (cartService.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Votre panier est vide'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    final orderRequest = OrderRequest(
      shippingAddress: _addressController.text.trim(),
      shippingCity: _cityController.text.trim(),
      shippingZip: _zipController.text.trim(),
      shippingPhone: _phoneController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      paymentMethod: _selectedPaymentMethod,
    );

    // 1. Créer la commande
    final result = await orderService.createOrder(orderRequest);

    if (!result['success']) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? localizations.orderError),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // ✅ Récupérer les commandes créées (liste ou unique)
    List<dynamic> createdOrders = [];
    if (result['orders'] != null) {
      createdOrders = result['orders'] as List;
    } else if (result['order'] != null) {
      createdOrders = [result['order']];
    }

    // Si paiement par carte, traiter le paiement Stripe
    if (_selectedPaymentMethod == 'card') {
      final paymentService = PaymentService(authService);

      // ✅ Pour les commandes multiples (plusieurs fournisseurs)
      // On paie la première commande comme exemple, ou on peut implémenter un paiement groupé
      if (createdOrders.isNotEmpty) {
        final paymentResult = await paymentService.payWithStripe(createdOrders.first.id);

        setState(() => _isLoading = false);

        if (paymentResult['success']) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ ${localizations.orderSuccess} - Paiement confirmé'),
                backgroundColor: Colors.green,
              ),
            );

            // Afficher un message sur les commandes créées
            if (createdOrders.length > 1) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${createdOrders.length} commandes créées (une par fournisseur)'),
                  backgroundColor: Colors.blue,
                  duration: const Duration(seconds: 3),
                ),
              );
            }

            Navigator.pushReplacementNamed(context, '/merchant/orders');
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Erreur paiement: ${paymentResult['message']}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
            // La commande est créée mais non payée, on reste sur la page
          }
        }
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur: aucune commande créée'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // ✅ Paiement à la livraison (COD)
      setState(() => _isLoading = false);

      if (mounted) {
        String successMessage = localizations.orderSuccess;
        if (createdOrders.isNotEmpty) {
          successMessage = '${localizations.orderSuccess} ${createdOrders.first.orderNumber}';
        }
        if (createdOrders.length > 1) {
          successMessage = '${createdOrders.length} commandes créées avec succès (une par fournisseur)';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/merchant/orders');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);
    final localizations = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final summary = cartService.getCheckoutSummary();
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // ✅ Récupérer le nombre de fournisseurs
    final supplierCount = cartService.supplierCount;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            localizations.checkoutTitle,
            style: const TextStyle(
              color: Color(0xFF2D3A4F),
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: Icon(isArabic ? Icons.arrow_forward : Icons.arrow_back,
                color: const Color(0xFF2D3A4F)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Avertissement multi-fournisseurs
                if (supplierCount > 1)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '💡 Votre commande sera divisée en $supplierCount commandes distinctes (une par fournisseur)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Récapitulatif
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.orderSummary,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3A4F),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${cartService.totalItems} ${localizations.itemsCount}',
                              style: const TextStyle(color: Color(0xFF8A9AA8)),
                            ),
                            Text(
                              '${cartService.subtotal.toStringAsFixed(2)} ${localizations.currency}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildSummaryRow(localizations.subtotal,
                            summary['subtotal']!, localizations),
                        const SizedBox(height: 8),
                        _buildSummaryRow(localizations.tax,
                            summary['tax']!, localizations),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Frais de livraison',
                              style: const TextStyle(color: Color(0xFF8A9AA8)),
                            ),
                            Text(
                              '${(summary['shipping'] ?? 0).toStringAsFixed(2)} ${localizations.currency}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        if (supplierCount > 1)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '($supplierCount x 50 MAD)',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              localizations.total,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${summary['total']!.toStringAsFixed(2)} ${localizations.currency}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Adresse de livraison
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.shippingAddress,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3A4F),
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (user != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.person, color: Colors.blue.shade700, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      if (user.email != null)
                                        Text(
                                          user.email!,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        TextFormField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            labelText: localizations.address,
                            hintText: localizations.addressHint,
                            prefixIcon: const Icon(Icons.home_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return localizations.addressRequired;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _cityController,
                          decoration: InputDecoration(
                            labelText: localizations.city,
                            hintText: localizations.city,
                            prefixIcon: const Icon(Icons.location_city_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return localizations.cityRequired;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _zipController,
                          decoration: InputDecoration(
                            labelText: localizations.zipCode,
                            hintText: localizations.zipCode,
                            prefixIcon: const Icon(Icons.markunread_mailbox_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return localizations.zipRequired;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: localizations.phone,
                            hintText: localizations.phone,
                            prefixIcon: const Icon(Icons.phone_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return localizations.phoneRequired;
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Mode de paiement
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.paymentMethod,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3A4F),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              RadioListTile<String>(
                                title: Text(localizations.cashOnDelivery),
                                subtitle: Text('+15 MAD de frais de gestion'),
                                value: 'cash',
                                groupValue: _selectedPaymentMethod,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedPaymentMethod = value!;
                                  });
                                },
                                activeColor: AppColors.primary,
                              ),
                              const Divider(height: 0, indent: 16, endIndent: 16),
                              RadioListTile<String>(
                                title: Text(localizations.cardPayment),
                                subtitle: Text('Paiement sécurisé par carte bancaire'),
                                value: 'card',
                                groupValue: _selectedPaymentMethod,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedPaymentMethod = value!;
                                  });
                                },
                                activeColor: AppColors.primary,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ✅ Informations sur le paiement
                        if (_selectedPaymentMethod == 'card')
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.security, color: Colors.blue.shade700, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Paiement sécurisé par Stripe. Aucune information bancaire n\'est stockée.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Notes
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.notes,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3A4F),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: localizations.notesHint,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Bouton de confirmation
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Text(
                      _selectedPaymentMethod == 'card'
                          ? 'Payer ${summary['total']!.toStringAsFixed(2)} MAD'
                          : localizations.confirmOrder,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Center(
                  child: Text(
                    localizations.termsAccept,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 3,
          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacementNamed(context, '/merchant/dashboard');
            } else if (index == 1) {
              Navigator.pushReplacementNamed(context, '/merchant/orders');
            } else if (index == 2) {
              Navigator.pushReplacementNamed(context, '/merchant/products');
            } else if (index == 3) {
              // Déjà sur le panier
            } else if (index == 4) {
              Navigator.pushReplacementNamed(context, '/merchant/account');
            }
          },
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, AppLocalizations localizations) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF8A9AA8)),
        ),
        Text(
          '${value.toStringAsFixed(2)} ${localizations.currency}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}