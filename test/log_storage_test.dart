import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_api_inspector/ui/log_storage.dart';

void main() {
  test('LogStorage should add and limit logs', () {
    final storage = LogStorage();
    storage.clear();

    for (int i = 0; i < 250; i++) {
      storage.addLog(APILogEntry(
        type: LogType.request,
        endpoint: '/test/$i',
        message: 'msg $i',
        timestamp: DateTime.now(),
      ));
    }

    expect(storage.logs.length, 200);
    expect(storage.logs.first.endpoint, '/test/50');
    expect(storage.logs.last.endpoint, '/test/249');
  });

  test('LogStorage should clear logs', () {
    final storage = LogStorage();
    storage.addLog(APILogEntry(
      type: LogType.request,
      endpoint: '/test',
      message: 'msg',
      timestamp: DateTime.now(),
    ));
    expect(storage.logs.isNotEmpty, true);
    
    storage.clear();
    expect(storage.logs.isEmpty, true);
  });
}
