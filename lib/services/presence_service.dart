import 'package:dio/dio.dart';

import '../models/presence_model.dart';
import '../models/presence_models.dart';
import 'api_client.dart';

class PresenceServiceException implements Exception {
  final String message;

  PresenceServiceException(this.message);

  @override
  String toString() => message;
}

// Compatibilité avec l'ancien code
typedef PresenceException = PresenceServiceException;

/// Service de gestion des présences.
///
/// Les routes correspondent exactement au backend actuel.
///
/// Backend :
/// GET  /api/presences/me
/// GET  /api/presences/me/status-today
/// POST /api/presences/qr/valider?token=...
class PresenceService {
  final ApiClient _apiClient;

  PresenceService(this._apiClient);

  // ============================================================
  // QR CODE
  // ============================================================

  /// Valide une présence à partir du contenu du QR Code.
  ///
  /// Backend :
  /// POST /api/presences/qr/valider?token=...
  Future<PresenceModel> validerPresenceParQrCode(
    String contenuQrCode,
  ) async {
    if (contenuQrCode.trim().isEmpty) {
      throw PresenceServiceException(
        'Le QR Code est vide.',
      );
    }

    try {
      final response = await _apiClient.dio.post(
        '/api/presences/qr/valider',
        queryParameters: {
          'token': contenuQrCode.trim(),
        },
      );

      final data = response.data;

      if (data is! Map<String, dynamic>) {
        throw PresenceServiceException(
          'Réponse invalide du serveur.',
        );
      }

      return PresenceModel.fromJson(data);
    } on DioException catch (e) {
      throw PresenceServiceException(
        _extractError(
          e,
          'Impossible d\'enregistrer la présence.',
        ),
      );
    }
  }

  // ============================================================
  // HISTORIQUE DE L'APPRENANT
  // ============================================================

  /// Récupère l'historique des présences
  /// de l'apprenant actuellement connecté.
  ///
  /// Backend :
  /// GET /api/presences/me
  Future<List<PresenceModel>> listerMonHistorique() async {
    try {
      final response = await _apiClient.dio.get(
        '/api/presences/me',
      );

      final data = response.data;

      if (data is! List) {
        return [];
      }

      return data
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => PresenceModel.fromJson(item),
          )
          .toList();
    } on DioException catch (e) {
      throw PresenceServiceException(
        _extractError(
          e,
          'Impossible de charger votre historique de présence.',
        ),
      );
    }
  }

  /// Ancienne méthode conservée pour éviter
  /// de casser les écrans existants.
  ///
  /// Backend :
  /// GET /api/presences/me
  Future<List<PresenceEntry>> getMesPresences() async {
    try {
      final response = await _apiClient.dio.get(
        '/api/presences/me',
      );

      final data = response.data;

      if (data is! List) {
        return [];
      }

      return data
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => PresenceEntry.fromJson(item),
          )
          .toList();
    } on DioException catch (e) {
      throw PresenceServiceException(
        _extractError(
          e,
          'Impossible de charger vos présences.',
        ),
      );
    }
  }

  // ============================================================
  // STATUT DES SÉANCES DU JOUR
  // ============================================================

  /// Récupère le statut des séances du jour
  /// pour l'apprenant connecté.
  ///
  /// Backend :
  /// GET /api/presences/me/status-today
  ///
  /// Cette méthode est volontairement séparée de
  /// l'historique afin de ne pas mélanger les deux données.
  Future<List<dynamic>> getTodayStatus() async {
    try {
      final response = await _apiClient.dio.get(
        '/api/presences/me/status-today',
      );

      final data = response.data;

      if (data is! List) {
        return [];
      }

      return data;
    } on DioException catch (e) {
      throw PresenceServiceException(
        _extractError(
          e,
          'Impossible de charger le statut des séances.',
        ),
      );
    }
  }

  // ============================================================
  // GESTION DES ERREURS
  // ============================================================

  String _extractError(
    DioException error,
    String fallback,
  ) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    // ----------------------------------------------------------
    // Message envoyé directement par le backend
    // ----------------------------------------------------------

    if (data is Map) {
      final message = data['message'];

      if (message is String && message.trim().isNotEmpty) {
        return message;
      }

      final errorMessage = data['error'];

      if (errorMessage is String &&
          errorMessage.trim().isNotEmpty) {
        return errorMessage;
      }
    }

    // ----------------------------------------------------------
    // Erreurs HTTP
    // ----------------------------------------------------------

    switch (statusCode) {
      case 400:
        return 'La requête est invalide.';

      case 401:
        return 'Votre session a expiré. Veuillez vous reconnecter.';

      case 403:
        return 'Vous n\'avez pas l\'autorisation d\'effectuer cette action.';

      case 404:
        return 'La ressource demandée est introuvable.';

      case 409:
        return 'Votre présence a déjà été enregistrée pour cette séance.';

      case 500:
        return 'Une erreur interne du serveur est survenue.';

      default:
        return fallback;
    }
  }
}