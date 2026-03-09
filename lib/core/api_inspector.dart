import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../interceptors/request_interceptor.dart';
import '../interceptors/response_interceptor.dart';
import '../ui/api_inspector_dashboard.dart';
import '../ui/api_inspector_overlay.dart';
import '../ui/log_storage.dart';
import 'inspector_config.dart';

import '../profiler/metrics_registry.dart';
import '../session/session_recorder.dart';
import '../session/session_exporter.dart';
import '../session/session_models.dart';

class APIInspector {
  static final InspectorConfig _config = InspectorConfig();
  static final LogStorage _storage = LogStorage();
  static final MetricsRegistry _metricsRegistry = MetricsRegistry();
  static final SessionRecorder _sessionRecorder = SessionRecorder();

  /// Initialize the API Inspector.
  static void initialize({bool enabled = true}) {
    _config.enabled = enabled;
  }

  /// Start recording a new API session.
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
  /// Only appears in debug mode.
  static Widget wrap(Widget app) {
    if (!kDebugMode || !_config.enabled) return app;
    return APIInspectorOverlay(child: app);
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
    if (!_config.enabled) return;

    // To ensure timing works correctly, we should add our interceptors.
    // We add them in order: RequestInterceptor, then ResponseInterceptor.
    dio.interceptors.add(RequestInterceptor());
    dio.interceptors.add(ResponseInterceptor());
  }
}
