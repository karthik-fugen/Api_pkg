import 'dart:convert';
import 'dart:developer' as developer;
import '../ui/log_storage.dart';
import '../core/inspector_config.dart';

class ConsoleLogger {
  static final LogStorage _storage = LogStorage();
  static final InspectorConfig _config = InspectorConfig();
  static int _requestIdCounter = 0;

  static int generateRequestId() => ++_requestIdCounter;

  static void logRequest({
    required int requestId,
    required String method,
    required String endpoint,
    required String fullUrl,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    dynamic body,
  }) {
    final timestamp = _formatTimestamp(DateTime.now());
    final maskedHeaders = _maskHeaders(headers);
    final curl = _config.enableCurlGeneration ? _generateCurl(method, fullUrl, maskedHeaders, body) : '';
    
    final buffer = StringBuffer();
    buffer.writeln('==============================');
    buffer.writeln('API REQUEST #$requestId');
    buffer.writeln('==============================');
    buffer.writeln('Method: $method');
    buffer.writeln('URL: $fullUrl');
    buffer.writeln('Endpoint: $endpoint');
    buffer.writeln('Timestamp: $timestamp');
    
    if (_config.enableDetailedLogs) {
      if (maskedHeaders != null && maskedHeaders.isNotEmpty) {
        buffer.writeln('\nHeaders:');
        maskedHeaders.forEach((k, v) => buffer.writeln('$k: $v'));
      }

      if (queryParameters != null && queryParameters.isNotEmpty) {
        buffer.writeln('\nQuery Parameters:');
        queryParameters.forEach((k, v) => buffer.writeln('$k: $v'));
      }

      if (body != null) {
        buffer.writeln('\nRequest Body:');
        buffer.writeln(_prettyPrint(body));
      }

      if (_config.enableCurlGeneration) {
        buffer.writeln('\n[CURL REQUEST]');
        buffer.writeln(curl);
      }
    }
    buffer.writeln('------------------------------');

    final message = buffer.toString();
    developer.log(message, name: 'API_INSPECTOR');
    
    _storage.addLog(APILogEntry(
      type: LogType.request,
      endpoint: endpoint,
      message: message,
      timestamp: DateTime.now(),
      metadata: {
        'requestId': requestId,
        'method': method,
        'fullUrl': fullUrl,
        'headers': maskedHeaders,
        'body': body,
        'curl': curl,
      },
    ));
  }

  static void logResponse({
    required int requestId,
    required int statusCode,
    required String endpoint,
    required Duration duration,
    required int responseSize,
    Map<String, dynamic>? headers,
    dynamic responseBody,
  }) {
    final timestamp = _formatTimestamp(DateTime.now());
    final sizeStr = _formatBytes(responseSize);
    final maskedHeaders = _maskHeaders(headers);

    final buffer = StringBuffer();
    buffer.writeln('------------------------------');
    buffer.writeln('API RESPONSE #$requestId');
    buffer.writeln('------------------------------');
    buffer.writeln('Endpoint: $endpoint');
    buffer.writeln('Status: $statusCode');
    buffer.writeln('Response Time: ${duration.inMilliseconds}ms');
    buffer.writeln('Response Size: $sizeStr');
    buffer.writeln('Timestamp: $timestamp');

    if (_config.enableDetailedLogs) {
      if (maskedHeaders != null && maskedHeaders.isNotEmpty) {
        buffer.writeln('\nHeaders:');
        maskedHeaders.forEach((k, v) => buffer.writeln('$k: $v'));
      }

      if (responseBody != null) {
        buffer.writeln('\nResponse Body:');
        buffer.writeln(_prettyPrint(responseBody));
      }
    }
    buffer.writeln('==============================\n');

    final message = buffer.toString();
    developer.log(message, name: 'API_INSPECTOR');

    _storage.addLog(APILogEntry(
      type: LogType.response,
      endpoint: endpoint,
      message: message,
      timestamp: DateTime.now(),
      metadata: {
        'requestId': requestId,
        'statusCode': statusCode,
        'durationMs': duration.inMilliseconds,
        'responseSize': responseSize,
        'headers': maskedHeaders,
        'responseBody': responseBody,
      },
    ));
  }

