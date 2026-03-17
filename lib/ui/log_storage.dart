import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

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

  Map<String, dynamic> toJson() => {
    'type': type.index,
    'endpoint': endpoint,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'metadata': metadata,
  };

  factory APILogEntry.fromJson(Map<String, dynamic> json) => APILogEntry(
    type: LogType.values[json['type']],
    endpoint: json['endpoint'],
    message: json['message'],
    timestamp: DateTime.parse(json['timestamp']),
    metadata: json['metadata'],
  );
}

class LogStorage extends ChangeNotifier {
  static final LogStorage _instance = LogStorage._internal();
  factory LogStorage() => _instance;
  LogStorage._internal() {
    _loadFromDisk();
  }

  final List<APILogEntry> _logs = [];
  static const int _maxLogs = 500;

  List<APILogEntry> get logs => UnmodifiableListView(_logs);

  Future<void> addLog(APILogEntry entry) async {
    if (_logs.length >= _maxLogs) {
      _logs.removeAt(0);
    }
    _logs.add(entry);
    notifyListeners();
    await _saveToDisk();
  }

  Future<void> clear() async {
    _logs.clear();
    notifyListeners();
    await _saveToDisk();
  }

  Future<String> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/api_inspector_logs.json';
  }

  Future<void> _saveToDisk() async {
    try {
      final file = File(await _getFilePath());
      final jsonString = jsonEncode(_logs.map((e) => e.toJson()).toList());
      await file.writeAsString(jsonString);
    } catch (e) {
      debugPrint('APIInspector Storage Error: $e');
    }
  }

  Future<void> _loadFromDisk() async {
    try {
      final file = File(await _getFilePath());
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _logs.clear();
        _logs.addAll(jsonList.map((j) => APILogEntry.fromJson(j)));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('APIInspector Load Error: $e');
    }
  }
}
