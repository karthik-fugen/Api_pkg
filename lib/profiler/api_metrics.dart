class EndpointMetrics {
  final String endpoint;
  int totalRequests = 0;
  int totalErrors = 0;
  int slowRequests = 0;
  Duration lastResponseTime = Duration.zero;
  Duration totalResponseTime = Duration.zero;

  EndpointMetrics({required this.endpoint});

  double get averageResponseTimeMs =>
      totalRequests == 0 ? 0 : totalResponseTime.inMilliseconds / totalRequests;

  void update({
    required Duration duration,
    required bool isError,
    required bool isSlow,
  }) {
    totalRequests++;
    lastResponseTime = duration;
    totalResponseTime += duration;
    if (isError) totalErrors++;
    if (isSlow) slowRequests++;
  }
}

class TimelineEntry {
  final String endpoint;
  final String method;
  final Duration duration;
  final DateTime timestamp;
  final int statusCode;

  TimelineEntry({
    required this.endpoint,
    required this.method,
    required this.duration,
    required this.timestamp,
    required this.statusCode,
  });
}
