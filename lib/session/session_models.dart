class APISessionEntry {
  final DateTime timestamp;
  final String method;
  final String endpoint;
  final int? statusCode;
  final int durationMs;
  final String? error;

  APISessionEntry({
    required this.timestamp,
    required this.method,
    required this.endpoint,
    this.statusCode,
    required this.durationMs,
    this.error,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'method': method,
      'endpoint': endpoint,
      'status': statusCode,
      'duration': durationMs,
      'error': error,
    };
  }
}

class APISession {
  final DateTime startTime;
  final List<APISessionEntry> entries = [];
  bool isRecording = false;

  APISession({required this.startTime});

  int get totalRequests => entries.length;
  int get totalErrors => entries.where((e) => e.error != null || (e.statusCode != null && e.statusCode! >= 400)).length;
  double get averageResponseTime => entries.isEmpty 
      ? 0 
      : entries.map((e) => e.durationMs).reduce((a, b) => a + b) / entries.length;
  int get slowRequests => entries.where((e) => e.durationMs > 1500).length;

  Map<String, dynamic> toJson() {
    return {
      'session_start': startTime.toIso8601String(),
      'summary': {
        'total_requests': totalRequests,
        'total_errors': totalErrors,
        'average_duration': averageResponseTime,
        'slow_requests': slowRequests,
      },
      'events': entries.map((e) => e.toJson()).toList(),
    };
  }
}
