import '../models/formateur_model.dart';
import 'api_client.dart';
import 'formateur_api_client.dart';
import 'formateur_config.dart';

class FormateurService {
  static FormateurApiClient _client(ApiClient apiClient) =>
      FormateurApiClient(apiClient);

  static Future<List<Seance>> seances(
    ApiClient apiClient,
    String email,
  ) async {
    final data = await _client(apiClient).getList('/api/emploi-du-temps');
    final normalizedEmail = email.toLowerCase();
    return data
        .map((json) => Seance.fromJson(json as Map<String, dynamic>))
        .where((session) =>
            session.formateurEmail.toLowerCase() == normalizedEmail)
        .toList();
  }

  static Future<List<Formation>> formations(
    ApiClient apiClient,
    String email,
  ) async {
    final data = await _client(apiClient).getList('/api/formations');
    final normalizedEmail = email.toLowerCase();
    return data
        .map((json) => Formation.fromJson(json as Map<String, dynamic>))
        .where(
            (formation) => formation.formateurEmail.toLowerCase() == normalizedEmail)
        .toList();
  }

  static Future<List<Inscription>> participants(ApiClient apiClient) async {
    final data = await _client(apiClient)
        .getList('/api/inscriptions/formateur/participants');
    return data
        .map((json) => Inscription.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<List<PresenceSession>> presenceSessions(
    ApiClient apiClient,
    int formationId,
  ) async {
    final data = await _client(apiClient).getList(
      '/api/presences/formations/$formationId/seances',
      baseUrl: FormateurConfig.presenceBaseUrl,
    );
    return data
        .map((json) => PresenceSession.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<PresenceSession> createPresenceSession(
    ApiClient apiClient,
    int formationId,
    String title,
    DateTime start,
    DateTime end,
  ) async {
    final data = await _client(apiClient).post(
      '/api/presences/formations/$formationId/seances',
      baseUrl: FormateurConfig.presenceBaseUrl,
      data: {
        'titre': title,
        'debut': start.toIso8601String(),
        'fin': end.toIso8601String(),
      },
    );
    return PresenceSession.fromJson(data);
  }

  static Future<PresenceSession> activateQr(
    ApiClient apiClient,
    int sessionId,
  ) async {
    final data = await _client(apiClient).post(
      '/api/presences/seances/$sessionId/qr',
      baseUrl: FormateurConfig.presenceBaseUrl,
      data: const {'validiteMinutes': 15},
    );
    return PresenceSession.fromJson(data);
  }

  static Future<PresenceSession> closePresenceSession(
    ApiClient apiClient,
    int sessionId,
  ) async {
    final data = await _client(apiClient).post(
      '/api/presences/seances/$sessionId/cloturer',
      baseUrl: FormateurConfig.presenceBaseUrl,
      data: const {},
    );
    return PresenceSession.fromJson(data);
  }

  static Future<List<PresenceRecord>> sessionAttendance(
    ApiClient apiClient,
    int sessionId,
  ) async {
    final data = await _client(apiClient).getList(
      '/api/presences/seances/$sessionId',
      baseUrl: FormateurConfig.presenceBaseUrl,
    );
    return data
        .map((json) => PresenceRecord.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<PresenceStats> sessionStats(
    ApiClient apiClient,
    int sessionId,
  ) async {
    final data = await _client(apiClient).getObject(
      '/api/presences/seances/$sessionId/statistiques',
      baseUrl: FormateurConfig.presenceBaseUrl,
    );
    return PresenceStats.fromJson(data);
  }

  static Future<PresenceRecord> markPresenceManually(
    ApiClient apiClient,
    int sessionId,
    int participantId,
    String status,
  ) async {
    final data = await _client(apiClient).post(
      '/api/presences/seances/$sessionId/manuel',
      baseUrl: FormateurConfig.presenceBaseUrl,
      data: {'participantId': participantId, 'statut': status},
    );
    return PresenceRecord.fromJson(data);
  }
}
