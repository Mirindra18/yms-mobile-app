// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yms_mobile_app/services/api_client.dart';

void main() {
  test('uses the local backend by default', () {
    final expectedBaseUrl =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android
            ? 'http://10.0.2.2:8081'
            : 'http://localhost:8081';

    expect(ApiClient().dio.options.baseUrl, expectedBaseUrl);
  });
}
