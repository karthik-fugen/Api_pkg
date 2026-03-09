import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_api_inspector/profiler/api_profiler.dart';
import 'package:flutter_api_inspector/profiler/metrics_registry.dart';

void main() {
  final registry = MetricsRegistry();

  setUp(() {
    registry.clear();
  });

  test('APIProfiler should record metrics correctly', () {
    final endpoint = '/users';
    
    APIProfiler.recordResponse(
      endpoint: endpoint,
      method: 'GET',
      duration: const Duration(milliseconds: 100),
      statusCode: 200,
      isError: false,
    );

    APIProfiler.recordResponse(
      endpoint: endpoint,
      method: 'GET',
      duration: const Duration(milliseconds: 200),
      statusCode: 200,
      isError: false,
    );

    final metrics = registry.metrics[endpoint]!;
    expect(metrics.totalRequests, 2);
    expect(metrics.averageResponseTimeMs, 150);
  });

  test('APIProfiler should rank slowest endpoints', () {
    APIProfiler.recordResponse(
      endpoint: '/fast',
      method: 'GET',
      duration: const Duration(milliseconds: 50),
      statusCode: 200,
      isError: false,
    );

    APIProfiler.recordResponse(
      endpoint: '/slow',
      method: 'GET',
      duration: const Duration(milliseconds: 2000),
      statusCode: 200,
      isError: false,
    );

    final slowest = APIProfiler.getSlowestEndpoints();
    expect(slowest.first.endpoint, '/slow');
    expect(slowest.last.endpoint, '/fast');
  });
}
