import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_api_inspector/flutter_api_inspector.dart';

void main() {
  test('APIInspector.attach should add interceptors to Dio', () {
    final dio = Dio();
    final initialInterceptorsCount = dio.interceptors.length;

    APIInspector.initialize();
    APIInspector.attach(dio);

    // It adds RequestInterceptor and ResponseInterceptor
    expect(dio.interceptors.length, initialInterceptorsCount + 2);
  });

  test('APIInspector.attach should not add interceptors when disabled', () {
    final dio = Dio();
    final initialInterceptorsCount = dio.interceptors.length;

    APIInspector.initialize(enabled: false);
    APIInspector.attach(dio);

    expect(dio.interceptors.length, initialInterceptorsCount);
  });
}
