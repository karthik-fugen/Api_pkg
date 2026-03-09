import 'package:dio/dio.dart';
import '../logger/console_logger.dart';
import '../core/inspector_config.dart';
import '../core/recorded_request.dart';

class RequestInterceptor extends Interceptor {
  static final InspectorConfig _config = InspectorConfig();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 1. Check for Mock Response
    if (_config.mockResponses.containsKey(options.path)) {
      final mockData = _config.mockResponses[options.path];
      ConsoleLogger.logMockUsage(options.path);
      return handler.resolve(
        Response(
          requestOptions: options,
          data: mockData,
          statusCode: 200,
        ),
      );
    }

    // 2. Generate Request ID
    final requestId = ConsoleLogger.generateRequestId();
    options.extra['requestId'] = requestId;

    // 3. Record Request for Replay
    _config.recordedRequests[requestId] = RecordedRequest(
      id: requestId,
      method: options.method,
      url: options.uri.toString(),
      path: options.path,
      headers: options.headers,
      body: options.data,
    );

    // 4. Log Detailed Request
    ConsoleLogger.logRequest(
      requestId: requestId,
      method: options.method,
      endpoint: options.path,
      fullUrl: options.uri.toString(),
      headers: options.headers,
      queryParameters: options.queryParameters,
      body: options.data,
    );
    super.onRequest(options, handler);
  }
}
