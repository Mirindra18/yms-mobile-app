import 'package:dio/dio.dart';
import '../models/finance_models.dart';
import 'api_client.dart';

class FinanceException implements Exception {
  final String message;
  FinanceException(this.message);
  @override
  String toString() => message;
}

/// Accès au module Finance : écolage de l'apprenant + paiement d'échéance.
class FinanceService {
  final ApiClient _apiClient;

  FinanceService(this._apiClient);

  Future<List<EcolageModel>> getMesEcolages() async {
    try {
      final response = await _apiClient.dio.get('/api/finance/ecolages/me');
      final data = response.data;
      if (data is! List) return const [];
      return data
          .map((e) => EcolageModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw FinanceException(_extractError(e, 'Impossible de charger vos écolages.'));
    }
  }

  Future<PaiementModel> payer({
    required int echeanceId,
    required double montant,
    required String modePaiement,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/finance/paiements',
        data: {
          'echeanceId': echeanceId,
          'montant': montant,
          'modePaiement': modePaiement,
        },
      );
      return PaiementModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw FinanceException(_extractError(e, 'Le paiement a échoué. Réessayez.'));
    }
  }

  String _extractError(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String && (data['message'] as String).isNotEmpty) {
      return data['message'] as String;
    }
    if (e.response?.statusCode == 403) {
      return 'Accès refusé.';
    }
    return fallback;
  }
}