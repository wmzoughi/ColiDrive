// lib/screens/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadNotifications({bool reset = false}) async {
    final service = Provider.of<NotificationService>(context, listen: false);
    await service.loadNotifications(reset: reset);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final service = Provider.of<NotificationService>(context, listen: false);
      if (service.hasMore && !service.isLoading) {
        _loadNotifications();
      }
    }
  }

  Future<void> _markAsRead(String id) async {
    final service = Provider.of<NotificationService>(context, listen: false);
    await service.markAsRead(id);
  }

  Future<void> _deleteNotification(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer'),
        content: const Text('Supprimer cette notification ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final service = Provider.of<NotificationService>(context, listen: false);
      await service.deleteNotification(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<NotificationService>(context);
    final authService = Provider.of<AuthService>(context);

    // ✅ Déterminer le type d'utilisateur
    final userType = authService.currentUser?.userType;

    // ✅ Filtrer les notifications selon le type d'utilisateur
    final displayNotifications = userType == 'fournisseur'
        ? service.getSupplierNotifications()
        : service.getMerchantNotifications();

    // ✅ Calculer les non lues pour l'affichage
    final displayUnreadCount = userType == 'fournisseur'
        ? service.getSupplierNotifications().where((n) => !n.isRead).length
        : service.getMerchantNotifications().where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFF2D3A4F),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3A4F)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (displayUnreadCount > 0)
            TextButton(
              onPressed: () async {
                final service = Provider.of<NotificationService>(context, listen: false);
                await service.markAllAsRead();
              },
              child: Text(
                'Tout marquer comme lu',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF2D3A4F)),
            onPressed: () => _loadNotifications(reset: true),
          ),
        ],
      ),
      body: service.isLoading && service.notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : displayNotifications.isEmpty
          ? _buildEmptyState(userType)
          : RefreshIndicator(
        onRefresh: () => _loadNotifications(reset: true),
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: displayNotifications.length + (service.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == displayNotifications.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final notification = displayNotifications[index];

            return Dismissible(
              key: Key(notification.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
              confirmDismiss: (direction) async {
                return await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Supprimer'),
                    content: const Text('Supprimer cette notification ?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Annuler'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Supprimer'),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (direction) async {
                final service = Provider.of<NotificationService>(context, listen: false);
                await service.deleteNotification(notification.id);
              },
              child: GestureDetector(
                onTap: () async {
                  if (!notification.isRead) {
                    await _markAsRead(notification.id);
                  }

                  if (notification.actionRoute != null) {
                    Navigator.pushNamed(
                      context,
                      notification.actionRoute!,
                      arguments: notification.actionArgs,
                    );
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: notification.isRead ? Colors.white : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: notification.isRead
                          ? Colors.grey.shade200
                          : AppColors.primary.withOpacity(0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: notification.color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          notification.icon,
                          color: notification.color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notification.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                if (!notification.isRead)
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification.message,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            if (notification.data.containsKey('order_number'))
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Commande: ${notification.data['order_number']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ),
                            if (notification.data.containsKey('product_name'))
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Produit: ${notification.data['product_name']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              notification.createdAt,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ✅ Nouvelle méthode pour l'état vide personnalisé
  Widget _buildEmptyState(String? userType) {
    String title = userType == 'fournisseur'
        ? 'Aucune nouvelle commande'
        : 'Aucune notification';

    String message = userType == 'fournisseur'
        ? 'Vous n\'avez pas encore reçu de commandes'
        : 'Vous n\'avez pas encore de mises à jour sur vos commandes';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
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