import 'session_models.dart';

class SessionRecorder {
  static final SessionRecorder _instance = SessionRecorder._internal();
  factory SessionRecorder() => _instance;
  SessionRecorder._internal();

  APISession? _currentSession;

  APISession? get currentSession => _currentSession;
  bool get isRecording => _currentSession?.isRecording ?? false;

  void start() {
    _currentSession = APISession(startTime: DateTime.now());
    _currentSession!.isRecording = true;
  }

  void stop() {
    _currentSession?.isRecording = false;
  }

  void recordEntry(APISessionEntry entry) {
    if (isRecording) {
      _currentSession!.entries.add(entry);
    }
  }

  void clear() {
    _currentSession = null;
  }
}
