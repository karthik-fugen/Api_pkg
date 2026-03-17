import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class InspectorState extends ChangeNotifier {
  static final InspectorState _instance = InspectorState._internal();
  factory InspectorState() => _instance;
  InspectorState._internal();

  int _lastResponseTimeMs = 0;
  int _errorCount = 0;
  String _lastMethod = '';
  Offset _offset = const Offset(20, 100);
  bool _isOverlayVisible = false;

  int get lastResponseTimeMs => _lastResponseTimeMs;
  int get errorCount => _errorCount;
  String get lastMethod => _lastMethod;
  Offset get offset => _offset;
  bool get isOverlayVisible => _isOverlayVisible;

  void updateResponse({required int durationMs, required String method}) {
    _lastResponseTimeMs = durationMs;
    _lastMethod = method;
    notifyListeners();
  }

  void updateOffset(Offset newOffset) {
    _offset = newOffset;
    notifyListeners();
  }

  void setOverlayVisible(bool visible) {
    _isOverlayVisible = visible;
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
