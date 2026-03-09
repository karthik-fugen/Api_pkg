import '../logger/console_logger.dart';

class SlowApiDetector {
  static const int _slowThresholdMs = 1500;

  static void analyze(String endpoint, Duration duration) {
    if (duration.inMilliseconds > _slowThresholdMs) {
      ConsoleLogger.logSlowApi(
        endpoint: endpoint,
        duration: duration,
      );
    }
  }
}
