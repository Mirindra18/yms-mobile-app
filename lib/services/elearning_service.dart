import 'package:dio/dio.dart';
import '../models/elearning_models.dart';
import '../models/formation_model.dart'; // Import indispensable pour FormationModel
import 'api_client.dart';

class ElearningServiceException implements Exception {
  final String message;
  ElearningServiceException(this.message);
  @override
  String toString() => message;
}

// Alias pour assurer la compatibilité avec les deux branches
typedef ElearningException = ElearningServiceException;

/// Module E-learning : catalogue, contenu du parcours, progression personnelle.
class ElearningService {
  final ApiClient _apiClient;

  ElearningService(this._apiClient);

  /// Liste des formations (compatibilité HEAD)
  Future<List<FormationModel>> listerFormations() async {
    try {
      final response = await _apiClient.dio.get('/api/elearning/formations');
      final data = response.data;
      if (data is! List) return [];
      return data
          .map((e) => FormationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ElearningServiceException(_extractError(e, 'Impossible de charger les formations.'));
    }
  }

  /// Liste des formations (compatibilité feature branch)
  Future<List<ElearningFormation>> getFormations() async {
    try {
      final response = await _apiClient.dio.get('/api/elearning/formations');
      final data = response.data;
      if (data is! List) return [];
      return data
          .map((f) => ElearningFormation.fromJson(f as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ElearningServiceException(_extractError(e, 'Impossible de charger les formations en ligne.'));
    }
  }

  /// Récupère l'intégralité du parcours (compatibilité HEAD)
  Future<FormationContentModel> obtenirParcours(int formationId) async {
    try {
      final response = await _apiClient.dio.get('/api/elearning/formations/$formationId/parcours');
      return FormationContentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ElearningServiceException(_extractError(e, 'Impossible de charger le contenu de la formation.'));
    }
  }

  /// Récupère l'intégralité du parcours (compatibilité feature branch)
  Future<ElearningContent> getParcours(int formationId) async {
    try {
      final response = await _apiClient.dio.get('/api/elearning/formations/$formationId/parcours');
      return ElearningContent.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ElearningServiceException(_extractError(e, 'Impossible de charger le parcours.'));
    }
  }

  /// Progression de l'apprenant (retourne null si 404)
  Future<ProgressionModel?> obtenirMaProgression(int formationId) async {
    try {
      final response = await _apiClient.dio.get('/api/elearning/formations/$formationId/progression/me');
      return ProgressionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw ElearningServiceException(_extractError(e, 'Impossible de charger la progression.'));
    }
  }

  /// Progression de l'apprenant (version standard)
  Future<ProgressionModel> getMaProgression(int formationId) async {
    try {
      final response = await _apiClient.dio.get('/api/elearning/formations/$formationId/progression/me');
      return ProgressionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ElearningServiceException(_extractError(e, 'Impossible de charger votre progression.'));
    }
  }

  /// Signale le démarrage d'une leçon
  Future<ProgressionModel> demarrerLecon(int formationId, int leconId) async {
    try {
      final response = await _apiClient.dio.post(
          '/api/elearning/formations/$formationId/progression/me/lecons/$leconId/demarrer');
      return ProgressionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ElearningServiceException(_extractError(e, 'Impossible de démarrer la leçon.'));
    }
  }

  /// Signale qu'une leçon est terminée
  Future<ProgressionModel> terminerLecon(int formationId, int leconId) async {
    try {
      final response = await _apiClient.dio.post(
          '/api/elearning/formations/$formationId/progression/me/lecons/$leconId/terminer');
      return ProgressionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ElearningServiceException(_extractError(e, 'Impossible de valider la leçon.'));
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