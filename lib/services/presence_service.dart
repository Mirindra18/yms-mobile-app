import 'package:dio/dio.dart';
import '../models/presence_models.dart';
import '../models/presence_model.dart';
import 'api_client.dart';

class PresenceServiceException implements Exception {
  final String message;
  PresenceServiceException(this.message);
  @override
  String toString() => message;
}

// Alias pour la compatibilité avec la branche distante
typedef PresenceException = PresenceServiceException;

/// Service d'accès à l'API du module Présences : scanner de QR Code 
/// et historique d'assiduité de l'apprenant connecté.
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

  /// Récupère l'historique complet des présences (format PresenceModel)
  Future<List<PresenceModel>> listerMonHistorique() async {
    try {
      final response = await _apiClient.dio.get('/api/presences/moi');
      final data = response.data;
      if (data is! List) return [];
      return data
          .map((e) => PresenceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw PresenceServiceException(_extractError(e, 'Impossible de charger votre historique de présence.'));
    }
  }

  /// Récupère l'historique complet des présences (format PresenceEntry - compatibilité distante)
  Future<List<PresenceEntry>> getMesPresences() async {
    try {
      final response = await _apiClient.dio.get('/api/presences/me');
      final data = response.data;
      if (data is! List) return [];
      return data
          .map((p) => PresenceEntry.fromJson(p as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw PresenceServiceException(_extractError(e, 'Impossible de charger vos présences.'));
    }
  }

  String _extractError(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String && (data['message'] as String).isNotEmpty) {
      return data['message'] as String;
    }
    if (e.response?.statusCode == 403) return 'Accès refusé.';
    return fallback;
  }
}