  static String _prettyPrint(dynamic data) {
    if (!_config.enablePrettyResponse) return data.toString();
    try {
      const encoder = JsonEncoder.withIndent('  ');
      final jsonStr = encoder.convert(data);
      if (jsonStr.length > 10240) { // 10KB
        return '${jsonStr.substring(0, 10240)}\n... truncated response ...';
      }
      return jsonStr;
    } catch (_) {
      return data.toString();
    }
  }

  static Map<String, dynamic>? _maskHeaders(Map<String, dynamic>? headers) {
    if (headers == null || !_config.maskSensitiveData) return headers;
    final masked = Map<String, dynamic>.from(headers);
    final sensitiveKeys = ['authorization', 'token', 'password', 'api-key', 'apikey', 'x-api-key'];
    masked.forEach((key, value) {
      if (sensitiveKeys.contains(key.toLowerCase())) {
        if (value is String && value.isNotEmpty) {
          final parts = value.split(' ');
          if (parts.length > 1) {
            masked[key] = '${parts[0]} *****';
          } else {
            masked[key] = '*****';
          }
        } else {
          masked[key] = '*****';
        }
      }
    });
    return masked;
  }

  static String _generateCurl(String method, String url, Map<String, dynamic>? headers, dynamic body) {
    final buffer = StringBuffer();
    buffer.write('curl -X $method "$url"');
    headers?.forEach((k, v) => buffer.write(' -H "$k: $v"'));
    if (body != null) {
      try {
        final bodyStr = jsonEncode(body);
        buffer.write(" -d '$bodyStr'");
      } catch (_) {
        buffer.write(" -d '${body.toString()}'");
      }
    }
    return buffer.toString();
  }

