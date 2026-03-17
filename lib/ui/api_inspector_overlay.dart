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
  final InspectorState _state = InspectorState();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to ensure the overlay is added after the first build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showOverlay();
      }
    });
  }

  @override
  void didUpdateWidget(APIInspectorOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the overlay was somehow removed, we might want to re-add it,
    // but usually, it stays until disposed.
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: _state.offset.dx,
        top: _state.offset.dy,
        child: _DraggableButton(state: _state, onDragEnd: (offset) {
          _state.updateOffset(offset);
          _overlayEntry?.markNeedsBuild();
        }),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _DraggableButton extends StatelessWidget {
  final InspectorState state;
  final Function(Offset) onDragEnd;

  const _DraggableButton({required this.state, required this.onDragEnd});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        return Draggable(
          feedback: _FloatingButton(state: state, dragging: true),
          childWhenDragging: Container(),
          onDragEnd: (details) => onDragEnd(details.offset),
          child: _FloatingButton(state: state, dragging: false),
        );
      },
    );
  }
}

class _FloatingButton extends StatelessWidget {
  final InspectorState state;
  final bool dragging;

  const _FloatingButton({required this.state, required this.dragging});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Opacity(
        opacity: dragging ? 0.5 : 0.9,
        child: GestureDetector(
          onTap: () {
            // Using a fallback to Navigator.of(context) if APIInspector.navigatorKey is not set.
            final navigator = APIInspector.navigatorKey.currentState ?? Navigator.of(context, rootNavigator: true);
            navigator.push(
              MaterialPageRoute(builder: (context) => const APILogDashboard()),
            );
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _getButtonColor(state),
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
                    if (state.lastResponseTimeMs > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '${state.lastResponseTimeMs}ms',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (state.errorCount > 0)
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
                      '${state.errorCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
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

  Color _getButtonColor(InspectorState state) {
    if (state.errorCount > 0) return Colors.redAccent;
    if (state.lastResponseTimeMs > 1000) return Colors.orangeAccent;
    return Colors.blueAccent;
  }
}
