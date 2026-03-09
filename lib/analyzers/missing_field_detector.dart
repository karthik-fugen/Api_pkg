import '../core/inspector_config.dart';
import '../logger/console_logger.dart';

class MissingFieldDetector {
  static final InspectorConfig _config = InspectorConfig();

  static void analyze(String endpoint, dynamic responseData) {
    if (responseData is! Map<String, dynamic>) return;

    final expectedFields = _config.schemas[endpoint];
    if (expectedFields == null) return;

    for (final field in expectedFields) {
      if (!responseData.containsKey(field)) {
        ConsoleLogger.logMissingField(
          field: field,
          endpoint: endpoint,
        );
      }
    }
  }
}
