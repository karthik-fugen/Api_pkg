class InspectorConfig {
  static final InspectorConfig _instance = InspectorConfig._internal();
  factory InspectorConfig() => _instance;
  InspectorConfig._internal();

  bool enabled = true;

  /// Whether to automatically learn API schemas.
  bool enableSchemaLearning = true;

  /// Whether to detect and log breaking changes in API schemas.
  bool enableBreakingChangeDetection = true;

  /// Whether to enable detailed logs.
  bool enableDetailedLogs = true;

  /// Whether to generate CURL commands for requests.
  bool enableCurlGeneration = true;

  /// Whether to pretty print JSON responses.
  bool enablePrettyResponse = true;

  /// Whether to mask sensitive data (headers like Authorization).
  bool maskSensitiveData = true;

  /// Map of endpoint to list of expected fields.
  final Map<String, List<String>> schemas = {};

  /// Map of endpoint to map of field names and their expected types.
  final Map<String, Map<String, Type>> schemaTypes = {};
}
