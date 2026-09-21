import 'package:dio/dio.dart';
import '../models/elearning_models.dart';
import 'api_client.dart';

class ElearningException implements Exception {
  final String message;
  ElearningException(this.message);
  @override
  String toString() => message;
}

/// Module E-learning : catalogue, contenu du parcours, progression personnelle.
class ElearningService {
  final ApiClient _apiClient;

  ElearningService(this._apiClient);

  Future<List<ElearningFormation>> getFormations() async {
    try {
      final response = await _apiClient.dio.get('/api/elearning/formations');
      final data = response.data;
      if (data is! List) return const [];
      return data
          .map((f) => ElearningFormation.fromJson(f as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ElearningException(_extractError(e, 'Impossible de charger les formations en ligne.'));
    }
  }

  Future<ElearningContent> getParcours(int formationId) async {
    try {
      final response =
          await _apiClient.dio.get('/api/elearning/formations/$formationId/parcours');
      return ElearningContent.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ElearningException(_extractError(e, 'Impossible de charger le parcours.'));
    }
  }

  Future<ProgressionModel> getMaProgression(int formationId) async {
    try {
      final response = await _apiClient.dio
          .get('/api/elearning/formations/$formationId/progression/me');
      return ProgressionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ElearningException(_extractError(e, 'Impossible de charger votre progression.'));
    }
  }

  Future<ProgressionModel> demarrerLecon(int formationId, int leconId) async {
    try {
      final response = await _apiClient.dio.post(
          '/api/elearning/formations/$formationId/progression/me/lecons/$leconId/demarrer');
      return ProgressionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ElearningException(_extractError(e, 'Impossible de démarrer la leçon.'));
    }
  }

  Future<ProgressionModel> terminerLecon(int formationId, int leconId) async {
    try {
      final response = await _apiClient.dio.post(
          '/api/elearning/formations/$formationId/progression/me/lecons/$leconId/terminer');
      return ProgressionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ElearningException(_extractError(e, 'Impossible de valider la leçon.'));
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