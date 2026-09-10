import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../models/notification_models.dart';
import 'api_client.dart';

/// Connexion temps réel au canal WebSocket (STOMP) de notification-service.
/// [RG-NOT-07] diffusion en temps réel des notifications.
///
/// NB : le endpoint backend est exposé avec SockJS
/// (`registry.addEndpoint("/ws/notifications").withSockJS()`). Le
/// paquet stomp_dart_client ne parle pas le protocole SockJS complet ;
/// on se connecte donc directement au transport WebSocket brut exposé
/// par SockJS via le suffixe `/websocket`. Si le Gateway modifie ce
/// comportement, adapter [_urlWebSocket] en conséquence (à confirmer
/// avec Sarobidy une fois le Gateway finalisé).
class NotificationRealtimeService {
  final ApiClient _apiClient;
  StompClient? _client;
  static const _storage = FlutterSecureStorage();

  NotificationRealtimeService(this._apiClient);

  String get _urlWebSocket {
    final base = _apiClient.dio.options.baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    return '$base/ws/notifications/websocket';
  }

  /// Ouvre la connexion et s'abonne au canal de l'utilisateur
  /// [destinataireId]. [onNotification] est appelé pour chaque
  /// nouvelle notification reçue en temps réel.
  Future<void> connecter({
    required int destinataireId,
    required void Function(NotificationModel notification) onNotification,
  }) async {
    final token = await _storage.read(key: ApiClient.tokenKey);

    _client = StompClient(
      config: StompConfig(
        url: _urlWebSocket,
        onConnect: (frame) {
          _client?.subscribe(
            destination: '/topic/notifications/$destinataireId',
            callback: (frame) {
              final body = frame.body;
              if (body == null) return;
              final json = jsonDecode(body) as Map<String, dynamic>;
              onNotification(NotificationModel.fromJson(json));
            },
          );
        },
        stompConnectHeaders: token != null ? {'Authorization': 'Bearer $token'} : {},
        webSocketConnectHeaders: token != null ? {'Authorization': 'Bearer $token'} : {},
        onWebSocketError: (error) {
          // La reconnexion automatique de stomp_dart_client (paramètre
          // reconnectDelay ci-dessous) reprend seule ; on journalise
          // simplement ici pour le diagnostic en développement.
        },
        reconnectDelay: const Duration(seconds: 5),
      ),
    );

    _client?.activate();
  }

  void deconnecter() {
    _client?.deactivate();
    _client = null;
  }
}
