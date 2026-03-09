import '../logger/console_logger.dart';
import 'slow_api_detector.dart';
import 'missing_field_detector.dart';
import 'type_mismatch_detector.dart';

class ResponseAnalyzer {
  static void analyze({
    required String endpoint,
    required Duration duration,
    required dynamic responseData,
  }) {
    // 1. Slow API Detection
    SlowApiDetector.analyze(endpoint, duration);

    // 2. Invalid JSON Detection
    if (responseData != null &&
        responseData is! Map<String, dynamic> &&
        responseData is! List<dynamic>) {
      ConsoleLogger.logInvalidResponse(
        endpoint: endpoint,
        expected: 'JSON (Map or List)',
        received: responseData.runtimeType.toString(),
      );
      return; // Stop further analysis if not JSON
    }

    // 3. Null Value Detection (if it's a Map)
    if (responseData is Map<String, dynamic>) {
      responseData.forEach((key, value) {
        if (value == null) {
          ConsoleLogger.logNullValue(
            field: key,
            endpoint: endpoint,
          );
        }
      });

      // 4. Missing Field Detection
      MissingFieldDetector.analyze(endpoint, responseData);

      // 5. Type Mismatch Detection
      TypeMismatchDetector.analyze(endpoint, responseData);
    } else if (responseData is List<dynamic>) {
       // Optional: could analyze elements if they are maps
       for (var element in responseData) {
         if (element is Map<String, dynamic>) {
            _analyzeMap(endpoint, element);
         }
       }
    }
  }

  static void _analyzeMap(String endpoint, Map<String, dynamic> data) {
      data.forEach((key, value) {
        if (value == null) {
          ConsoleLogger.logNullValue(
            field: key,
            endpoint: endpoint,
          );
        }
      });
      MissingFieldDetector.analyze(endpoint, data);
      TypeMismatchDetector.analyze(endpoint, data);
  }
}
