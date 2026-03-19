// lib/screens/commercant/invoices_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/invoice_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'invoice_detail_screen.dart';
import '../../models/invoice.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({Key? key}) : super(key: key);

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedFilter = 'Toutes';

  @override
  void initState() {
    super.initState();
    _loadInvoices();
    _scrollController.addListener(_onScroll);
    // ✅ Marquer comme vu quand on arrive sur l'écran
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = Provider.of<InvoiceService>(context, listen: false);
      service.markInvoicesAsViewed();
    });
  }

  Future<void> _loadInvoices({bool reset = false}) async {
    final service = Provider.of<InvoiceService>(context, listen: false);
    await service.loadInvoices(reset: reset);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final service = Provider.of<InvoiceService>(context, listen: false);
      if (service.hasMore && !service.isLoading) {
        _loadInvoices();
      }
    }
  }

  List<Invoice> _getFilteredInvoices(InvoiceService service) {
    if (_selectedFilter == 'Toutes') {
      return service.invoices;
    }
    // Filtrer par mois ou année si besoin
    return service.invoices;
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<InvoiceService>(context);
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Mes factures',
          style: TextStyle(
            color: Color(0xFF2D3A4F),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3A4F)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF2D3A4F)),
            onPressed: () => _loadInvoices(reset: true),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey.shade200,
            height: 1,
          ),
        ),
      ),
      body: Column(
        children: [
          // Barre de filtres
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Toutes', _selectedFilter == 'Toutes'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Ce mois', _selectedFilter == 'Ce mois'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Mois dernier', _selectedFilter == 'Mois dernier'),
                  const SizedBox(width: 8),
                  _buildFilterChip('2026', _selectedFilter == '2026'),
                ],
              ),
            ),
          ),

          // Statistiques rapides
          if (service.invoices.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total facturé',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getTotalInvoiced(service),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),

          // Liste des factures
          Expanded(
            child: service.isLoading && service.invoices.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : service.invoices.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: () => _loadInvoices(reset: true),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: service.invoices.length + (service.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == service.invoices.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final invoice = service.invoices[index];
                  return _buildInvoiceCard(invoice);
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 5,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/merchant/dashboard');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/merchant/suppliers');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/merchant/orders');
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/merchant/products');
          } else if (index == 4) {
            Navigator.pushReplacementNamed(context, '/merchant/cart');
          } else if (index == 5) {
            // Déjà sur factures
          } else if (index == 6) {
            Navigator.pushReplacementNamed(context, '/merchant/account');
          }
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
        });
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildInvoiceCard(Invoice invoice) {
    Color statusColor = invoice.status == 'paid' ? Colors.green : Colors.orange;
    String statusText = invoice.status == 'paid' ? 'Payée' : 'En attente';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InvoiceDetailScreen(invoiceId: invoice.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // En-tête de la carte
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.02),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.receipt_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.invoiceNumber,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Date: ${invoice.invoiceDate}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Corps de la carte
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Client',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          invoice.customerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (invoice.customerCompany != null)
                          Text(
                            invoice.customerCompany!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        invoice.formattedTotal,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Boutons d'action
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final service = Provider.of<InvoiceService>(context, listen: false);
                      await service.downloadPdf(invoice.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Téléchargement démarré'),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('PDF'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InvoiceDetailScreen(invoiceId: invoice.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('Détails'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTotalInvoiced(InvoiceService service) {
    double total = 0;
    for (var invoice in service.invoices) {
      total += invoice.total;
    }
    return '${total.toStringAsFixed(2)} MAD';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 60,
              color: AppColors.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucune facture',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3A4F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vos factures apparaîtront ici\naprès vos achats',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/merchant/products');
            },
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Découvrir les produits'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}