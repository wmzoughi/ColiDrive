// lib/screens/fournisseur/compte_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/dashboard_service.dart';
import '../../services/product_service.dart';
import '../../utils/constants.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../l10n/app_localizations.dart';
import '../auth/login_screen.dart';
import 'gestion_produits.dart';
import '../../models/user.dart';
import '../../widgets/notification_icon.dart';

class CompteScreenS extends StatelessWidget {
  const CompteScreenS({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final dashboardService = Provider.of<DashboardService>(context);
    final productService = Provider.of<ProductService>(context);
    final user = authService.currentUser;
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          localizations.myAccount,
          style: const TextStyle(
            color: Color(0xFF2D3A4F),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          NotificationIcon(color: const Color(0xFF2D3A4F)),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              dashboardService.loadDashboardData();
              productService.loadSupplierProducts(reset: true);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await dashboardService.loadDashboardData();
          await productService.loadSupplierProducts(reset: true);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Photo de profil
              _buildProfileHeader(user, localizations),

              const SizedBox(height: 20),

              // Informations personnelles
              _buildPersonalInfo(user, localizations),

              const SizedBox(height: 20),

              // Entreprise
              _buildCompanyInfo(user, localizations),

              const SizedBox(height: 20),

              // Statistiques DYNAMIQUES
              _buildStatisticsSection(dashboardService, productService, localizations),

              const SizedBox(height: 20),

              // Bouton déconnexion
              _buildLogoutButton(context, authService, localizations),

              const SizedBox(height: 20),

              // Version
              Center(
                child: Text(
                  localizations.version,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
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
            Navigator.pushReplacementNamed(context, '/supplier/dashboard');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/supplier/orders');
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ChangeNotifierProvider.value(
                  value: productService,
                  child: const GestionProduitsScreen(),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  // ✅ Section photo de profil
  Widget _buildProfileHeader(User? user, AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                user?.name?.substring(0, 1).toUpperCase() ?? 'F',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? localizations.supplier,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3A4F),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: const TextStyle(
              color: Color(0xFF8A9AA8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              localizations.supplier,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Section informations personnelles
  Widget _buildPersonalInfo(User? user, AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(20),
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
            localizations.personalInfo,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3A4F),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.person_outline,
            label: localizations.fullName,
            value: user?.name ?? localizations.notProvided,
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.email_outlined,
            label: localizations.email,
            value: user?.email ?? localizations.notProvided,
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.phone_outlined,
            label: localizations.phone,
            value: user?.phone ?? localizations.notProvided,
          ),
        ],
      ),
    );
  }

  // ✅ Section entreprise
  Widget _buildCompanyInfo(User? user, AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(20),
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
            localizations.company,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3A4F),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.business_outlined,
            label: localizations.companyName,
            value: user?.companyName ?? localizations.notProvided,
          ),
        ],
      ),
    );
  }

  // ✅ Section statistiques DYNAMIQUES
  Widget _buildStatisticsSection(
      DashboardService dashboardService,
      ProductService productService,
      AppLocalizations localizations,
      ) {
    return Container(
      padding: const EdgeInsets.all(20),
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
            localizations.stats,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3A4F),
            ),
          ),
          const SizedBox(height: 16),

          // Ligne 1: Commandes totales et Produits
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.shopping_bag_outlined,
                  value: dashboardService.totalOrders.toString(),
                  label: localizations.totalOrders,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.inventory,
                  value: productService.products.length.toString(),
                  label: localizations.products,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Ligne 2: En attente et Confirmées
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.hourglass_empty,
                  value: dashboardService.pendingOrders.toString(),
                  label: localizations.pending,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.check_circle,
                  value: dashboardService.confirmedOrders.toString(),
                  label: localizations.confirmed,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Ligne 3: En préparation et En livraison
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.build,
                  value: dashboardService.preparingOrders.toString(),
                  label: localizations.preparing,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.local_shipping,
                  value: dashboardService.deliveringOrders.toString(),
                  label: localizations.delivering,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Ligne 4: Livrées et Annulées
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.check_circle,
                  value: dashboardService.deliveredOrders.toString(),
                  label: localizations.delivered,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.cancel,
                  value: dashboardService.cancelledOrders.toString(),
                  label: localizations.cancelled,
                  color: Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Chiffre d'affaires
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.attach_money, color: Colors.green.shade800),
                    const SizedBox(width: 8),
                    Text(
                      localizations.totalRevenue,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${dashboardService.totalSales.toStringAsFixed(2)} ${localizations.currency}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Bouton déconnexion
  Widget _buildLogoutButton(
      BuildContext context,
      AuthService authService,
      AppLocalizations localizations,
      ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutDialog(context, authService, localizations),
        icon: const Icon(Icons.logout),
        label: Text(localizations.logout),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade50,
          foregroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // Widgets réutilisables
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A9AA8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D3A4F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Divider(color: Colors.grey.shade100),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(
      BuildContext context,
      AuthService authService,
      AppLocalizations localizations,
      ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(localizations.logout),
          content: Text(localizations.logoutConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(localizations.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(localizations.logout),
                    duration: const Duration(seconds: 1),
                  ),
                );
                await authService.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(localizations.confirm),
            ),
          ],
        );
      },
    );
  }
}