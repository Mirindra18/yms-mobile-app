import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Client HTTP central. Adapte [baseUrl] pour pointer vers l'API Gateway
/// (Sarobidy) plutôt que directement vers yms-backend-service si le
/// Gateway route déjà /api/**.
class ApiClient {
  static const String baseUrl = 'https://api.yms.local'; // TODO: adapter (Gateway / env)
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
