import 'package:flutter/material.dart';
import 'package:buana_vpad/enums/button_shape.dart';
import 'package:buana_vpad/models/button_layout.dart';
import 'package:buana_vpad/models/button_state.dart';

class ButtonWidget extends StatefulWidget {
  final ButtonLayout layout;
  final ButtonState? state;
  final Function(bool isPressed, double value)? onStateChanged;
  final bool isDraggable;

  const ButtonWidget({
    super.key,
    required this.layout,
    this.state,
    this.onStateChanged,
    this.isDraggable = false,
  });

  @override
  State<ButtonWidget> createState() => _ButtonWidgetState();
}

class _ButtonWidgetState extends State<ButtonWidget> {
  static const maxPressDuration = Duration(milliseconds: 500);
  DateTime? pressStartTime;

  void _startPress(double initialPressure) {
    pressStartTime = DateTime.now();
    widget.onStateChanged?.call(true, initialPressure);
    _updatePressValue();
  }

  void _updatePressValue() {
    if (pressStartTime == null || !mounted) return;

    final currentDuration = DateTime.now().difference(pressStartTime!);
    if (currentDuration < maxPressDuration) {
      final progress =
          currentDuration.inMilliseconds / maxPressDuration.inMilliseconds;
      // Mulai dari 0.3 dan naik secara linear sampai 1.0
      final value = 0.3 + (progress * 0.7);
      widget.onStateChanged?.call(true, value);

      // Update terus selama masih ditekan
      Future.delayed(const Duration(milliseconds: 16), _updatePressValue);
    }
  }

  void _endPress() {
    pressStartTime = null;
    widget.onStateChanged?.call(false, 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final buttonWidget = Listener(
      onPointerDown: (event) {
        // Gunakan pressure dari device jika tersedia
        final pressure = event.pressure > 0 && event.pressure < 1
            ? event.pressure
            : 0.3; // Mulai dari 0.3 untuk feedback awal
        _startPress(pressure);
      },
      onPointerMove: (event) {
        if (widget.state?.isPressed == true &&
            event.pressure > 0 &&
            event.pressure < 1) {
          // Update dengan pressure device jika tersedia
          widget.onStateChanged?.call(true, event.pressure);
        }
      },
      onPointerUp: (_) => _endPress(),
      onPointerCancel: (_) => _endPress(),
      child: _buildButtonShape(),
    );

    if (widget.isDraggable) return buttonWidget;

    return Positioned(
      left: widget.layout.x,
      top: widget.layout.y,
      child: buttonWidget,
    );
  }

  Widget _buildButtonShape() {
    final currentValue = widget.state?.value ?? 0.0;
    final baseOpacity = 0.3;
    final pressedOpacity = baseOpacity + (currentValue * 0.7);

    switch (widget.layout.shape) {
      case ButtonShape.circle:
        return Container(
          width: widget.layout.width,
          height: widget.layout.width,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.state?.isPressed == true
                ? Colors.blue.withOpacity(pressedOpacity)
                : Colors.blue.withOpacity(baseOpacity),
            boxShadow: widget.state?.isPressed == true
                ? [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 8 * currentValue,
                      spreadRadius: 2 * currentValue,
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              widget.layout.label,
              style: TextStyle(
                fontSize: widget.layout.width * 0.4,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );

      case ButtonShape.rectangle:
        final rectHeight = widget.layout.height > 0
            ? widget.layout.height
            : widget.layout.width;
        final fontSize = widget.layout.width < rectHeight
            ? widget.layout.width * 0.4
            : rectHeight * 0.4;

        return Container(
          width: widget.layout.width,
          height: rectHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.layout.cornerRadius),
            color: widget.state?.isPressed == true
                ? Colors.blue.withOpacity(pressedOpacity)
                : Colors.blue.withOpacity(baseOpacity),
            boxShadow: widget.state?.isPressed == true
                ? [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 8 * currentValue,
                      spreadRadius: 2 * currentValue,
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              widget.layout.label,
              style: TextStyle(
                fontSize: fontSize,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );

      default:
        return Container();
    }
  }

  @override
  void dispose() {
    pressStartTime = null;
    super.dispose();
  }
}
