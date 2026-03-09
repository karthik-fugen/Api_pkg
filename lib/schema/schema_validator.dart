import 'schema_models.dart';
import '../logger/console_logger.dart';

class SchemaValidator {
  static void validate(String endpoint, EndpointSchema storedSchema, dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      _validateMap(endpoint, storedSchema, responseData);
    } else if (responseData is List<dynamic> && responseData.isNotEmpty) {
      if (responseData.first is Map<String, dynamic>) {
        _validateMap(endpoint, storedSchema, responseData.first);
      }
    }
  }

  static void _validateMap(String endpoint, EndpointSchema storedSchema, Map<String, dynamic> data) {
    final currentFieldTypes = data.map((key, value) => MapEntry(key, value.runtimeType.toString()));

    // 1. Detect New Fields
    currentFieldTypes.forEach((field, type) {
      if (!storedSchema.fieldTypes.containsKey(field)) {
        ConsoleLogger.logNewFieldDetected(
          endpoint: endpoint,
          field: field,
          type: type,
        );
      }
    });

    // 2. Detect Removed Fields
    storedSchema.fieldTypes.forEach((field, type) {
      if (!currentFieldTypes.containsKey(field)) {
        ConsoleLogger.logFieldRemoved(
          endpoint: endpoint,
          field: field,
        );
      }
    });

    // 3. Detect Type Changes (Breaking Changes)
    currentFieldTypes.forEach((field, currentType) {
      if (storedSchema.fieldTypes.containsKey(field)) {
        final previousType = storedSchema.fieldTypes[field];
        // If previous was Null, we might want to update or ignore.
        // For now, if types differ and weren't Null, it's a breaking change.
        if (previousType != 'Null' && currentType != 'Null' && previousType != currentType) {
          ConsoleLogger.logBreakingChange(
            endpoint: endpoint,
            field: field,
            previousType: previousType!,
            newType: currentType,
          );
        }
      }
    });
  }
}
