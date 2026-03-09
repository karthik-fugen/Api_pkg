import 'api_metrics.dart';

class MetricsRegistry {
  static final MetricsRegistry _instance = MetricsRegistry._internal();
  factory MetricsRegistry() => _instance;
  MetricsRegistry._internal();

  final Map<String, EndpointMetrics> _metrics = {};
  final List<TimelineEntry> _timeline = [];
  static const int _maxTimelineEntries = 100;

  Map<String, EndpointMetrics> get metrics => Map.unmodifiable(_metrics);
  List<TimelineEntry> get timeline => List.unmodifiable(_timeline);

  void updateMetrics({
    required String endpoint,
    required Duration duration,
    required bool isError,
    required bool isSlow,
  }) {
    final metrics = _metrics.putIfAbsent(endpoint, () => EndpointMetrics(endpoint: endpoint));
    metrics.update(duration: duration, isError: isError, isSlow: isSlow);
  }

  void addTimelineEntry(TimelineEntry entry) {
    if (_timeline.length >= _maxTimelineEntries) {
      _timeline.removeAt(0);
    }
    _timeline.add(entry);
  }

  void clear() {
    _metrics.clear();
    _timeline.clear();
  }
}
