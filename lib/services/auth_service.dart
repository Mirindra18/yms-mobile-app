import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

/// Gère la connexion, le stockage sécurisé du token JWT et la déconnexion.
/// [RG6] : stockage sécurisé du token via flutter_secure_storage.
class AuthService {
  final ApiClient _apiClient;
  static const _storage = FlutterSecureStorage();

  AuthService(this._apiClient);

  /// Adapter le endpoint '/api/auth/login' au contrat exposé par
  /// le module sécurité de Fiderana (POST /api/auth/login attendu ici).
  Future<String> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );

      final token = response.data['token'] as String?;
      if (token == null) {
        throw AuthException('Réponse invalide du serveur : token manquant.');
      }

      await _storage.write(key: ApiClient.tokenKey, value: token);
      return token;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw AuthException('Email ou mot de passe incorrect.');
      }
      throw AuthException('Impossible de se connecter. Vérifiez votre connexion.');
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: ApiClient.tokenKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: ApiClient.tokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<String?> getToken() async {
    return _storage.read(key: ApiClient.tokenKey);
  }
}
