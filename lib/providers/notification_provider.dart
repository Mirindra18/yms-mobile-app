import 'package:flutter/foundation.dart';
import '../models/notification_models.dart';
import '../models/user_model.dart';
import '../services/notification_realtime_service.dart';
import '../services/notification_service.dart';

enum LoadStatus { idle, loading, success, error }

/// Fournit à l'interface le centre de notifications de l'utilisateur
/// connecté : liste, compteur non lues, marquage lu, et réception en
/// temps réel via WebSocket. Ticket MOB-B2.
class NotificationProvider extends ChangeNotifier {
  final NotificationService _service;
  final NotificationRealtimeService _realtimeService;

  NotificationProvider(this._service, this._realtimeService);

  LoadStatus status = LoadStatus.idle;
  String? errorMessage;
  List<NotificationModel> notifications = [];
  int nombreNonLues = 0;

  Future<void> chargerNotifications() async {
    status = LoadStatus.loading;
    notifyListeners();

    try {
      notifications = await _service.listerMesNotifications();
      nombreNonLues = notifications.where((n) => !n.lue).length;
      status = LoadStatus.success;
    } on NotificationServiceException catch (e) {
      errorMessage = e.message;
      status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> marquerCommeLue(NotificationModel notification) async {
    if (notification.lue) return;

    try {
      final miseAJour = await _service.marquerCommeLue(notification.destinataireEntryId);
      notifications = notifications
          .map((n) => n.destinataireEntryId == miseAJour.destinataireEntryId ? miseAJour : n)
          .toList();
      nombreNonLues = notifications.where((n) => !n.lue).length;
      notifyListeners();
    } on NotificationServiceException catch (e) {
      errorMessage = e.message;
      notifyListeners();
    }
  }

  /// Ouvre la connexion temps réel pour l'utilisateur connecté, afin
  /// que les nouvelles notifications apparaissent immédiatement sans
  /// nécessiter de rafraîchissement manuel. [RG-NOT-07]
  Future<void> demarrerEcouteTempsReel(UserModel utilisateur) async {
    await _realtimeService.connecter(
      destinataireId: utilisateur.id,
      onNotification: (notification) {
        notifications = [notification, ...notifications];
        nombreNonLues += notification.lue ? 0 : 1;
        notifyListeners();
      },
    );
  }

  void arreterEcouteTempsReel() {
    _realtimeService.deconnecter();
  }

  @override
  void dispose() {
    arreterEcouteTempsReel();
    super.dispose();
  }
}
