import 'package:dio/dio.dart';
import '../models/notification_models.dart';
import 'api_client.dart';

class NotificationServiceException implements Exception {
  final String message;
  NotificationServiceException(this.message);
  @override
  String toString() => message;
}

/// Service d'accès à l'API REST de notification-service. Ticket
/// MOB-B2 : centre de notifications. La partie temps réel est gérée
/// séparément par [NotificationRealtimeService] (canal WebSocket).
class NotificationService {
  final ApiClient _apiClient;

  NotificationService(this._apiClient);

  Future<List<NotificationModel>> listerMesNotifications({bool nonLuesUniquement = false}) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/notifications/moi',
        queryParameters: {'nonLuesUniquement': nonLuesUniquement},
      );
      return (response.data as List<dynamic>)
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw NotificationServiceException(_extractError(e, 'Impossible de charger les notifications.'));
    }
  }

  Future<int> compterNonLues() async {
    try {
      final response = await _apiClient.dio.get('/api/notifications/moi/compteur');
      return (response.data as Map<String, dynamic>)['nonLues'] as int? ?? 0;
    } on DioException catch (e) {
      throw NotificationServiceException(_extractError(e, 'Impossible de charger le compteur.'));
    }
  }

  /// Marque une notification comme lue. [RG-NOT-05]
  Future<NotificationModel> marquerCommeLue(int destinataireEntryId) async {
    try {
      final response = await _apiClient.dio.put('/api/notifications/$destinataireEntryId/lue');
      return NotificationModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw NotificationServiceException(_extractError(e, 'Impossible de marquer la notification comme lue.'));
    }
  }

  String _extractError(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return fallback;
  }
}
