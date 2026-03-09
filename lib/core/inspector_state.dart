import 'package:flutter/foundation.dart';

class InspectorState extends ChangeNotifier {
  static final InspectorState _instance = InspectorState._internal();
  factory InspectorState() => _instance;
  InspectorState._internal();

  int _lastResponseTimeMs = 0;
  int _errorCount = 0;
  String _lastMethod = '';

  int get lastResponseTimeMs => _lastResponseTimeMs;
  int get errorCount => _errorCount;
  String get lastMethod => _lastMethod;

  void updateResponse({required int durationMs, required String method}) {
    _lastResponseTimeMs = durationMs;
    _lastMethod = method;
    notifyListeners();
  }

  void incrementError() {
    _errorCount++;
    notifyListeners();
  }

  void resetErrors() {
    _errorCount = 0;
    notifyListeners();
  }
}
