import 'api_client.dart';

class FormateurConfig {
  static const String _presenceUrl = String.fromEnvironment(
    'PRESENCE_API_BASE_URL',
    defaultValue: '',
  );

  static String get presenceBaseUrl {
    if (_presenceUrl.isNotEmpty) return _presenceUrl;
    return Uri.parse(ApiClient.baseUrl).replace(port: 8086).toString();
  }
}
