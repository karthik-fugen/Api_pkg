import 'package:flutter/material.dart';
import 'api_inspector_dashboard.dart';
import '../core/api_inspector.dart';
import '../core/inspector_state.dart';

class APIInspectorOverlay extends StatefulWidget {
  final Widget child;

  const APIInspectorOverlay({super.key, required this.child});

  @override
  State<APIInspectorOverlay> createState() => _APIInspectorOverlayState();
}

class _APIInspectorOverlayState extends State<APIInspectorOverlay> {
  Offset _offset = const Offset(20, 100);
  final InspectorState _state = InspectorState();

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Stack(
        children: [
          widget.child,
          Positioned(
            left: _offset.dx,
            top: _offset.dy,
            child: Draggable(
              feedback: _buildFloatingButton(context, true),
              childWhenDragging: Container(),
              onDragEnd: (details) {
                setState(() {
                  _offset = details.offset;
                });
              },
              child: AnimatedBuilder(
                animation: _state,
                builder: (context, _) => _buildFloatingButton(context, false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton(BuildContext context, bool dragging) {
    return Material(
      color: Colors.transparent,
      child: Opacity(
        opacity: dragging ? 0.5 : 0.9,
        child: GestureDetector(
          onTap: () {
            APIInspector.navigatorKey.currentState?.push(
              MaterialPageRoute(builder: (context) => const APILogDashboard()),
            );
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _getButtonColor(),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(50),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bug_report,
                      color: Colors.white,
                      size: 18,
                    ),
                    if (_state.lastResponseTimeMs > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '${_state.lastResponseTimeMs}ms',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_state.errorCount > 0)
                Positioned(
                  right: -5,
                  top: -5,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '${_state.errorCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getButtonColor() {
    if (_state.errorCount > 0) return Colors.redAccent;
    if (_state.lastResponseTimeMs > 1000) return Colors.orangeAccent;
    return Colors.blueAccent;
  }
}
