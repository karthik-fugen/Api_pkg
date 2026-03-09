import 'package:dio/dio.dart';
import '../logger/console_logger.dart';
import '../analyzers/response_analyzer.dart';
import '../schema/schema_registry.dart';
import '../schema/schema_learner.dart';
import '../schema/schema_validator.dart';
import '../core/inspector_config.dart';
import '../profiler/api_profiler.dart';
import '../session/session_recorder.dart';
import '../session/session_models.dart';

class ResponseInterceptor extends Interceptor {
  static final InspectorConfig _config = InspectorConfig();
  static final SchemaRegistry _registry = SchemaRegistry();
  static final SessionRecorder _sessionRecorder = SessionRecorder();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['startTime'] = DateTime.now();
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    final startTime = response.requestOptions.extra['startTime'] as DateTime?;
    final duration = startTime != null ? DateTime.now().difference(startTime) : Duration.zero;
    final endpoint = response.requestOptions.path;
    final requestId = response.requestOptions.extra['requestId'] as int;

    ConsoleLogger.logResponse(
      requestId: requestId,
      statusCode: response.statusCode ?? 0,
      endpoint: endpoint,
      duration: duration,
      responseSize: response.data?.toString().length ?? 0,
      headers: response.headers.map,
      responseBody: response.data,
    );

    // Record session entry if recording is active
    if (_sessionRecorder.isRecording) {
      _sessionRecorder.recordEntry(APISessionEntry(
        timestamp: DateTime.now(),
        method: response.requestOptions.method,
        endpoint: endpoint,
        statusCode: response.statusCode,
        durationMs: duration.inMilliseconds,
      ));
    }

    // Record performance metrics
    APIProfiler.recordResponse(
      endpoint: endpoint,
      method: response.requestOptions.method,
      duration: duration,
      statusCode: response.statusCode ?? 0,
      isError: (response.statusCode ?? 0) >= 400,
    );

    // Trigger Smart API Analysis (Phase 2)
    ResponseAnalyzer.analyze(
      endpoint: endpoint,
      duration: duration,
      responseData: response.data,
    );

    // Trigger Schema Learning (Phase 3)
    if (_config.enableSchemaLearning) {
      if (!_registry.hasSchema(endpoint)) {
        SchemaLearner.learn(endpoint, response.data);
      } else if (_config.enableBreakingChangeDetection) {
        final storedSchema = _registry.getSchema(endpoint);
        if (storedSchema != null) {
          SchemaValidator.validate(endpoint, storedSchema, response.data);
        }
      }
    }

    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final startTime = err.requestOptions.extra['startTime'] as DateTime?;
    final duration = startTime != null ? DateTime.now().difference(startTime) : Duration.zero;
    final requestId = err.requestOptions.extra['requestId'] as int?;

    ConsoleLogger.logError(
      endpoint: err.requestOptions.path,
      statusCode: err.response?.statusCode,
      message: '${requestId != null ? 'Request #$requestId ' : ''}${err.message ?? 'Unknown error'}',
    );

    // Record session entry on error if active
    if (_sessionRecorder.isRecording) {
      _sessionRecorder.recordEntry(APISessionEntry(
        timestamp: DateTime.now(),
        method: err.requestOptions.method,
        endpoint: err.requestOptions.path,
        statusCode: err.response?.statusCode,
        durationMs: duration.inMilliseconds,
        error: err.message,
      ));
    }

    // Record performance for errors too
    APIProfiler.recordResponse(
      endpoint: err.requestOptions.path,
      method: err.requestOptions.method,
      duration: duration,
      statusCode: err.response?.statusCode ?? 0,
      isError: true,
    );

    super.onError(err, handler);
  }
}
