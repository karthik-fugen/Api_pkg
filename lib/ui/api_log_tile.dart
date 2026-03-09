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
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: _buildLeading(),
        title: Text(
          '#${entry.metadata?['requestId'] ?? '??'} ${entry.endpoint}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            fontFamily: 'monospace',
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              _buildMethodBadge(),
              const SizedBox(width: 8),
              if (entry.type == LogType.response || entry.type == LogType.error) ...[
                _buildStatusBadge(),
                const SizedBox(width: 8),
              ],
              Text(
                _getDurationText(),
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
            ],
          ),
        ),
        trailing: Text(
          _formatTime(entry.timestamp),
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildLeading() {
    IconData icon;
    Color color;
    switch (entry.type) {
      case LogType.request:
        icon = Icons.upload;
        color = Colors.blue;
        break;
      case LogType.response:
        icon = Icons.download;
        color = Colors.green;
        break;
      case LogType.error:
        icon = Icons.error_outline;
        color = Colors.red;
        break;
      case LogType.warning:
        icon = Icons.warning_amber_rounded;
        color = Colors.orange;
        break;
      case LogType.schemaChange:
        icon = Icons.schema_outlined;
        color = Colors.purple;
        break;
      case LogType.performance:
        icon = Icons.speed;
        color = Colors.deepOrange;
        break;
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildMethodBadge() {
    final method = entry.metadata?['method']?.toString().toUpperCase() ?? 'GET';
    Color color;
    switch (method) {
      case 'GET': color = Colors.cyan; break;
      case 'POST': color = Colors.green; break;
      case 'PUT':
      case 'PATCH': color = Colors.orange; break;
      case 'DELETE': color = Colors.red; break;
      default: color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(100), width: 0.5),
      ),
      child: Text(
        method,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final status = entry.metadata?['statusCode'] ?? 0;
    Color color;
    if (status >= 200 && status < 300) {
      color = Colors.green;
    } else if (status >= 400 && status < 500) {
      color = Colors.orange;
    } else if (status >= 500) {
      color = Colors.red;
    } else {
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toString(),
        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _getDurationText() {
    final ms = entry.metadata?['durationMs'];
    if (ms == null) return '';
    return '${ms}ms';
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}";
  }
}
