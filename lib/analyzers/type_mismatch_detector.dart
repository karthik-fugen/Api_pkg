import '../core/inspector_config.dart';
import '../logger/console_logger.dart';

class TypeMismatchDetector {
  static final InspectorConfig _config = InspectorConfig();

  static void analyze(String endpoint, dynamic responseData) {
    if (responseData is! Map<String, dynamic>) return;

    final expectedTypes = _config.schemaTypes[endpoint];
    if (expectedTypes == null) return;

    expectedTypes.forEach((field, expectedType) {
      if (responseData.containsKey(field)) {
        final value = responseData[field];
        if (value != null && value.runtimeType != expectedType) {
          ConsoleLogger.logTypeMismatch(
            endpoint: endpoint,
            field: field,
            expected: expectedType.toString(),
            received: value.runtimeType.toString(),
          );
        }
      }
    });
  }
}
