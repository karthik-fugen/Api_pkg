class RecordedRequest {
  final int id;
  final String method;
  final String url;
  final String path;
  final Map<String, dynamic>? headers;
  final dynamic body;

  RecordedRequest({
    required this.id,
    required this.method,
    required this.url,
    required this.path,
    this.headers,
    this.body,
  });
}
