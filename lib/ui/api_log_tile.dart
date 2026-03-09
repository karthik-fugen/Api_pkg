import 'package:flutter/material.dart';
import 'log_storage.dart';

class APILogTile extends StatelessWidget {
  final APILogEntry entry;
  final VoidCallback onTap;

  const APILogTile({
    super.key,
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: _buildIcon(),
        title: Text(
          '#${entry.metadata?['requestId'] ?? '??'} ${entry.endpoint}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          _getSubtitle(),
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: Text(
          _formatTime(entry.timestamp),
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    switch (entry.type) {
      case LogType.request:
        return const Icon(Icons.arrow_upward, color: Colors.blue);
      case LogType.response:
        return const Icon(Icons.arrow_downward, color: Colors.green);
      case LogType.error:
        return const Icon(Icons.error, color: Colors.red);
      case LogType.warning:
        return const Icon(Icons.warning, color: Colors.orange);
      case LogType.schemaChange:
        return const Icon(Icons.schema, color: Colors.purple);
      case LogType.performance:
        return const Icon(Icons.speed, color: Colors.deepOrange);
    }
  }

  String _getSubtitle() {
    switch (entry.type) {
      case LogType.request:
        return "Method: ${entry.metadata?['method'] ?? 'Unknown'}";
      case LogType.response:
        return "Status: ${entry.metadata?['statusCode'] ?? 'Unknown'} • ${entry.metadata?['durationMs'] ?? 0}ms";
      case LogType.error:
        return "Error: ${entry.metadata?['errorMessage'] ?? 'Unknown'}";
      case LogType.warning:
        return "Warning: ${entry.metadata?['warningType'] ?? 'Unknown'}";
      case LogType.schemaChange:
        return "Schema: ${entry.metadata?['changeType'] ?? 'Unknown'}";
      case LogType.performance:
        return "Performance: ${entry.metadata?['averageTimeMs']?.toStringAsFixed(1) ?? '0.0'}ms (Avg)";
    }
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}";
  }
}
