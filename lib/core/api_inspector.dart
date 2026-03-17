import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../interceptors/request_interceptor.dart';
import '../interceptors/response_interceptor.dart';
import '../ui/api_inspector_dashboard.dart';
import '../ui/api_inspector_overlay.dart';
import '../ui/log_storage.dart';
import 'inspector_config.dart';
import 'inspector_state.dart';

import '../logger/console_logger.dart';
import '../profiler/metrics_registry.dart';
import '../session/session_recorder.dart';
import '../session/session_exporter.dart';
import '../session/session_models.dart';

class APIInspector {
  static final InspectorConfig _config = InspectorConfig();
  static final LogStorage _storage = LogStorage();
  static final MetricsRegistry _metricsRegistry = MetricsRegistry();
  static final SessionRecorder _sessionRecorder = SessionRecorder();
  static final InspectorState _state = InspectorState();

  /// Global key to access the navigator from anywhere.
  /// Pass this to your MaterialApp's navigatorKey property.
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// The last attached Dio instance, used for replaying requests.
  static Dio? _dio;

  /// Initialize the API Inspector.
  static void initialize({
    bool enabled = true,
    bool showInRelease = false,
  }) {
    _config.enabled = enabled;
    _config.showInRelease = showInRelease;
  }

  /// Replay a recorded request by its ID.
  static Future<Response?> replayRequest(int id) async {
    final req = _config.recordedRequests[id];
    if (req == null || _dio == null) {
      print('❌ Cannot replay request: Request not found or Dio instance not attached.');
      return null;
    }

    ConsoleLogger.logReplay(id, req.method, req.url);

    return _dio!.request(
      req.url,
      data: req.body,
      options: Options(
        method: req.method,
        headers: req.headers,
      ),
    );
  }

  /// Register a mock response for an endpoint.
  static void mockResponse(String endpoint, dynamic response) {
    _config.mockResponses[endpoint] = response;
  }

  /// Clear all registered mock responses.
  static void clearMocks() {
    _config.mockResponses.clear();
  }

  /// Wrap your app with the API Inspector overlay.

  static void startSessionRecording() {
    _sessionRecorder.start();
  }

  /// Stop the current API session recording.
  static void stopSessionRecording() {
    _sessionRecorder.stop();
  }

  /// Get the current session entries.
  static List<APISessionEntry> getSessionEntries() {
    return _sessionRecorder.currentSession?.entries ?? [];
  }

  /// Export the current session as a JSON string.
  static String exportSession() {
    final session = _sessionRecorder.currentSession;
    if (session == null) return '{}';
    return SessionExporter.exportToJson(session);
  }

  /// Get a summary of the current session.
  static Map<String, dynamic> getSessionSummary() {
    return _sessionRecorder.currentSession?.toJson()['summary'] ?? {};
  }

  /// Reset all stored performance metrics.
  static void resetMetrics() {
    _metricsRegistry.clear();
  }

  /// Wrap your app with the API Inspector overlay.
  /// Appears in debug mode, or in release if showInRelease is true.
  /// Best used in MaterialApp.builder.
  static Widget wrap(Widget child) {
    final shouldShow = _config.enabled && (kDebugMode || _config.showInRelease);
    if (!shouldShow) return child;
    return APIInspectorOverlay(child: child);
  }

  /// Manually show the API Inspector dashboard.
  static void showInspector(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const APILogDashboard()),
    );
  }

  /// Clear all stored logs.
  static void clearLogs() {
    _storage.clear();
  }

  /// Manually log a response (useful for http package users).
  static void logManualResponse({
    required String method,
    required String endpoint,
    required int statusCode,
    required Duration duration,
    dynamic responseBody,
    Map<String, dynamic>? headers,
  }) {
    if (!_config.enabled) return;
    
    final requestId = ConsoleLogger.generateRequestId();
    
    // Log to console
    ConsoleLogger.logResponse(
      requestId: requestId,
      statusCode: statusCode,
      endpoint: endpoint,
      duration: duration,
      responseSize: responseBody?.toString().length ?? 0,
      headers: headers,
      responseBody: responseBody,
    );

    // Update state for overlay
    _state.updateResponse(
      durationMs: duration.inMilliseconds,
      method: method,
    );
    
    if (statusCode >= 400) {
      _state.incrementError();
    }
  }

  /// Manually log an error (useful for http package users).
  static void logManualError({
    required String endpoint,
    required String message,
    int? statusCode,
  }) {
    if (!_config.enabled) return;
    
    ConsoleLogger.logError(
      endpoint: endpoint,
      statusCode: statusCode,
      message: message,
    );
    
    _state.incrementError();
  }

  /// Register an expected response schema for an endpoint.
  static void registerSchema(String endpoint, List<String> fields) {
    _config.schemas[endpoint] = fields;
  }

  /// Register expected field types for an endpoint.
  static void registerSchemaTypes(String endpoint, Map<String, Type> fieldTypes) {
    _config.schemaTypes[endpoint] = fieldTypes;
  }

  /// Attach the API Inspector interceptors to a Dio client.
  static void attach(Dio dio) {
    _dio = dio; // Store for replay
    if (!_config.enabled) return;

    // To ensure timing works correctly, we should add our interceptors.
    // We add them in order: RequestInterceptor, then ResponseInterceptor.
    dio.interceptors.add(RequestInterceptor());
    dio.interceptors.add(ResponseInterceptor());
  }
}
