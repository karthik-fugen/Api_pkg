import 'dart:convert';
import '../ui/log_storage.dart';
import '../core/inspector_config.dart';

class LogColors {
  static const reset = '\x1B[0m';
  static const red = '\x1B[31m';
  static const green = '\x1B[32m';
  static const yellow = '\x1B[33m';
  static const blue = '\x1B[34m';
  static const cyan = '\x1B[36m';
  static const magenta = '\x1B[35m';
  static const bold = '\x1B[1m';
}

class ConsoleLogger {
  static final LogStorage _storage = LogStorage();
  static final InspectorConfig _config = InspectorConfig();
  static int _requestIdCounter = 0;

  static int generateRequestId() => ++_requestIdCounter;

  static String _color(String color, String text) {
    if (!_config.enableColoredLogs) return text;
    return "$color$text${LogColors.reset}";
  }

  static String _bold(String text) {
    if (!_config.enableColoredLogs) return text;
    return "${LogColors.bold}$text${LogColors.reset}";
  }

  static String _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET': return LogColors.cyan;
      case 'POST': return LogColors.green;
      case 'PUT':
      case 'PATCH': return LogColors.yellow;
      case 'DELETE': return LogColors.red;
      default: return LogColors.blue;
    }
  }

  static String _getStatusColor(int code) {
    if (code >= 200 && code < 300) return LogColors.green;
    if (code >= 400 && code < 500) return LogColors.yellow;
    if (code >= 500) return LogColors.red;
    return LogColors.reset;
  }

  static String _getDurationColor(int ms) {
    if (ms < 300) return LogColors.green;
    if (ms < 1000) return LogColors.yellow;
    return LogColors.red;
  }

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
    final methodColor = _getMethodColor(method);
    
    final consoleBuffer = StringBuffer();
    final storageBuffer = StringBuffer();

    // Console Output with Colors
    consoleBuffer.writeln(_color(LogColors.blue, _bold('\n┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')));
    consoleBuffer.writeln('┃ 🚀 ${_color(LogColors.blue, _bold('API REQUEST #$requestId'))} [${_color(methodColor, _bold(method.toUpperCase()))}]');
    consoleBuffer.writeln(_color(LogColors.blue, _bold('┠━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')));
    consoleBuffer.writeln('┃ ${_color(LogColors.cyan, 'Method:   ')} $method');
    consoleBuffer.writeln('┃ ${_color(LogColors.cyan, 'URL:      ')} $fullUrl');
    consoleBuffer.writeln('┃ ${_color(LogColors.cyan, 'Endpoint: ')} $endpoint');
    consoleBuffer.writeln('┃ ${_color(LogColors.cyan, 'Time:     ')} $timestamp');

    // Storage Output (Plain text)
    storageBuffer.writeln('==============================');
    storageBuffer.writeln('API REQUEST #$requestId');
    storageBuffer.writeln('==============================');
    storageBuffer.writeln('Method: $method');
    storageBuffer.writeln('URL: $fullUrl');
    storageBuffer.writeln('Endpoint: $endpoint');
    storageBuffer.writeln('Timestamp: $timestamp');
    
    if (_config.enableDetailedLogs) {
      if (maskedHeaders != null && maskedHeaders.isNotEmpty) {
        consoleBuffer.writeln('┃');
        consoleBuffer.writeln('┃ ${_color(LogColors.magenta, _bold('Headers:'))}');
        storageBuffer.writeln('\nHeaders:');
        maskedHeaders.forEach((k, v) {
          consoleBuffer.writeln('┃   $k: $v');
          storageBuffer.writeln('$k: $v');
        });
      }

      if (queryParameters != null && queryParameters.isNotEmpty) {
        consoleBuffer.writeln('┃');
        consoleBuffer.writeln('┃ ${_color(LogColors.magenta, _bold('Query Parameters:'))}');
        storageBuffer.writeln('\nQuery Parameters:');
        queryParameters.forEach((k, v) {
          consoleBuffer.writeln('┃   $k: $v');
          storageBuffer.writeln('$k: $v');
        });
      }

      if (body != null) {
        final prettyBody = _prettyPrint(body);
        consoleBuffer.writeln('┃');
        consoleBuffer.writeln('┃ ${_color(LogColors.magenta, _bold('Request Body:'))}');
        prettyBody.split('\n').forEach((line) => consoleBuffer.writeln('┃   $line'));
        storageBuffer.writeln('\nRequest Body:');
        storageBuffer.writeln(prettyBody);
      }

      if (_config.enableCurlGeneration) {
        consoleBuffer.writeln('┃');
        consoleBuffer.writeln('┃ ${_color(LogColors.yellow, _bold('[CURL REPRODUCTION]'))}');
        consoleBuffer.writeln('┃   $curl');
        storageBuffer.writeln('\n[CURL REQUEST]');
        storageBuffer.writeln(curl);
      }
    }
    consoleBuffer.writeln(_color(LogColors.blue, '┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'));
    storageBuffer.writeln('------------------------------');

    print(consoleBuffer.toString());
    
    _storage.addLog(APILogEntry(
      type: LogType.request,
      endpoint: endpoint,
      message: storageBuffer.toString(),
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
    final statusColor = _getStatusColor(statusCode);
    final durationColor = _getDurationColor(duration.inMilliseconds);

    final consoleBuffer = StringBuffer();
    final storageBuffer = StringBuffer();

    // Console Output
    consoleBuffer.writeln(_color(LogColors.green, '┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'));
    consoleBuffer.writeln('┃ 📦 ${_color(LogColors.green, _bold('API RESPONSE #$requestId'))} [${_color(statusColor, _bold(statusCode.toString()))}]');
    consoleBuffer.writeln(_color(LogColors.green, '┠━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'));
    consoleBuffer.writeln('┃ ${_color(LogColors.yellow, 'Status:   ')} ${_color(statusColor, _bold(statusCode.toString()))}');
    consoleBuffer.writeln('┃ ${_color(LogColors.yellow, 'Time:     ')} ${_color(durationColor, '${duration.inMilliseconds}ms')}');
    consoleBuffer.writeln('┃ ${_color(LogColors.yellow, 'Size:     ')} $sizeStr');
    consoleBuffer.writeln('┃ ${_color(LogColors.yellow, 'Timestamp:')} $timestamp');

    // Storage Output
    storageBuffer.writeln('------------------------------');
    storageBuffer.writeln('API RESPONSE #$requestId');
    storageBuffer.writeln('------------------------------');
    storageBuffer.writeln('Endpoint: $endpoint');
    storageBuffer.writeln('Status: $statusCode');
    storageBuffer.writeln('Response Time: ${duration.inMilliseconds}ms');
    storageBuffer.writeln('Response Size: $sizeStr');
    storageBuffer.writeln('Timestamp: $timestamp');

    if (_config.enableDetailedLogs) {
      if (responseBody != null) {
        final prettyBody = _prettyPrint(responseBody);
        consoleBuffer.writeln('┃');
        consoleBuffer.writeln('┃ ${_color(LogColors.magenta, _bold('Response Body:'))}');
        prettyBody.split('\n').forEach((line) => consoleBuffer.writeln('┃   $line'));
        storageBuffer.writeln('\nResponse Body:');
        storageBuffer.writeln(prettyBody);
      }
    }
    consoleBuffer.writeln(_color(LogColors.green, _bold('┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n')));
    storageBuffer.writeln('==============================\n');

    print(consoleBuffer.toString());

    _storage.addLog(APILogEntry(
      type: LogType.response,
      endpoint: endpoint,
      message: storageBuffer.toString(),
      timestamp: DateTime.now(),
      metadata: {
        'requestId': requestId,
        'statusCode': statusCode,
        'durationMs': duration.inMilliseconds,
        'size': sizeStr,
        'headers': maskedHeaders,
        'responseBody': responseBody,
      },
    ));
  }

  static void logError({
    required String endpoint,
    required int? statusCode,
    required String message,
  }) {
    print('\n${_color(LogColors.red, _bold('❌ API ERROR'))}');
    print('${_color(LogColors.red, 'Endpoint:')} $endpoint');
    print('${_color(LogColors.red, 'Status:')} ${statusCode ?? 'Unknown'}');
    print('${_color(LogColors.red, 'Message:')} $message\n');

    final logMessage = '\n[API ERROR]\nEndpoint: $endpoint\nStatus: ${statusCode ?? 'Unknown'}\nMessage: $message\n';

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
    print('🐢 ${_color(LogColors.yellow, _bold('[SLOW API WARNING]'))}');
    print('${_color(LogColors.yellow, 'Endpoint:')} $endpoint');
    print('${_color(LogColors.yellow, 'Response Time:')} ${duration.inMilliseconds}ms\n');

    final message = '\n[SLOW API WARNING]\nEndpoint: $endpoint\nResponse Time: ${duration.inMilliseconds}ms\n';

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
    print('⚠️  ${_color(LogColors.yellow, _bold('[INVALID RESPONSE FORMAT]'))}');
    print('${_color(LogColors.yellow, 'Endpoint:')} $endpoint');
    print('${_color(LogColors.yellow, 'Expected:')} $expected');
    print('${_color(LogColors.yellow, 'Received:')} $received\n');

    final message = '\n[INVALID RESPONSE FORMAT]\nEndpoint: $endpoint\nExpected: $expected\nReceived: $received\n';

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
    print('👻 ${_color(LogColors.yellow, _bold('[NULL VALUE WARNING]'))}');
    print('${_color(LogColors.yellow, 'Field:')} $field');
    print('${_color(LogColors.yellow, 'Endpoint:')} $endpoint\n');

    final message = '\n[NULL VALUE WARNING]\nField: $field\nEndpoint: $endpoint\n';

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
    print('🔍 ${_color(LogColors.yellow, _bold('[MISSING FIELD WARNING]'))}');
    print('${_color(LogColors.yellow, 'Endpoint:')} $endpoint');
    print('${_color(LogColors.yellow, 'Missing Field:')} $field\n');

    final message = '\n[MISSING FIELD WARNING]\nEndpoint: $endpoint\nMissing Field: $field\n';

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
    print('🚫 ${_color(LogColors.red, _bold('[TYPE MISMATCH DETECTED]'))}');
    print('${_color(LogColors.red, 'Endpoint:')} $endpoint');
    print('${_color(LogColors.red, 'Field:')} $field');
    print('${_color(LogColors.red, 'Expected:')} $expected');
    print('${_color(LogColors.red, 'Received:')} $received\n');

    final message = '\n[TYPE MISMATCH DETECTED]\nEndpoint: $endpoint\nField: $field\nExpected: $expected\nReceived: $received\n';

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
    print('🧠 ${_color(LogColors.magenta, _bold('[SCHEMA LEARNED]'))}');
    print('${_color(LogColors.magenta, 'Endpoint:')} $endpoint');
    print('${_color(LogColors.magenta, 'Fields:')} ${fields.join(', ')}\n');

    final message = '\n[SCHEMA LEARNED]\nEndpoint: $endpoint\nFields: ${fields.join(', ')}\n';

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
    print('✨ ${_color(LogColors.magenta, _bold('[NEW FIELD DETECTED]'))}');
    print('${_color(LogColors.magenta, 'Endpoint:')} $endpoint');
    print('${_color(LogColors.magenta, 'Field:')} $field');
    print('${_color(LogColors.magenta, 'Type:')} $type\n');

    final message = '\n[NEW FIELD DETECTED]\nEndpoint: $endpoint\nField: $field\nType: $type\n';

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
    print('🗑️  ${_color(LogColors.magenta, _bold('[SCHEMA CHANGE WARNING]'))}');
    print('${_color(LogColors.magenta, 'Endpoint:')} $endpoint');
    print('${_color(LogColors.magenta, 'Removed Field:')} $field\n');

    final message = '\n[SCHEMA CHANGE WARNING]\nEndpoint: $endpoint\nRemoved Field: $field\n';

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
    print('💥 ${_color(LogColors.red, _bold('[API BREAKING CHANGE DETECTED]'))}');
    print('${_color(LogColors.red, 'Endpoint:')} $endpoint');
    print('${_color(LogColors.red, 'Field:')} $field');
    print('${_color(LogColors.red, 'Previous Type:')} $previousType');
    print('${_color(LogColors.red, 'New Type:')} $newType\n');

    final message = '\n[API BREAKING CHANGE DETECTED]\nEndpoint: $endpoint\nField: $field\nPrevious Type: $previousType\nNew Type: $newType\n';

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
    print('⚡ ${_color(LogColors.red, _bold('[PERFORMANCE WARNING]'))}');
    print('${_color(LogColors.red, 'Endpoint:')} $endpoint');
    print('${_color(LogColors.red, 'Average Response Time:')} ${averageTimeMs.toStringAsFixed(1)}ms\n');

    final message = '\n[PERFORMANCE WARNING]\nEndpoint: $endpoint\nAverage Response Time: ${averageTimeMs.toStringAsFixed(1)}ms\n';

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

  static String _formatTimestamp(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}";
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
}
