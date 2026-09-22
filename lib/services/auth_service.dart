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

/// Client des endpoints auth/users du backend YMS.
class AuthService {
  final ApiClient _apiClient;

  static const _storage = FlutterSecureStorage();

  AuthService(this._apiClient);

  // ============================================================
  // INSCRIPTION
  // ============================================================

  Future<String> register({
    required String nom,
    required String prenom,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/auth/register',
        data: {
          'nom': nom,
          'prenom': prenom,
          'email': email,
          'password': password,
          'role': role,
        },
      );

      final data = response.data;

      // Si le backend retourne directement un texte
      if (data is String) {
        return data;
      }

      // Si le backend retourne un objet JSON
      if (data is Map) {
        if (data['message'] is String) {
          return data['message'] as String;
        }

        return data.toString();
      }

      return 'Compte créé avec succès.';
    } on DioException catch (e) {
      throw AuthException(_extractRegisterError(e));
    } catch (e) {
      throw AuthException(
        'Une erreur est survenue lors de la création du compte.',
      );
    }
  }

  // ============================================================
  // CONNEXION
  // ============================================================

  Future<UserModel> login(
    String email,
    String password,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final data = response.data;

      if (data is! Map<String, dynamic>) {
        throw AuthException(
          'Réponse invalide du serveur.',
        );
      }

      final token = data['token'] as String?;

      if (token == null || token.isEmpty) {
        throw AuthException(
          'Réponse invalide du serveur : token manquant.',
        );
      }

      // Sauvegarder le token
      await _storage.write(
        key: ApiClient.tokenKey,
        value: token,
      );

      // Récupérer les informations de l'utilisateur connecté
      return await getCurrentUser();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 ||
          e.response?.statusCode == 403) {
        throw AuthException(
          'Email ou mot de passe incorrect.',
        );
      }

      throw AuthException(
        _extractError(
          e,
          'Impossible de se connecter. Vérifiez votre connexion.',
        ),
      );
    }
  }

  // ============================================================
  // UTILISATEUR CONNECTÉ
  // ============================================================

  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _apiClient.dio.get(
        '/api/users/me',
      );

      final data = response.data;

      if (data is! Map<String, dynamic>) {
        throw AuthException(
          'Réponse invalide du serveur.',
        );
      }

      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw AuthException(
        _extractError(
          e,
          'Session expirée. Veuillez vous reconnecter.',
        ),
      );
    }
  }

  // ============================================================
  // EXTRACTION DES ERREURS GÉNÉRALES
  // ============================================================

  String _extractError(
    DioException e,
    String fallback,
  ) {
    final data = e.response?.data;

    print('======================================');
    print('ERREUR API');
    print('STATUS : ${e.response?.statusCode}');
    print('DATA   : ${e.response?.data}');
    print('======================================');

    if (data is String && data.isNotEmpty) {
      return data;
    }

    if (data is Map) {
      if (data['message'] is String) {
        return data['message'] as String;
      }

      if (data['error'] is String) {
        return data['error'] as String;
      }

      if (data['errors'] is Map) {
        final errors = data['errors'] as Map;

        if (errors.isNotEmpty) {
          return errors.values.first.toString();
        }
      }
    }

    if (e.response?.statusCode == 409) {
      return 'Cette adresse email est déjà utilisée.';
    }

    return fallback;
  }

  // ============================================================
  // EXTRACTION DE L'ERREUR D'INSCRIPTION
  // ============================================================

  String _extractRegisterError(
    DioException e,
  ) {
    print('');
    print('==========================================');
    print('       ERREUR INSCRIPTION YMS');
    print('==========================================');
    print('STATUS : ${e.response?.statusCode}');
    print('URL    : ${e.requestOptions.uri}');
    print('METHOD : ${e.requestOptions.method}');
    print('DATA ENVOYÉE : ${e.requestOptions.data}');
    print('RÉPONSE BACKEND : ${e.response?.data}');
    print('==========================================');
    print('');

    final data = e.response?.data;

    // ----------------------------------------------------------
    // Réponse texte
    // ----------------------------------------------------------

    if (data is String && data.isNotEmpty) {
      return data;
    }

    // ----------------------------------------------------------
    // Réponse JSON
    // ----------------------------------------------------------

    if (data is Map) {
      // Exemple :
      // {
      //   "message": "Email déjà utilisé"
      // }

      if (data['message'] is String) {
        return data['message'] as String;
      }

      // Exemple :
      // {
      //   "error": "Bad Request"
      // }

      if (data['error'] is String) {
        return data['error'] as String;
      }

      // Exemple :
      // {
      //   "errors": {
      //      "email": "Email invalide"
      //   }
      // }

      if (data['errors'] is Map) {
        final errors = data['errors'] as Map;

        if (errors.isNotEmpty) {
          final firstError = errors.values.first;

          if (firstError is List && firstError.isNotEmpty) {
            return firstError.first.toString();
          }

          return firstError.toString();
        }
      }

      // Afficher toute la réponse si son format est différent
      return data.toString();
    }

    // ----------------------------------------------------------
    // Codes HTTP connus
    // ----------------------------------------------------------

    if (e.response?.statusCode == 400) {
      return 'Les données envoyées sont invalides.';
    }

    if (e.response?.statusCode == 409) {
      return 'Cette adresse email est déjà utilisée.';
    }

    if (e.response?.statusCode == 500) {
      return 'Erreur interne du serveur.';
    }

    return 'Impossible de créer le compte.';
  }

  // ============================================================
  // DÉCONNEXION
  // ============================================================

  Future<void> logout() async {
    await _storage.delete(
      key: ApiClient.tokenKey,
    );
  }

  // ============================================================
  // VÉRIFIER SI L'UTILISATEUR EST CONNECTÉ
  // ============================================================

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(
      key: ApiClient.tokenKey,
    );

    return token?.isNotEmpty ?? false;
  }
}