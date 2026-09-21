import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Client HTTP central. Adapte [baseUrl] pour pointer vers l'API Gateway
/// (Sarobidy) plutôt que directement vers yms-backend-service si le
/// Gateway route déjà /api/**.
class ApiClient {
  /// URL du backend. Elle est injectee au lancement pour que la meme APK
  /// fonctionne en developpement, en recette et en production.
  ///
  /// Exemples :
  /// - Windows / navigateur : http://localhost:8081
  /// - Emulateur Android : http://10.0.2.2:8081
///   - Telephone physique : `http://<IP-DU-PC>:8081`
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Uses the Android emulator host alias by default. A physical phone must
  /// receive its PC LAN address with --dart-define=API_BASE_URL=... .
  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8081';
    }
    return 'http://localhost:8081';
  }
  static const _storage = FlutterSecureStorage();
  static const String tokenKey = 'yms_jwt_token';

  late final Dio dio;

  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (DioException e, handler) {
        // Centraliser ici la gestion des 401 (ex: déconnexion automatique)
        // si besoin, une fois le refresh token / logique de session définie
        // avec Fiderana.
        handler.next(e);
      },
    ));
  }
}
