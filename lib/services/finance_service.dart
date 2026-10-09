import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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

  /// Récupère les écolages de l'apprenant connecté.
  ///
  /// Correspond exactement à l'API utilisée par le Web :
  /// GET /api/finance/ecolages/me
  Future<List<EcolageModel>> getMesEcolages() async {
    try {
      final response =
          await _apiClient.dio.get('/api/finance/ecolages/me');

      final data = response.data;

      // Logs temporaires pour comparer Flutter avec le Web.
      debugPrint('========================================');
      debugPrint('=== FINANCE /ecolages/me ===');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Data: $data');
      debugPrint('Type: ${data.runtimeType}');
      debugPrint('========================================');

      if (data is! List) {
        debugPrint(
          'Finance: la réponse n\'est pas une liste.',
        );
        return const [];
      }

      final ecolages = data
          .whereType<Map>()
          .map(
            (e) => EcolageModel.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();

      debugPrint(
        'Nombre d\'écolages reçus: ${ecolages.length}',
      );

      for (final ecolage in ecolages) {
        debugPrint(
          'Écolage #${ecolage.id} '
          '| email=${ecolage.apprenantEmail} '
          '| formation=${ecolage.formationId} '
          '| total=${ecolage.montantTotal} '
          '| solde=${ecolage.soldeDu} '
          '| échéances=${ecolage.echeances.length}',
        );
      }

      return ecolages;
    } on DioException catch (e) {
      debugPrint('========================================');
      debugPrint('=== FINANCE ERROR ===');
      debugPrint('Status: ${e.response?.statusCode}');
      debugPrint('Data: ${e.response?.data}');
      debugPrint('Message: ${e.message}');
      debugPrint('========================================');

      throw FinanceException(
        _extractError(
          e,
          'Impossible de charger vos écolages.',
        ),
      );
    } catch (e) {
      debugPrint('Erreur inattendue Finance: $e');

      throw FinanceException(
        'Impossible de charger vos écolages.',
      );
    }
  }

  /// Enregistre un paiement.
  ///
  /// Correspond exactement à l'API utilisée par le Web :
  /// POST /api/finance/paiements
  Future<PaiementModel> payer({
    required int echeanceId,
    required double montant,
    required String modePaiement,
    required String referenceTransaction,
  }) async {
    try {
      final requestData = {
        'echeanceId': echeanceId,
        'montant': montant,
        'modePaiement': modePaiement,
        'referenceTransaction': referenceTransaction.trim(),
      };

      debugPrint('========================================');
      debugPrint('=== FINANCE /paiements ===');
      debugPrint('Request: $requestData');
      debugPrint('========================================');

      final response = await _apiClient.dio.post(
        '/api/finance/paiements',
        data: requestData,
      );

      debugPrint('=== PAIEMENT RESPONSE ===');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Data: ${response.data}');

      return PaiementModel.fromJson(
        Map<String, dynamic>.from(
          response.data as Map,
        ),
      );
    } on DioException catch (e) {
      debugPrint('========================================');
      debugPrint('=== PAIEMENT ERROR ===');
      debugPrint('Status: ${e.response?.statusCode}');
      debugPrint('Data: ${e.response?.data}');
      debugPrint('Message: ${e.message}');
      debugPrint('========================================');

      throw FinanceException(
        _extractError(
          e,
          'Le paiement a échoué. Réessayez.',
        ),
      );
    } catch (e) {
      debugPrint('Erreur inattendue paiement: $e');

      throw FinanceException(
        'Le paiement a échoué. Réessayez.',
      );
    }
  }

  /// Extrait le message d'erreur envoyé par le backend.
  String _extractError(
    DioException e,
    String fallback,
  ) {
    final data = e.response?.data;

    if (data is Map &&
        data['message'] is String &&
        (data['message'] as String).isNotEmpty) {
      return data['message'] as String;
    }

    if (e.response?.statusCode == 403) {
      return 'Accès refusé.';
    }

    if (e.response?.statusCode == 401) {
      return 'Session expirée. Veuillez vous reconnecter.';
    }

    return fallback;
  }
}