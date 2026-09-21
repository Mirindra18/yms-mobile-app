import 'package:dio/dio.dart';
import '../models/presence_model.dart';
import 'api_client.dart';

class PresenceException implements Exception {
  final String message;
  PresenceException(this.message);
  @override
  String toString() => message;
}

/// Historique d'assiduité de l'apprenant connecté.
class PresenceService {
  final ApiClient _apiClient;

  PresenceService(this._apiClient);

  Future<List<PresenceEntry>> getMesPresences() async {
    try {
      final response = await _apiClient.dio.get('/api/presences/me');
      final data = response.data;
      if (data is! List) return const [];
      return data
          .map((p) => PresenceEntry.fromJson(p as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw PresenceException(_extractError(e, 'Impossible de charger vos présences.'));
    }
  }

  String _extractError(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String && (data['message'] as String).isNotEmpty) {
      return data['message'] as String;
    }
    return fallback;
  }
}