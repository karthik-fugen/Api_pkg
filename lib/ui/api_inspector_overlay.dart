import 'package:flutter/material.dart';
import 'api_inspector_dashboard.dart';

class APIInspectorOverlay extends StatefulWidget {
  final Widget child;

  const APIInspectorOverlay({super.key, required this.child});

  @override
  State<APIInspectorOverlay> createState() => _APIInspectorOverlayState();
}

class _APIInspectorOverlayState extends State<APIInspectorOverlay> {
  Offset _offset = const Offset(20, 100);

  @override
  Widget build(BuildContext context) {
    return Stack(
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
            child: _buildFloatingButton(context, false),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingButton(BuildContext context, bool dragging) {
    return Material(
      color: Colors.transparent,
      child: Opacity(
        opacity: dragging ? 0.5 : 0.8,
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const APILogDashboard()),
            );
          },
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.bug_report,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
