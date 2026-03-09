class EndpointSchema {
  final String endpoint;
  final Map<String, String> fieldTypes;

  EndpointSchema({
    required this.endpoint,
    required this.fieldTypes,
  });

  List<String> get fieldNames => fieldTypes.keys.toList();
}
