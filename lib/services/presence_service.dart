import 'package:dio/dio.dart';
import '../models/presence_models.dart';
import 'api_client.dart';

class PresenceServiceException implements Exception {
  final String message;
  PresenceServiceException(this.message);
  @override
  String toString() => message;
}

/// Service d'accès à l'API du module Présences. Ticket MOB-B2 :
/// scanner de QR Code pour valider sa présence.
///
/// À CONFIRMER AVEC SAROBIDY : endpoints /api/presences/** en attente
/// du microservice presence-service (BACK-B3). Voir presence_models.dart.
class PresenceService {
  final ApiClient _apiClient;

  PresenceService(this._apiClient);

  /// Envoie le contenu brut du QR Code scanné afin d'enregistrer la
  /// présence de l'apprenant connecté à la séance correspondante.
  /// [RG-PRES-04] la présence peut être enregistrée par scan de QR Code.
  Future<PresenceModel> validerPresenceParQrCode(String contenuQrCode) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/presences/scan',
        data: {'qrCode': contenuQrCode},
      );
      return PresenceModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw PresenceServiceException('Votre présence a déjà été enregistrée pour cette séance.');
      }
      if (e.response?.statusCode == 400) {
        throw PresenceServiceException('QR Code invalide ou expiré.');
      }
      throw PresenceServiceException(_extractError(e, 'Impossible d\'enregistrer la présence.'));
    }
  }

  Future<List<PresenceModel>> listerMonHistorique() async {
    try {
      final response = await _apiClient.dio.get('/api/presences/moi');
      return (response.data as List<dynamic>)
          .map((e) => PresenceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw PresenceServiceException(_extractError(e, 'Impossible de charger votre historique de présence.'));
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
