import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../screens/notifications_center_screen.dart';

/// Icône de notifications avec badge du nombre de messages non lus, à
/// placer dans l'AppBar des écrans principaux de l'application.
class NotificationBadgeIcon extends StatelessWidget {
  const NotificationBadgeIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final nombreNonLues = context.watch<NotificationProvider>().nombreNonLues;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsCenterScreen()),
          ),
        ),
        if (nombreNonLues > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(3),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
              child: Text(
                nombreNonLues > 9 ? '9+' : '$nombreNonLues',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
