import 'package:dio/dio.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class UserServiceException implements Exception {
  final String message;
  UserServiceException(this.message);
  @override
  String toString() => message;
}

class UserService {
  final ApiClient _apiClient;

  UserService(this._apiClient);

  /// Récupère le profil de l'utilisateur connecté.
  /// NB : si un endpoint GET /api/users/me existe côté backend, l'utiliser
  /// directement ; sinon le décoder depuis le JWT ou l'exposer côté backend.
  Future<UserModel> getProfile() async {
    try {
      final response = await _apiClient.dio.get('/api/users/me');
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw UserServiceException(_extractError(e, 'Impossible de charger le profil.'));
    }
  }

  /// Met à jour le profil. [RG5]
  /// Envoie uniquement les champs non nuls.
  Future<UserModel> updateProfile({
    String? nom,
    String? prenom,
    String? email,
    String? password,
  }) async {
    final body = <String, dynamic>{};
    if (nom != null && nom.isNotEmpty) body['nom'] = nom;
    if (prenom != null && prenom.isNotEmpty) body['prenom'] = prenom;
    if (email != null && email.isNotEmpty) body['email'] = email;
    if (password != null && password.isNotEmpty) body['password'] = password;

    try {
      final response = await _apiClient.dio.put('/api/users/me', data: body);
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw UserServiceException(_extractError(e, 'Impossible de mettre à jour le profil.'));
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
