import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_api_inspector/logger/console_logger.dart';
import 'package:flutter_api_inspector/ui/log_storage.dart';

void main() {
  final storage = LogStorage();

  setUp(() {
    storage.clear();
  });

  test('ConsoleLogger should generate unique request IDs', () {
    final id1 = ConsoleLogger.generateRequestId();
    final id2 = ConsoleLogger.generateRequestId();
    expect(id2, equals(id1 + 1));
  });

  test('ConsoleLogger should log detailed request and mask sensitive headers', () {
    final requestId = ConsoleLogger.generateRequestId();
    ConsoleLogger.logRequest(
      requestId: requestId,
      method: 'POST',
      endpoint: '/users',
      fullUrl: 'https://api.example.com/users',
      headers: {
        'Authorization': 'Bearer token123',
        'Content-Type': 'application/json',
      },
      queryParameters: {'page': '1'},
      body: {'name': 'John'},
    );

    final log = storage.logs.first;
    expect(log.type, LogType.request);
    expect(log.message, contains('API REQUEST #$requestId'));
    expect(log.message, contains('Authorization: Bearer *****'));
    expect(log.message, contains('curl -X POST'));
  });

  test('ConsoleLogger should log detailed response and pretty print JSON', () {
    final requestId = ConsoleLogger.generateRequestId();
    ConsoleLogger.logResponse(
      requestId: requestId,
      statusCode: 200,
      endpoint: '/users',
      duration: const Duration(milliseconds: 150),
      responseSize: 100,
      headers: {'content-type': 'application/json'},
      responseBody: {'id': 1, 'name': 'John'},
    );

    final log = storage.logs.first;
    expect(log.type, LogType.response);
    expect(log.message, contains('API RESPONSE #$requestId'));
    expect(log.message, contains('"name": "John"')); // Pretty printed
  });

  test('ConsoleLogger should log replay', () {
    ConsoleLogger.logReplay(7, 'POST', 'https://api.example.com/posts');
    final log = storage.logs.first;
    expect(log.message, contains('REPLAYING REQUEST #7'));
    expect(log.metadata?['isReplay'], true);
  });

  test('ConsoleLogger should log mock usage', () {
    ConsoleLogger.logMockUsage('/users');
    final log = storage.logs.first;
    expect(log.message, contains('MOCK RESPONSE USED'));
    expect(log.metadata?['isMock'], true);
  });
}
