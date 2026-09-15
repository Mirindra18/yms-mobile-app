import 'package:dio/dio.dart';
import '../models/consultation_models.dart';
import 'api_client.dart';

class ConsultationServiceException implements Exception {
  final String message;
  ConsultationServiceException(this.message);
  @override
  String toString() => message;
}

/// Service d'accès à l'API du microservice consultation-service.
/// Ticket MOB-B1 : module de prise de RDV / Consultations.
///
/// NB : consultation-service tourne aujourd'hui comme processus
/// indépendant (port 8084, voir yms-backend-service/consultation-service).
/// Ce service suppose que l'API Gateway route /api/consultations/**
/// vers ce microservice, comme pour les autres modules. Si le Gateway
/// n'est pas encore en place, adapter [ApiClient.baseUrl] ou utiliser
/// une base URL dédiée le temps de l'intégration finale (à confirmer
/// avec Sarobidy).
class ConsultationService {
  final ApiClient _apiClient;

  ConsultationService(this._apiClient);

  Future<List<CreneauModel>> listerCreneauxDisponibles() async {
    try {
      final response = await _apiClient.dio.get('/api/consultations/creneaux');
      return (response.data as List<dynamic>)
          .map((e) => CreneauModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ConsultationServiceException(_extractError(e, 'Impossible de charger les créneaux disponibles.'));
    }
  }

  /// Demande une consultation sur le créneau sélectionné. [RG-CON-01]
  Future<ConsultationModel> demanderConsultation({required int creneauId, String? motif}) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/consultations',
        data: {'creneauId': creneauId, 'motif': motif},
      );
      return ConsultationModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw ConsultationServiceException('Ce créneau vient d\'être réservé par un autre utilisateur.');
      }
      throw ConsultationServiceException(_extractError(e, 'Impossible d\'envoyer la demande de consultation.'));
    }
  }

  Future<List<ConsultationModel>> listerMesConsultations() async {
    try {
      final response = await _apiClient.dio.get('/api/consultations/moi');
      return (response.data as List<dynamic>)
          .map((e) => ConsultationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ConsultationServiceException(_extractError(e, 'Impossible de charger vos consultations.'));
    }
  }

  Future<ConsultationModel> annuler(int consultationId) async {
    try {
      final response = await _apiClient.dio.put(
        '/api/consultations/$consultationId/statut',
        data: {'statut': 'ANNULEE'},
      );
      return ConsultationModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ConsultationServiceException(_extractError(e, 'Impossible d\'annuler la consultation.'));
    }
  }

  /// Reprogramme une consultation vers un nouveau créneau. [RG-CON-06]
  Future<ConsultationModel> reprogrammer({required int consultationId, required int nouveauCreneauId}) async {
    try {
      final response = await _apiClient.dio.put(
        '/api/consultations/$consultationId/reprogrammation',
        data: {'nouveauCreneauId': nouveauCreneauId},
      );
      return ConsultationModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ConsultationServiceException(_extractError(e, 'Impossible de reprogrammer la consultation.'));
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
