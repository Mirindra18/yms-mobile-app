import 'package:dio/dio.dart';
import '../models/elearning_models.dart';
import 'api_client.dart';

class ElearningServiceException implements Exception {
  final String message;
  ElearningServiceException(this.message);
  @override
  String toString() => message;
}

/// Service d'accès à l'API du module E-learning (mg.yms.elearning côté
/// backend). Ticket MOB-B1 : lecteur E-learning avec reprise de cours.
class ElearningService {
  final ApiClient _apiClient;

  ElearningService(this._apiClient);

  Future<List<FormationModel>> listerFormations() async {
    try {
      final response = await _apiClient.dio.get('/api/elearning/formations');
      return (response.data as List<dynamic>)
          .map((e) => FormationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ElearningServiceException(_extractError(e, 'Impossible de charger les formations.'));
    }
  }

  /// Récupère l'intégralité du parcours d'une formation (chapitres,
  /// leçons, ressources), utilisé par le lecteur E-learning.
  Future<FormationContentModel> obtenirParcours(int formationId) async {
    try {
      final response = await _apiClient.dio.get('/api/elearning/formations/$formationId/parcours');
      return FormationContentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ElearningServiceException(_extractError(e, 'Impossible de charger le contenu de la formation.'));
    }
  }

  /// Progression de l'apprenant connecté pour une formation, utilisée
  /// pour reprendre la lecture à la dernière leçon consultée.
  Future<ProgressionModel?> obtenirMaProgression(int formationId) async {
    try {
      final response = await _apiClient.dio.get('/api/elearning/formations/$formationId/progression/me');
      return ProgressionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Aucune progression enregistrée : premier accès à la formation.
        return null;
      }
      throw ElearningServiceException(_extractError(e, 'Impossible de charger la progression.'));
    }
  }

  /// Signale le démarrage d'une leçon (première ouverture).
  Future<ProgressionModel> demarrerLecon(int formationId, int leconId) async {
    try {
      final response = await _apiClient.dio
          .post('/api/elearning/formations/$formationId/progression/me/lecons/$leconId/demarrer');
      return ProgressionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ElearningServiceException(_extractError(e, 'Impossible d\'enregistrer le démarrage de la leçon.'));
    }
  }

  /// Signale qu'une leçon est terminée, ce qui permet la reprise du
  /// parcours à la leçon suivante lors d'une prochaine session.
  Future<ProgressionModel> terminerLecon(int formationId, int leconId) async {
    try {
      final response = await _apiClient.dio
          .post('/api/elearning/formations/$formationId/progression/me/lecons/$leconId/terminer');
      return ProgressionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ElearningServiceException(_extractError(e, 'Impossible d\'enregistrer la fin de la leçon.'));
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
