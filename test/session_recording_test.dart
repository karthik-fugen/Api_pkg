import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_api_inspector/session/session_recorder.dart';
import 'package:flutter_api_inspector/session/session_models.dart';
import 'package:flutter_api_inspector/session/session_exporter.dart';

void main() {
  final recorder = SessionRecorder();

  setUp(() {
    recorder.clear();
  });

  test('SessionRecorder should record entries when active', () {
    recorder.start();
    expect(recorder.isRecording, true);

    recorder.recordEntry(APISessionEntry(
      timestamp: DateTime.now(),
      method: 'GET',
      endpoint: '/users',
      statusCode: 200,
      durationMs: 100,
    ));

    expect(recorder.currentSession?.totalRequests, 1);
    
    recorder.stop();
    expect(recorder.isRecording, false);

    recorder.recordEntry(APISessionEntry(
      timestamp: DateTime.now(),
      method: 'GET',
      endpoint: '/other',
      statusCode: 200,
      durationMs: 50,
    ));

    expect(recorder.currentSession?.totalRequests, 1); // Should not increase
  });

  test('SessionExporter should export valid JSON', () {
    recorder.start();
    recorder.recordEntry(APISessionEntry(
      timestamp: DateTime.parse('2026-03-10T10:00:00Z'),
      method: 'GET',
      endpoint: '/users',
      statusCode: 200,
      durationMs: 120,
    ));

    final json = SessionExporter.exportToJson(recorder.currentSession!);
    expect(json, contains('"total_requests": 1'));
    expect(json, contains('"/users"'));
  });
}
