import 'api_client.dart';

class FormateurApiClient {
  final ApiClient _apiClient;

  FormateurApiClient(this._apiClient);

  Future<List<dynamic>> getList(
    String path, {
    String? baseUrl,
  }) async {
    final url = baseUrl == null ? path : Uri.parse(baseUrl).resolve(path).toString();
    final response = await _apiClient.dio.get<dynamic>(url);
    if (response.data case final List<dynamic> data) return data;
    throw const FormatException(
      'Réponse API invalide : une liste était attendue.',
    );
  }

  Future<Map<String, dynamic>> getObject(
    String path, {
    String? baseUrl,
  }) async {
    final url = baseUrl == null ? path : Uri.parse(baseUrl).resolve(path).toString();
    final response = await _apiClient.dio.get<dynamic>(url);
    if (response.data case final Map<String, dynamic> data) return data;
    throw const FormatException(
      'Réponse API invalide : un objet était attendu.',
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> data,
    String? baseUrl,
  }) async {
    final url = baseUrl == null ? path : Uri.parse(baseUrl).resolve(path).toString();
    final response = await _apiClient.dio.post<dynamic>(url, data: data);
    if (response.data case final Map<String, dynamic> data) return data;
    throw const FormatException(
      'Réponse API invalide : un objet était attendu.',
    );
  }
}
