import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'log_storage.dart';
import 'api_log_tile.dart';
import '../core/api_inspector.dart';

import '../profiler/metrics_registry.dart';
import '../profiler/api_profiler.dart';
import '../profiler/timeline_builder.dart';

import '../session/session_recorder.dart';
import '../session/session_exporter.dart';

import '../core/inspector_state.dart';

class APILogDashboard extends StatefulWidget {
  const APILogDashboard({super.key});

  @override
  State<APILogDashboard> createState() => _APILogDashboardState();
}

class _APILogDashboardState extends State<APILogDashboard> {
  final LogStorage _storage = LogStorage();
  final MetricsRegistry _metricsRegistry = MetricsRegistry();
  final SessionRecorder _sessionRecorder = SessionRecorder();
  final InspectorState _inspectorState = InspectorState();
  String _filter = 'All';
  String _searchQuery = '';

  List<APILogEntry> get _filteredLogs {
    var logs = _storage.logs;

    if (_searchQuery.isNotEmpty) {
      logs = logs.where((l) {
        final endpointMatch = l.endpoint.toLowerCase().contains(_searchQuery.toLowerCase());
        final statusCodeMatch = l.metadata?['statusCode']?.toString().contains(_searchQuery) ?? false;
        return endpointMatch || statusCodeMatch;
      }).toList();
    }

    if (_filter == 'All') return logs.reversed.toList();
    if (_filter == 'Requests') return logs.where((l) => l.type == LogType.request).toList().reversed.toList();
    if (_filter == 'Errors') return logs.where((l) => l.type == LogType.error).toList().reversed.toList();
    if (_filter == 'Warnings') return logs.where((l) => l.type == LogType.warning).toList().reversed.toList();
    if (_filter == 'Schema Changes') return logs.where((l) => l.type == LogType.schemaChange).toList().reversed.toList();
    return logs.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('API Inspector'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Logs', icon: Icon(Icons.list)),
              Tab(text: 'Performance', icon: Icon(Icons.speed)),
              Tab(text: 'Session', icon: Icon(Icons.history)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () {
                setState(() {
                  _storage.clear();
                  _metricsRegistry.clear();
                  _sessionRecorder.clear();
                  _inspectorState.resetErrors();
                });
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildLogsTab(),
            _buildPerformanceTab(),
            _buildSessionTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsTab() {
    return Column(
      children: [
        _buildSearchBar(),
        _buildFilterBar(),
        Expanded(
          child: ListView.builder(
            itemCount: _filteredLogs.length,
            itemBuilder: (context, index) {
              final entry = _filteredLogs[index];
              return APILogTile(
                entry: entry,
                onTap: () => _showLogDetails(context, entry),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search endpoint or status code...',
          prefixIcon: const Icon(Icons.search),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildPerformanceTab() {
    final slowest = APIProfiler.getSlowestEndpoints();
    final timeline = _metricsRegistry.timeline;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Slowest Endpoints', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (slowest.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No performance data yet.')))
        else
          ...slowest.take(5).map((m) => Card(
                child: ListTile(
                  title: Text(m.endpoint),
                  subtitle: Text('Avg: ${m.averageResponseTimeMs.toStringAsFixed(1)}ms • Requests: ${m.totalRequests}'),
                  trailing: Icon(Icons.timer, color: _getPerformanceColor(m.averageResponseTimeMs)),
                ),
              )),
        const SizedBox(height: 24),
        Text('Timeline', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (timeline.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No activity yet.')))
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: timeline.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = timeline[timeline.length - 1 - index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    TimelineBuilder.buildLog(entry),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Color _getPerformanceColor(double ms) {
    if (ms < 500) return Colors.green;
    if (ms < 1500) return Colors.orange;
    return Colors.red;
  }

  Widget _buildSessionTab() {
    final session = _sessionRecorder.currentSession;
    final isRecording = _sessionRecorder.isRecording;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isRecording ? 'Recording Session...' : 'Session Recording',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Switch(
                      value: isRecording,
                      onChanged: (value) {
                        setState(() {
                          if (value) {
                            _sessionRecorder.start();
                          } else {
                            _sessionRecorder.stop();
                          }
                        });
                      },
                    ),
                  ],
                ),
                if (session != null) ...[
                  const Divider(),
                  _detailRow('Started At', session.startTime.toString()),
                  _detailRow('Total Calls', session.totalRequests.toString()),
                  _detailRow('Errors', session.totalErrors.toString()),
                  _detailRow('Avg Time', '${session.averageResponseTime.toStringAsFixed(1)}ms'),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (session != null && session.entries.isNotEmpty) ...[
          ElevatedButton.icon(
            onPressed: () => _exportSession(context),
            icon: const Icon(Icons.download),
            label: const Text('Export Session (JSON)'),
          ),
          const SizedBox(height: 24),
          const Text('Session Timeline', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...session.entries.reversed.map((e) => Card(
                child: ListTile(
                  dense: true,
                  title: Text(e.endpoint, style: const TextStyle(fontSize: 12)),
                  subtitle: Text('${e.method} • ${e.statusCode} • ${e.durationMs}ms', style: const TextStyle(fontSize: 10)),
                  trailing: Icon(
                    Icons.circle,
                    size: 12,
                    color: (e.statusCode ?? 0) >= 400 ? Colors.red : Colors.green,
                  ),
                ),
              )),
        ] else if (session == null)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No session recorded. Toggle the switch to start.'),
            ),
          ),
      ],
    );
  }

  void _exportSession(BuildContext context) {
    final session = _sessionRecorder.currentSession;
    if (session == null) return;

    final json = SessionExporter.exportToJson(session);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Session Export'),
          content: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[100],
              child: SelectableText(
                json,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterBar() {
    final filters = ['All', 'Requests', 'Errors', 'Warnings', 'Schema Changes'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: filters.map((f) {
          final isSelected = _filter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(f),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _filter = f;
                  });
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showLogDetails(BuildContext context, APILogEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (_, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: ListView(
                controller: scrollController,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Log Details',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_all),
                        tooltip: 'Copy Full Log',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: entry.message));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Log copied to clipboard')),
                          );
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  _detailRow('Endpoint', entry.endpoint),
                  _detailRow('Timestamp', entry.timestamp.toString()),
                  _detailRow('Type', entry.type.toString().split('.').last),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (entry.type == LogType.request && entry.metadata?['requestId'] != null)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.pop(context);
                              await APIInspector.replayRequest(entry.metadata!['requestId']);
                            },
                            icon: const Icon(Icons.replay),
                            label: const Text('Replay'),
                          ),
                        ),
                      if (entry.metadata?['curl'] != null && entry.metadata!['curl'].toString().isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: entry.metadata!['curl']));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('CURL copied')),
                              );
                            },
                            icon: const Icon(Icons.code),
                            label: const Text('Copy CURL'),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Raw Log Output:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      entry.message.trim(),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