  static String _formatTimestamp(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}";
  }

  static void logError({
    required String endpoint,
    required int? statusCode,
    required String message,
  }) {
    final logMessage = '\n[API ERROR]\nEndpoint: $endpoint\nStatus: ${statusCode ?? 'Unknown'}\nMessage: $message\n';
    developer.log(logMessage, name: 'API_INSPECTOR');

    _storage.addLog(APILogEntry(
      type: LogType.error,
      endpoint: endpoint,
      message: logMessage,
      timestamp: DateTime.now(),
      metadata: {'statusCode': statusCode, 'errorMessage': message},
    ));
  }

  static void logSlowApi({
    required String endpoint,
    required Duration duration,
  }) {
    final message = '\n[SLOW API WARNING]\nEndpoint: $endpoint\nResponse Time: ${duration.inMilliseconds}ms\n';
    developer.log(message, name: 'API_INSPECTOR');

    _storage.addLog(APILogEntry(
      type: LogType.warning,
      endpoint: endpoint,
      message: message,
      timestamp: DateTime.now(),
      metadata: {'warningType': 'SLOW_API', 'durationMs': duration.inMilliseconds},
    ));
  }

  static void logInvalidResponse({
    required String endpoint,
    required String expected,
    required String received,
  }) {
    final message = '\n[INVALID RESPONSE FORMAT]\nEndpoint: $endpoint\nExpected: $expected\nReceived: $received\n';
    developer.log(message, name: 'API_INSPECTOR');

    _storage.addLog(APILogEntry(
      type: LogType.warning,
      endpoint: endpoint,
      message: message,
      timestamp: DateTime.now(),
      metadata: {'warningType': 'INVALID_RESPONSE', 'expected': expected, 'received': received},
    ));
  }

  static void logNullValue({
    required String field,
    required String endpoint,
  }) {
    final message = '\n[NULL VALUE WARNING]\nField: $field\nEndpoint: $endpoint\n';
    developer.log(message, name: 'API_INSPECTOR');

    _storage.addLog(APILogEntry(
      type: LogType.warning,
      endpoint: endpoint,
      message: message,
      timestamp: DateTime.now(),
      metadata: {'warningType': 'NULL_VALUE', 'field': field},
    ));
  }

  static void logMissingField({
    required String field,
    required String endpoint,
  }) {
    final message = '\n[MISSING FIELD WARNING]\nEndpoint: $endpoint\nMissing Field: $field\n';
    developer.log(message, name: 'API_INSPECTOR');

    _storage.addLog(APILogEntry(
      type: LogType.warning,
      endpoint: endpoint,
      message: message,
      timestamp: DateTime.now(),
      metadata: {'warningType': 'MISSING_FIELD', 'field': field},
    ));
  }

  static void logTypeMismatch({
    required String endpoint,
    required String field,
    required String expected,
    required String received,
  }) {
    final message = '\n[TYPE MISMATCH DETECTED]\nEndpoint: $endpoint\nField: $field\nExpected: $expected\nReceived: $received\n';
    developer.log(message, name: 'API_INSPECTOR');

    _storage.addLog(APILogEntry(
      type: LogType.warning,
      endpoint: endpoint,
      message: message,
      timestamp: DateTime.now(),
      metadata: {
        'warningType': 'TYPE_MISMATCH',
        'field': field,
        'expected': expected,
        'received': received,
      },
    ));
  }

  static void logSchemaLearned({
    required String endpoint,
    required List<String> fields,
  }) {
    final message = '\n[SCHEMA LEARNED]\nEndpoint: $endpoint\nFields: ${fields.join(', ')}\n';
    developer.log(message, name: 'API_INSPECTOR');

    _storage.addLog(APILogEntry(
      type: LogType.schemaChange,
      endpoint: endpoint,
      message: message,
      timestamp: DateTime.now(),
      metadata: {'changeType': 'SCHEMA_LEARNED', 'fields': fields},
    ));
  }

  static void logNewFieldDetected({
    required String endpoint,
    required String field,
    required String type,
  }) {
    final message = '\n[NEW FIELD DETECTED]\nEndpoint: $endpoint\nField: $field\nType: $type\n';
    developer.log(message, name: 'API_INSPECTOR');

    _storage.addLog(APILogEntry(
      type: LogType.schemaChange,
      endpoint: endpoint,
      message: message,
      timestamp: DateTime.now(),
      metadata: {'changeType': 'NEW_FIELD', 'field': field, 'fieldType': type},
    ));
  }

  static void logFieldRemoved({
    required String endpoint,
    required String field,
  }) {
    final message = '\n[SCHEMA CHANGE WARNING]\nEndpoint: $endpoint\nRemoved Field: $field\n';
    developer.log(message, name: 'API_INSPECTOR');

    _storage.addLog(APILogEntry(
      type: LogType.schemaChange,
      endpoint: endpoint,
      message: message,
      timestamp: DateTime.now(),
      metadata: {'changeType': 'FIELD_REMOVED', 'field': field},
    ));
  }

  static void logBreakingChange({
    required String endpoint,
    required String field,
    required String previousType,
    required String newType,
  }) {
    final message = '\n[API BREAKING CHANGE DETECTED]\nEndpoint: $endpoint\nField: $field\nPrevious Type: $previousType\nNew Type: $newType\n';
    developer.log(message, name: 'API_INSPECTOR');

    _storage.addLog(APILogEntry(
      type: LogType.schemaChange,
      endpoint: endpoint,
      message: message,
      timestamp: DateTime.now(),
      metadata: {
        'changeType': 'BREAKING_CHANGE',
        'field': field,
        'previousType': previousType,
        'newType': newType,
      },
    ));
  }

  static void logPerformanceWarning({
    required String endpoint,
    required double averageTimeMs,
  }) {
    final message = '\n[PERFORMANCE WARNING]\nEndpoint: $endpoint\nAverage Response Time: ${averageTimeMs.toStringAsFixed(1)}ms\n';
    developer.log(message, name: 'API_INSPECTOR');

    _storage.addLog(APILogEntry(
      type: LogType.performance,
      endpoint: endpoint,
      message: message,
      timestamp: DateTime.now(),
      metadata: {'averageTimeMs': averageTimeMs},
    ));
  }

  static String _formatBytes(int bytes) {

    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    double val = bytes.toDouble();
    int idx = 0;
    while (val >= 1024 && idx < suffixes.length - 1) {
      val /= 1024;
      idx++;
    }
    return "${val.toStringAsFixed(1)} ${suffixes[idx]}";
  }
}
