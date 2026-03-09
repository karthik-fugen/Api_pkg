import 'schema_models.dart';

class SchemaRegistry {
  static final SchemaRegistry _instance = SchemaRegistry._internal();
  factory SchemaRegistry() => _instance;
  SchemaRegistry._internal();

  final Map<String, EndpointSchema> _learnedSchemas = {};

  void registerSchema(EndpointSchema schema) {
    _learnedSchemas[schema.endpoint] = schema;
  }

  EndpointSchema? getSchema(String endpoint) {
    return _learnedSchemas[endpoint];
  }

  bool hasSchema(String endpoint) {
    return _learnedSchemas.containsKey(endpoint);
  }

  void clear() {
    _learnedSchemas.clear();
  }
}
