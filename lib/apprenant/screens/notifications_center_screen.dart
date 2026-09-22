import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/notification_models.dart';
import '../../providers/notification_provider.dart';

/// Centre de notifications en temps réel. Ticket MOB-B2.
class NotificationsCenterScreen extends StatefulWidget {
  const NotificationsCenterScreen({super.key});

  @override
  State<NotificationsCenterScreen> createState() => _NotificationsCenterScreenState();
}

class _NotificationsCenterScreenState extends State<NotificationsCenterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().chargerNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(title: const Text('Notifications')),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.status == LoadStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.notifications.isEmpty) {
            return const Center(child: Text('Aucune notification pour le moment.'));
          }

          return RefreshIndicator(
            onRefresh: provider.chargerNotifications,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                return _NotificationTile(
                  notification: notification,
                  onTap: () => provider.marquerCommeLue(notification),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  IconData get _icone => switch (notification.type) {
        TypeNotification.formation => Icons.menu_book_outlined,
        TypeNotification.inscription => Icons.how_to_reg_outlined,
        TypeNotification.rendezVous => Icons.event_outlined,
        TypeNotification.modification => Icons.edit_outlined,
        TypeNotification.annulation => Icons.cancel_outlined,
        TypeNotification.rappel => Icons.notifications_active_outlined,
        TypeNotification.informationGenerale => Icons.info_outline,
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      color: notification.lue ? Colors.white : const Color(0xFFEAF1FB),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF2E5AAC).withValues(alpha: 0.1),
          child: Icon(_icone, color: const Color(0xFF2E5AAC)),
        ),
        title: Text(
          notification.titre,
          style: TextStyle(fontWeight: notification.lue ? FontWeight.normal : FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification.contenu),
            const SizedBox(height: 4),
            Text(
              DateFormat('d MMM yyyy à HH:mm', 'fr_FR').format(notification.createdAt),
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ],
        ),
        trailing: notification.lue ? null : const CircleAvatar(radius: 5, backgroundColor: Color(0xFF2E5AAC)),
        isThreeLine: true,
      ),
    );
  }
}
