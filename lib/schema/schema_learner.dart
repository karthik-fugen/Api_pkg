import 'schema_models.dart';
import 'schema_registry.dart';
import '../logger/console_logger.dart';

class SchemaLearner {
  static final SchemaRegistry _registry = SchemaRegistry();

  static void learn(String endpoint, dynamic data) {
    if (data is Map<String, dynamic>) {
      final fieldTypes = <String, String>{};
      data.forEach((key, value) {
        fieldTypes[key] = _getTypeString(value);
      });

      final schema = EndpointSchema(
        endpoint: endpoint,
        fieldTypes: fieldTypes,
      );

      _registry.registerSchema(schema);

      ConsoleLogger.logSchemaLearned(
        endpoint: endpoint,
        fields: schema.fieldNames,
      );
    } else if (data is List<dynamic> && data.isNotEmpty) {
      // Learn from the first element if it's a map
      if (data.first is Map<String, dynamic>) {
        learn(endpoint, data.first);
      }
    }
  }

  static String _getTypeString(dynamic value) {
    if (value == null) return 'Null';
    return value.runtimeType.toString();
  }
}
