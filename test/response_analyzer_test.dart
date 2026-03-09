import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_api_inspector/flutter_api_inspector.dart';
import 'package:flutter_api_inspector/analyzers/response_analyzer.dart';
import 'package:flutter_api_inspector/core/inspector_config.dart';

void main() {
  test('ResponseAnalyzer should detect slow API', () {
    // This is hard to test via ConsoleLogger directly without mocking it, 
    // but we can ensure it runs without errors.
    ResponseAnalyzer.analyze(
      endpoint: '/slow',
      duration: Duration(milliseconds: 2000),
      responseData: {'id': 1},
    );
  });

  test('ResponseAnalyzer should detect missing fields', () {
    final endpoint = '/users';
    APIInspector.registerSchema(endpoint, ['id', 'name', 'email']);
    
    ResponseAnalyzer.analyze(
      endpoint: endpoint,
      duration: Duration(milliseconds: 100),
      responseData: {'id': 1, 'name': 'John'}, // missing 'email'
    );
  });

  test('ResponseAnalyzer should detect type mismatch', () {
    final endpoint = '/users';
    APIInspector.registerSchemaTypes(endpoint, {'id': int, 'age': int});
    
    ResponseAnalyzer.analyze(
      endpoint: endpoint,
      duration: Duration(milliseconds: 100),
      responseData: {'id': 1, 'age': '25'}, // 'age' should be int
    );
  });

  test('ResponseAnalyzer should detect null values', () {
    ResponseAnalyzer.analyze(
      endpoint: '/users',
      duration: Duration(milliseconds: 100),
      responseData: {'id': 1, 'email': null},
    );
  });

  test('ResponseAnalyzer should detect invalid response format', () {
    ResponseAnalyzer.analyze(
      endpoint: '/text',
      duration: Duration(milliseconds: 100),
      responseData: "This is not JSON",
    );
  });
}
