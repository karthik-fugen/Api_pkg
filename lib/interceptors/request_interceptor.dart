import 'package:dio/dio.dart';
import '../logger/console_logger.dart';

class RequestInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final requestId = ConsoleLogger.generateRequestId();
    options.extra['requestId'] = requestId;

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
