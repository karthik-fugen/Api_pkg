import 'dart:convert';
import 'session_models.dart';

class SessionExporter {
  static String exportToJson(APISession session) {
    final Map<String, dynamic> data = session.toJson();
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }
}
