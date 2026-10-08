import 'package:dio/dio.dart';
import 'api_client.dart';

enum InscriptionErrorType { alreadySubscribed, networkError, unknown }

class InscriptionException implements Exception {
  final String message;
  final InscriptionErrorType type;
  InscriptionException(this.message, {this.type = InscriptionErrorType.unknown});
  @override
  String toString() => message;
}

/// Inscription d'un apprenant à une formation et vérification du statut.
/// 100 % basé sur ApiClient Dio — fonctionne sur mobile ET web.
class InscriptionService {
  final ApiClient _apiClient;
  InscriptionService(this._apiClient);

  Future<void> inscrireAFormation(int formationId) async {
    try {
      await _apiClient.dio.post('/api/inscriptions/formations/$formationId');
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw InscriptionException(
          'Vous êtes déjà inscrit à cette formation.',
          type: InscriptionErrorType.alreadySubscribed,
        );
      }
      throw InscriptionException(_extractMessage(e, 'Erreur lors de l\'inscription à la formation'));
    } catch (e) {
      throw InscriptionException(
        'Impossible de contacter le serveur ($e)',
        type: InscriptionErrorType.networkError,
      );
    }
  }

  /// Le backend n'a pas d'endpoint dédié à la vérification d'une seule
  /// formation : on récupère toutes les inscriptions de l'utilisateur
  /// connecté (GET /api/inscriptions/me) et on cherche localement.
  Future<bool> estInscritAFormation(int formationId) async {
    try {
      final response = await _apiClient.dio.get('/api/inscriptions/me');
      final data = response.data;
      if (data is! List) return false;

      return data.any((item) => item is Map && item['formationId'] == formationId);
    } on DioException catch (_) {
      return false;
    }
  }

  String _extractMessage(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return fallback;
  }
}