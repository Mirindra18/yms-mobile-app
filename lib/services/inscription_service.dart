import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_client.dart'; // Si tu utilises un ApiClient global

// Exception personnalisée pour gérer les erreurs d'inscription
enum InscriptionErrorType { alreadySubscribed, networkError, unknown }

class InscriptionException implements Exception {
  final String message;
  final InscriptionErrorType type;
  InscriptionException(this.message, {this.type = InscriptionErrorType.unknown});

  @override
  String toString() => message;
}

class InscriptionService {
  final ApiClient? apiClient;
  InscriptionService([this.apiClient]);

  // Détection automatique de l'hôte (Émulateur Android vs Chrome/Desktop)
  static String get baseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8081/api';
    }
    return 'http://localhost:8081/api';
  }

  // Méthode de Connexion
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false, 
          'message': error['message'] ?? 'Erreur de connexion'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Impossible de contacter le serveur ($e)'};
    }
  }

  // Méthode d'Inscription utilisateur (Compte)
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String role = 'ROLE_APPRENANT',
  }) async {
    try {
      final nameParts = name.trim().split(' ');
      final String nom = nameParts.first;
      final String prenom = nameParts.length > 1 
          ? nameParts.sublist(1).join(' ') 
          : nom;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nom': nom,
          'prenom': prenom,
          'email': email,
          'password': password,
          'roles': [role],
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false, 
          'message': error['message'] ?? 'Erreur lors de l\'inscription'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Impossible de contacter le serveur ($e)'};
    }
  }

  // Nouvelle méthode pour s'inscrire à une formation spécifique (utilisée par FormationDetailScreen)
  Future<void> inscrireAFormation(int formationId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/formations/$formationId/inscrire'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        if (response.statusCode == 409) {
          throw InscriptionException(
            'Vous êtes déjà inscrit à cette formation.',
            type: InscriptionErrorType.alreadySubscribed,
          );
        }
        final error = jsonDecode(response.body);
        throw InscriptionException(error['message'] ?? 'Erreur lors de l\'inscription à la formation');
      }
    } catch (e) {
      if (e is InscriptionException) rethrow;
      throw InscriptionException(
        'Impossible de contacter le serveur ($e)',
        type: InscriptionErrorType.networkError,
      );
    }
  }
}