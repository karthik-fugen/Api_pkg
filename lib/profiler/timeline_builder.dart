import 'api_metrics.dart';

class TimelineBuilder {
  static String buildLog(TimelineEntry entry) {
    final timestamp =
        "${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}:${entry.timestamp.second.toString().padLeft(2, '0')}";
    return "[$timestamp] ${entry.method} ${entry.endpoint} → ${entry.duration.inMilliseconds}ms (${entry.statusCode})";
  }
}
