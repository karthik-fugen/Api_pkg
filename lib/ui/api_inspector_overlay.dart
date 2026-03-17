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
  bool _isOverlayInserted = false;

  @override
  void initState() {
    super.initState();
    // We use a post-frame callback to insert the overlay after the Navigator is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _insertOverlay();
    });
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _insertOverlay() {
    if (_isOverlayInserted || !mounted) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => _PersistentOverlay(state: _state),
    );

    // Find the overlay and insert
    final overlay = Overlay.of(context, rootOverlay: true);
    overlay.insert(_overlayEntry!);
    _isOverlayInserted = true;
  }

  void _removeOverlay() {
    if (_isOverlayInserted) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _isOverlayInserted = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // We still return the child so the app continues to render normally.
    // The overlay sits in a parallel layer.
    return widget.child;
  }
}

class _PersistentOverlay extends StatelessWidget {
  final InspectorState state;

  const _PersistentOverlay({required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final screenSize = MediaQuery.of(context).size;
        
        // Clamp position to screen bounds
        double left = state.offset.dx;
        double top = state.offset.dy;
        
        // Ensure it doesn't go off screen (with some padding)
        left = left.clamp(0.0, screenSize.width - 60);
        top = top.clamp(0.0, screenSize.height - 40);

        return Positioned(
          left: left,
          top: top,
          child: _DraggableButton(state: state),
        );
      },
    );
  }
}

class _DraggableButton extends StatelessWidget {
  final InspectorState state;

  const _DraggableButton({required this.state});

  @override
  Widget build(BuildContext context) {
    // We wrap in Directionality and Material to ensure icons and text render 
    // correctly even if the root context is missing them.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Draggable(
        feedback: _FloatingButton(state: state, dragging: true),
        childWhenDragging: Container(),
        onDragEnd: (details) {
          state.updateOffset(details.offset);
        },
        child: _FloatingButton(state: state, dragging: false),
      ),
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
            // Priority 1: Use the developer-provided navigatorKey
            final navigator = APIInspector.navigatorKey.currentState;
            if (navigator != null) {
              navigator.push(
                MaterialPageRoute(builder: (context) => const APILogDashboard()),
              );
            } else {
              // Priority 2: Try to find the root navigator from the current context
              try {
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (context) => const APILogDashboard()),
                );
              } catch (e) {
                debugPrint('APIInspector Error: Could not find Navigator. '
                    'Did you set APIInspector.navigatorKey in your MaterialApp?');
              }
            }
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
                    const Icon(Icons.bug_report, color: Colors.white, size: 18),
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
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
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
