import 'dart:collection';

enum LogType {
  request,
  response,
  error,
  warning,
  schemaChange,
  performance,
}

class APILogEntry {
  final LogType type;
  final String endpoint;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  APILogEntry({
    required this.type,
    required this.endpoint,
    required this.message,
    required this.timestamp,
    this.metadata,
  });
}

class LogStorage {
  static final LogStorage _instance = LogStorage._internal();
  factory LogStorage() => _instance;
  LogStorage._internal();

  final List<APILogEntry> _logs = [];
  static const int _maxLogs = 200;

  List<APILogEntry> get logs => UnmodifiableListView(_logs);

  void addLog(APILogEntry entry) {
    if (_logs.length >= _maxLogs) {
      _logs.removeAt(0);
    }
    _logs.add(entry);
  }

  void clear() {
    _logs.clear();
  }
}
