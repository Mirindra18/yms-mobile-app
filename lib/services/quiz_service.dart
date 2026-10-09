import 'package:dio/dio.dart';

import '../models/quiz_model.dart';
import 'api_client.dart';

class QuizService {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'QUIZ_API_BASE_URL',
    defaultValue: '',
  );

  final ApiClient _apiClient;

  QuizService(this._apiClient);

  String get _baseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    return Uri.parse(ApiClient.baseUrl)
        .replace(port: 8088, path: '', query: null, fragment: null)
        .toString()
        .replaceFirst(RegExp(r'/$'), '');
  }

  String _url(String path) => Uri.parse(_baseUrl).resolve(path).toString();

  Future<List<QuizModel>> getQuizzes() async {
    final response = await _apiClient.dio.get<dynamic>(_url('/api/quiz'));
    if (response.data case final List<dynamic> items) {
      return items
          .whereType<Map>()
          .map((item) => QuizModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    throw const FormatException(
      'Réponse API invalide : une liste de quiz était attendue.',
    );
  }

  Future<QuizResultModel> submit(int quizId, Map<int, int> answers) async {
    final response = await _apiClient.dio.post<dynamic>(
      _url('/api/quiz/$quizId/soumettre'),
      data: {
        'reponses': answers.map(
          (questionId, answerIndex) =>
              MapEntry(questionId.toString(), answerIndex),
        ),
      },
    );
    if (response.data case final Map<String, dynamic> result) {
      return QuizResultModel.fromJson(result);
    }
    throw const FormatException(
      'Réponse API invalide : un résultat de quiz était attendu.',
    );
  }

  static String errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      if (error.response?.statusCode == 401) {
        return 'Votre session a expiré. Reconnectez-vous puis réessayez.';
      }
      if (error.response?.statusCode == 403) {
        return 'Votre compte ne peut pas accéder à ces quiz.';
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Le service des quiz est inaccessible. Vérifiez votre connexion.';
      }
    }
    if (error is FormatException) return error.message;
    return 'Impossible de charger les quiz. Réessayez.';
  }
}
