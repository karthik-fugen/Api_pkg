import 'metrics_registry.dart';
import 'api_metrics.dart';
import '../logger/console_logger.dart';

class APIProfiler {
  static final MetricsRegistry _registry = MetricsRegistry();
  static const int _performanceThresholdMs = 1500;
  static final Map<String, DateTime> _lastWarningTime = {};
  static const Duration _warningInterval = Duration(minutes: 5);

  static void recordResponse({
    required String endpoint,
    required String method,
    required Duration duration,
    required int statusCode,
    required bool isError,
  }) {
    final bool isSlow = duration.inMilliseconds > _performanceThresholdMs;

    // 1. Update Metrics
    _registry.updateMetrics(
      endpoint: endpoint,
      duration: duration,
      isError: isError,
      isSlow: isSlow,
    );

    // 2. Add to Timeline
    _registry.addTimelineEntry(TimelineEntry(
      endpoint: endpoint,
      method: method,
      duration: duration,
      timestamp: DateTime.now(),
      statusCode: statusCode,
    ));

    // 3. Performance Warning
    final metrics = _registry.metrics[endpoint];
    if (metrics != null &&
        metrics.totalRequests >= 3 && // Wait for some data
        metrics.averageResponseTimeMs > _performanceThresholdMs) {
      _logPerformanceWarning(endpoint, metrics.averageResponseTimeMs);
    }
  }

  static void _logPerformanceWarning(String endpoint, double averageTimeMs) {
    final now = DateTime.now();
    final lastWarning = _lastWarningTime[endpoint];

    if (lastWarning == null || now.difference(lastWarning) > _warningInterval) {
      ConsoleLogger.logPerformanceWarning(
        endpoint: endpoint,
        averageTimeMs: averageTimeMs,
      );
      _lastWarningTime[endpoint] = now;
    }
  }

  static List<EndpointMetrics> getSlowestEndpoints() {
    final list = _registry.metrics.values.toList();
    list.sort((a, b) => b.averageResponseTimeMs.compareTo(a.averageResponseTimeMs));
    return list;
  }
}
