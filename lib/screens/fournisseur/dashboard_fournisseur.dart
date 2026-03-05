// lib/screens/fournisseur/dashboard_fournisseur.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/dashboard_service.dart';
import '../../services/product_service.dart';
import '../../utils/constants.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../l10n/app_localizations.dart';
import 'gestion_produits.dart';
import 'compte_screen.dart';


class DashboardFournisseur extends StatefulWidget {
  const DashboardFournisseur({Key? key}) : super(key: key);

  @override
  State<DashboardFournisseur> createState() => _DashboardFournisseurState();
}

class _DashboardFournisseurState extends State<DashboardFournisseur> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final dashboardService = Provider.of<DashboardService>(context, listen: false);
    await dashboardService.loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final dashboardService = Provider.of<DashboardService>(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/icons/logo.png',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'CD',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Color(0xFF2D3A4F)),
            onPressed: () {},
          ),
        ],
      ),
      body: dashboardService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.salesStats,
                      style: const TextStyle(
                        color: Color(0xFF8A9AA8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${localizations.hello}, ${authService.currentUser?.name ?? ''}',
                      style: const TextStyle(
                        color: Color(0xFF2D3A4F),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.calendar_today, size: 20, color: Color(0xFF2D3A4F)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    label: localizations.totalOrders,
                    value: dashboardService.totalOrders.toString(),
                    color: const Color(0xFF0F2AA6),
                    icon: Icons.shopping_bag_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    label: localizations.pendingOrders,
                    value: dashboardService.pendingOrders.toString(),
                    color: const Color(0xFFFF8D06),
                    icon: Icons.hourglass_empty,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    label: localizations.totalSales,
                    value: dashboardService.formatMAD(dashboardService.totalSales, context),
                    color: const Color(0xFF1D571D),
                    icon: Icons.euro_symbol,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    label: localizations.outOfStockProducts,
                    value: dashboardService.outOfStockProducts.toString(),
                    color: const Color(0xFF8E1927),
                    icon: Icons.warning_amber_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.salesStats,
                    style: const TextStyle(
                      color: Color(0xFF2D3A4F),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: dashboardService.salesChartData.map((data) {
                      return _buildChartBar(
                        data['month'],
                        (data['value'] / 1000).clamp(20, 80).toDouble(),
                        data['isActive'],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      '${localizations.totalSales} (${dashboardService.formatMAD(0, context).replaceAll('0,00', '')})',
                      style: const TextStyle(
                        color: Color(0xFF8A9AA8),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.recentTransactions,
                  style: const TextStyle(
                    color: Color(0xFF2D3A4F),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    localizations.seeAll,
                    style: const TextStyle(
                      color: Color(0xFF4361EE),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (dashboardService.recentTransactions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    localizations.noTransactions,
                    style: const TextStyle(color: Color(0xFF8A9AA8)),
                  ),
                ),
              )
            else
              ...dashboardService.recentTransactions.map((transaction) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildTransactionCard(
                    clientName: transaction['clientName'],
                    commandeRef: transaction['commandeRef'],
                    montant: transaction['montant'].toStringAsFixed(2),
                    statut: transaction['statut'],
                    timeInfo: transaction['timeInfo'],
                    isDelayed: transaction['isDelayed'],
                  ),
                );
              }).toList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index == 1) {
            // Navigator.pushNamed(context, '/supplier/orders');
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChangeNotifierProvider(
                  create: (context) => ProductService(
                    Provider.of<AuthService>(context, listen: false),
                  ),
                  child: const GestionProduitsScreen(),
                ),
              ),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CompteScreenS(),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartBar(String month, double height, bool isActive) {
    return Column(
      children: [
        Container(
          width: 24,
          height: height,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF4361EE) : const Color(0xFFE8EDF2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          month,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF8A9AA8),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard({
    required String clientName,
    required String commandeRef,
    required String montant,
    required String statut,
    required String timeInfo,
    required bool isDelayed,
  }) {
    final localizations = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDelayed ? const Color(0xFFE71D36).withOpacity(0.1) : const Color(0xFF2EC4B6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isDelayed ? Icons.warning_amber_rounded : Icons.check_circle,
              color: isDelayed ? const Color(0xFFE71D36) : const Color(0xFF2EC4B6),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clientName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3A4F),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  commandeRef,
                  style: const TextStyle(
                    color: Color(0xFF8A9AA8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDelayed ? const Color(0xFFE71D36).withOpacity(0.1) : const Color(0xFF2EC4B6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '+$montant MAD',
                        style: TextStyle(
                          color: isDelayed ? const Color(0xFFE71D36) : const Color(0xFF2EC4B6),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeInfo,
                      style: const TextStyle(
                        color: Color(0xFF8A9AA8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDelayed ? const Color(0xFFE71D36).withOpacity(0.1) : const Color(0xFF2EC4B6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statut == 'En retard' ? localizations.pending : localizations.delivered,
              style: TextStyle(
                color: isDelayed ? const Color(0xFFE71D36) : const Color(0xFF2EC4B6),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}