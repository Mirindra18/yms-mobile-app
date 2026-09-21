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

/// Inscription d'un apprenant à une formation (POST /inscrire)
/// et vérification du statut (GET /mon-inscription).
/// 100 % basé sur ApiClient Dio — fonctionne sur mobile ET web.
class InscriptionService {
  final ApiClient _apiClient;
  InscriptionService(this._apiClient);

  Future<void> inscrireAFormation(int formationId) async {
    try {
      await _apiClient.dio.post('/api/formations/$formationId/inscrire');
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

  Future<bool> estInscritAFormation(int formationId) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/formations/$formationId/mon-inscription',
      );
      return response.data is Map && response.data['inscrit'] == true;
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