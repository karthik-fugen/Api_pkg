import 'package:dio/dio.dart';
// Import internal files to avoid flutter dependency in standalone dart run
import 'package:flutter_api_inspector/core/api_inspector.dart';

void main() async {
  // 1. Initialize
  APIInspector.initialize();

  // 2. Setup Dio
  final dio = Dio();
  
  // 3. Attach
  APIInspector.attach(dio);

  print('--- STARTING NON-UI TEST DRIVE ---\n');

  try {
    print('Sending Request #1 (GET Detailed)...');
    await dio.get('https://jsonplaceholder.typicode.com/posts/1');

    print('\nSending Request #2 (POST with Body & Masked Headers)...');
    await dio.post(
      'https://jsonplaceholder.typicode.com/posts',
      data: {'title': 'foo', 'body': 'bar', 'userId': 1},
      options: Options(headers: {
        'Authorization': 'Bearer my-secret-token',
        'X-API-KEY': '12345-abcde',
      }),
    );

    print('\nSending Request #3 (Error Case)...');
    await dio.get('https://jsonplaceholder.typicode.com/invalid-endpoint');

  } catch (e) {
    // Logged by interceptor
  }

  print('\n--- TEST DRIVE COMPLETED ---');
}
