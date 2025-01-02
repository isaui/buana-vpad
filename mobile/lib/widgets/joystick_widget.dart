import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:buana_vpad/models/joystick_layout.dart';
import 'package:buana_vpad/models/joystick_state.dart';

class JoystickWidget extends StatelessWidget {
  final JoystickLayout layout;
  final JoystickState? state;
  final Function(double dx, double dy, double intensity, double angle)?
      onJoystickMove;
  final bool isDraggable;

  const JoystickWidget({
    super.key,
    required this.layout,
    this.state,
    this.onJoystickMove,
    this.isDraggable = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseWidget = Container(
      width: layout.outerSize,
      height: layout.outerSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black12,
        border: Border.all(
          color: isDraggable ? Colors.blue.withOpacity(0.3) : Colors.black26,
          width: 2,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (state != null && !state!.isIdle)
            Positioned.fill(child: _buildIntensityIndicator()),
          _buildKnob(),
          if (isDraggable)
            Positioned(
              right: 5,
              top: 5,
              child: Icon(
                Icons.drag_indicator,
                size: 16,
                color: Colors.black26,
              ),
            ),
        ],
      ),
    );

    final joystickWidget = GestureDetector(
      behavior: HitTestBehavior.translucent, // Ganti ke translucent
      onPanStart: !isDraggable
          ? (onPanStart) {
              _handlePanStart(onPanStart, context);
              if (layout.hapticEnabled) {
                HapticFeedback.lightImpact();
              }
            }
          : null,
      onPanUpdate: !isDraggable
          ? (onPanUpdate) => _handlePanUpdate(onPanUpdate, context)
          : null,
      onPanEnd: !isDraggable
          ? (details) {
              _handlePanEnd(details);
              if (layout.hapticEnabled) {
                HapticFeedback.lightImpact();
              }
            }
          : null,
      child: baseWidget,
    );

    if (isDraggable) {
      return joystickWidget;
    }

    return Positioned(
      left: layout.x,
      top: layout.y,
      child: joystickWidget,
    );
  }

  Widget _buildIntensityIndicator() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
    );
  }

  Widget _buildKnob() {
    double dx = state?.dx ?? 0;
    double dy = state?.dy ?? 0;

    final center = layout.outerSize / 2;
    final maxRadius = (layout.outerSize - layout.innerSize) / 2;

    final xPos = center + (dx * maxRadius) - (layout.innerSize / 2);
    final yPos = center + (dy * maxRadius) - (layout.innerSize / 2);

    return Positioned(
      left: xPos,
      top: yPos,
      child: Transform.rotate(
        angle: state?.angle ?? 0,
        child: Container(
          width: layout.innerSize,
          height: layout.innerSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: state?.isPressed == true
                ? (state!.isAtMaxIntensity
                    ? Colors.blue.withOpacity(0.9)
                    : Colors.blue.withOpacity(0.7))
                : Colors.blue.withOpacity(0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handlePanStart(DragStartDetails details, BuildContext context) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);
    _updateJoystickPosition(localPosition);
  }

  void _handlePanUpdate(DragUpdateDetails details, BuildContext context) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);
    _updateJoystickPosition(localPosition);
  }

  void _handlePanEnd(DragEndDetails details) {
    if (!layout.isFixed) {
      onJoystickMove?.call(0, 0, 0, 0);
    }
  }

  void _updateJoystickPosition(Offset localPosition) {
    final center = layout.outerSize / 2;
    final dx = localPosition.dx - center;
    final dy = localPosition.dy - center;

    final distance = sqrt(dx * dx + dy * dy) / (layout.outerSize / 2);
    final angle = atan2(dy, dx);

    final values = layout.getJoystickValues(localPosition.dx, localPosition.dy);

    onJoystickMove?.call(
        values['dx']!, values['dy']!, distance.clamp(0.0, 1.0), angle);
  }
}
