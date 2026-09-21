import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user_model.dart';
import 'api_client.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

/// Client of identity-service only. Other domain services never handle passwords.
class AuthService {
  final ApiClient _apiClient;
  static const _storage = FlutterSecureStorage();

  AuthService(this._apiClient);

  Future<UserModel> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/auth/register',
        data: {'firstName': firstName, 'lastName': lastName, 'email': email, 'password': password},
      );
      return _storeSession(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AuthException(_extractError(e, 'Impossible de créer le compte.'));
    }
  }

  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/auth/login',
        data: {'email': email, 'password': password},
      );
      return _storeSession(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw AuthException('Email ou mot de passe incorrect.');
      }
      throw AuthException(_extractError(e, 'Impossible de se connecter. Vérifiez votre connexion.'));
    }
  }

  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _apiClient.dio.get('/api/v1/users/me');
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AuthException(_extractError(e, 'Session expirée. Veuillez vous reconnecter.'));
    }
  }

  Future<UserModel> _storeSession(Map<String, dynamic> data) async {
    final token = data['accessToken'] as String?;
    if (token == null || token.isEmpty) {
      throw AuthException('Réponse invalide du serveur : access token manquant.');
    }
    await _storage.write(key: ApiClient.tokenKey, value: token);
    return UserModel.fromJson(data);
  }

  String _extractError(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) return data['message'] as String;
    if (e.response?.statusCode == 409) return 'Cette adresse email est déjà utilisée.';
    return fallback;
  }

  Future<void> logout() => _storage.delete(key: ApiClient.tokenKey);
  Future<bool> isLoggedIn() async => (await _storage.read(key: ApiClient.tokenKey))?.isNotEmpty ?? false;
}
