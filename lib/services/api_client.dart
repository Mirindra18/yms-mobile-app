import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Client HTTP centralisé pour l'application YMS.
class ApiClient {
/// URL configurable au lancement.
///
/// Exemples :
/// - Navigateur / Windows : http://localhost:8081
/// - Émulateur Android : http://10.0.2.2:8081
/// - Téléphone physique : http://IP_DU_PC:8081
static const String _configuredBaseUrl = String.fromEnvironment(
'API_BASE_URL',
defaultValue: '',
);

static String get baseUrl {
if (_configuredBaseUrl.isNotEmpty) {
return _configuredBaseUrl;
}


if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
  return 'http://10.0.2.2:8081';
}

return 'http://localhost:8081';

}

static const FlutterSecureStorage _storage = FlutterSecureStorage();

static const String tokenKey = 'yms_jwt_token';

late final Dio dio;

ApiClient() {
dio = Dio(
BaseOptions(
baseUrl: baseUrl,
connectTimeout: const Duration(seconds: 10),
receiveTimeout: const Duration(seconds: 10),
headers: const {
'Content-Type': 'application/json',
'Accept': 'application/json',
},
),
);

dio.interceptors.add(
  InterceptorsWrapper(
    onRequest: (options, handler) async {
      try {
        final storedToken = await _storage.read(key: tokenKey);
        final token = storedToken?.trim();

        if (token == null || token.isEmpty) {
          options.headers.remove('Authorization');
          handler.next(options);
          return;
        }

        // Ne jamais envoyer un JWT déjà expiré.
        if (_isTokenExpired(token)) {
          await _storage.delete(key: tokenKey);
          options.headers.remove('Authorization');

          debugPrint(
            '[ApiClient] JWT expiré supprimé. '
            'Une nouvelle connexion est nécessaire.',
          );

          handler.next(options);
          return;
        }

        options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      } catch (error, stackTrace) {
        debugPrint(
          '[ApiClient] Erreur lors de la lecture du token : $error',
        );
        debugPrintStack(stackTrace: stackTrace);

        handler.reject(
          DioException(
            requestOptions: options,
            error: error,
            message: 'Impossible de lire le token de connexion.',
          ),
        );
      }
    },
    onError: (error, handler) async {
      final statusCode = error.response?.statusCode;

      // Un 401 signifie que la requête n'est pas authentifiée.
      // On supprime le token pour éviter de le réutiliser.
      if (statusCode == 401) {
        try {
          await _storage.delete(key: tokenKey);
          debugPrint(
            '[ApiClient] Réponse 401 : token supprimé.',
          );
        } catch (storageError) {
          debugPrint(
            '[ApiClient] Impossible de supprimer le token : '
            '$storageError',
          );
        }
      }

      // Un 403 peut simplement signifier que le rôle n'a pas
      // l'autorisation d'accéder à la ressource : on conserve
      // donc le token dans ce cas.
      handler.next(error);
    },
  ),
);


}

/// Vérifie la date d'expiration du JWT à partir de sa propriété `exp`.
///
/// Renvoie true si le token est expiré.
/// Si le token ne peut pas être décodé ou ne contient pas `exp`,
/// la vérification locale ne peut pas confirmer son expiration.
/// Le backend reste responsable de la validation définitive.
static bool _isTokenExpired(String token) {
try {
final parts = token.split('.');


  if (parts.length != 3) {
    return false;
  }

  final payloadBytes = base64Url.decode(
    base64Url.normalize(parts[1]),
  );

  final payload = jsonDecode(
    utf8.decode(payloadBytes),
  );

  if (payload is! Map<String, dynamic>) {
    return false;
  }

  final expiration = payload['exp'];

  if (expiration is! num) {
    return false;
  }

  final nowInSeconds =
      DateTime.now().millisecondsSinceEpoch / 1000;

  return nowInSeconds >= expiration.toDouble();
} catch (_) {
  // En cas de format inattendu, le serveur vérifiera le token.
  return false;
}


}
}
