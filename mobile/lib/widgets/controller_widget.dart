import 'package:flutter/material.dart';
import 'package:buana_vpad/models/controller_layout.dart';
import 'package:buana_vpad/models/controller_state.dart';
import 'package:buana_vpad/models/button_state.dart';
import 'package:buana_vpad/models/joystick_state.dart';
import 'package:buana_vpad/widgets/button_widget.dart';
import 'package:buana_vpad/widgets/dpad_widget.dart';
import 'package:buana_vpad/widgets/joystick_widget.dart';
import 'package:buana_vpad/models/button_layout.dart';
import 'package:buana_vpad/models/joystick_layout.dart';
import 'package:buana_vpad/models/dpad_layout.dart';
import 'package:buana_vpad/enums/button_shape.dart';

class ControllerWidget extends StatefulWidget {
  final ControllerLayout layout;
  final ControllerState state;
  final Function(ControllerState newState)? onStateChanged;
  final Function(ControllerLayout newLayout)? onLayoutChanged;

  const ControllerWidget({
    super.key,
    required this.layout,
    required this.state,
    this.onStateChanged,
    this.onLayoutChanged,
  });

  @override
  State<ControllerWidget> createState() => _ControllerWidgetState();
}

class _ControllerWidgetState extends State<ControllerWidget> {
  Offset? dragStart;
  Offset? elementOffset;

  Widget _buildResizeHandle({
    required MouseCursor cursor,
    required Function(double dx, double dy) onDrag,
  }) {
    return MouseRegion(
      cursor: cursor,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) => onDrag(details.delta.dx, details.delta.dy),
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.8),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 2,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _wrapWithDraggable({
    required Widget child,
    required double x,
    required double y,
    required Function(double, double) onPositionChanged,
    ButtonLayout? buttonLayout,
    JoystickLayout? joystickLayout,
    DPadLayout? dpadLayout,
  }) {
    if (!widget.layout.isEditable) return child;

    return Positioned(
      left: x,
      top: y,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main draggable content
          MouseRegion(
            cursor: SystemMouseCursors.move,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (details) {
                setState(() {
                  dragStart = details.localPosition;
                  elementOffset = Offset(x, y);
                });
              },
              onPanUpdate: (details) {
                if (dragStart == null || elementOffset == null) return;

                final dx = details.localPosition.dx - dragStart!.dx;
                final dy = details.localPosition.dy - dragStart!.dy;

                final newX = (elementOffset!.dx + dx)
                    .clamp(0.0, widget.layout.width - 50);
                final newY = (elementOffset!.dy + dy)
                    .clamp(0.0, widget.layout.height - 50);

                onPositionChanged(newX, newY);
              },
              onPanEnd: (details) {
                setState(() {
                  dragStart = null;
                  elementOffset = null;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.5),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: child,
              ),
            ),
          ),

          // Resize handles untuk buttons
          if (buttonLayout != null) ...[
            if (buttonLayout.shape == ButtonShape.circle)
              // Scale handle untuk tombol bulat
              Positioned(
                right: -8,
                bottom: -8,
                child: _buildResizeHandle(
                  cursor: SystemMouseCursors.resizeDownRight,
                  onDrag: (dx, dy) {
                    final scale = (buttonLayout.width + dx).clamp(30.0, 120.0);
                    widget.onLayoutChanged?.call(
                      widget.layout.copyWith(
                        newButtons: {
                          ...widget.layout.buttons,
                          buttonLayout.id: buttonLayout.copyWith(
                            newWidth: scale,
                            newHeight: scale,
                          ),
                        },
                      ),
                    );
                  },
                ),
              )
            else if (buttonLayout.shape == ButtonShape.rectangle) ...[
              // Width handle untuk tombol kotak
              Positioned(
                right: -8,
                top: buttonLayout.height / 2 - 8,
                child: _buildResizeHandle(
                  cursor: SystemMouseCursors.resizeRow,
                  onDrag: (dx, _) {
                    final newWidth =
                        (buttonLayout.width + dx).clamp(40.0, 200.0);
                    widget.onLayoutChanged?.call(
                      widget.layout.copyWith(
                        newButtons: {
                          ...widget.layout.buttons,
                          buttonLayout.id: buttonLayout.copyWith(
                            newWidth: newWidth,
                          ),
                        },
                      ),
                    );
                  },
                ),
              ),
              // Height handle untuk tombol kotak
              Positioned(
                bottom: -8,
                left: buttonLayout.width / 2 - 8,
                child: _buildResizeHandle(
                  cursor: SystemMouseCursors.resizeColumn,
                  onDrag: (_, dy) {
                    final newHeight =
                        (buttonLayout.height + dy).clamp(30.0, 100.0);
                    widget.onLayoutChanged?.call(
                      widget.layout.copyWith(
                        newButtons: {
                          ...widget.layout.buttons,
                          buttonLayout.id: buttonLayout.copyWith(
                            newHeight: newHeight,
                          ),
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ],

          // Resize handle untuk joystick
          if (joystickLayout != null)
            Positioned(
              right: -8,
              bottom: -8,
              child: _buildResizeHandle(
                cursor: SystemMouseCursors.resizeDownRight,
                onDrag: (dx, _) {
                  final newSize =
                      (joystickLayout.outerSize + dx).clamp(100.0, 200.0);
                  final newInnerSize = newSize *
                      (joystickLayout.innerSize / joystickLayout.outerSize);
                  if (joystickLayout == widget.layout.leftJoystick) {
                    widget.onLayoutChanged?.call(
                      widget.layout.copyWith(
                        newLeftJoystick: joystickLayout.copyWith(
                          newOuterSize: newSize,
                          newInnerSize: newInnerSize,
                        ),
                      ),
                    );
                  } else {
                    widget.onLayoutChanged?.call(
                      widget.layout.copyWith(
                        newRightJoystick: joystickLayout.copyWith(
                          newOuterSize: newSize,
                          newInnerSize: newInnerSize,
                        ),
                      ),
                    );
                  }
                },
              ),
            ),

          // Resize handle untuk DPad
          if (dpadLayout != null)
            Positioned(
              right: -8,
              bottom: -8,
              child: _buildResizeHandle(
                cursor: SystemMouseCursors.resizeDownRight,
                onDrag: (dx, _) {
                  final newSize = (dpadLayout.size + dx).clamp(100.0, 200.0);
                  widget.onLayoutChanged?.call(
                    widget.layout.copyWith(
                      newDPadLayout: dpadLayout.copyWith(
                        newSize: newSize,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.layout.width,
      height: widget.layout.height,
      color: Colors.transparent,
      child: Stack(
        children: [
          // Render buttons
          ...widget.layout.buttons.entries.map((entry) {
            final buttonId = entry.key;
            final buttonLayout = entry.value;
            final buttonState = widget.state.buttonStates[buttonId];

            return _wrapWithDraggable(
              x: buttonLayout.x,
              y: buttonLayout.y,
              buttonLayout: buttonLayout,
              onPositionChanged: (x, y) {
                widget.onLayoutChanged?.call(
                  widget.layout.copyWith(
                    newButtons: {
                      ...widget.layout.buttons,
                      entry.key: buttonLayout.copyWith(newX: x, newY: y),
                    },
                  ),
                );
              },
              child: ButtonWidget(
                isDraggable: widget.layout.isEditable,
                layout: buttonLayout,
                state: buttonState,
                onStateChanged: widget.layout.isEditable
                    ? null
                    : (isPressed, value) {
                        final newButtonStates = Map<String, ButtonState>.from(
                            widget.state.buttonStates);
                        newButtonStates[buttonId] = ButtonState(
                          id: buttonId,
                          isPressed: isPressed,
                          value: value,
                        );
                        widget.onStateChanged?.call(widget.state.copyWith(
                          newButtonStates: newButtonStates,
                        ));
                      },
              ),
            );
          }).toList(),

          // Render left joystick
          if (widget.layout.leftJoystick != null)
            _wrapWithDraggable(
              x: widget.layout.leftJoystick!.x,
              y: widget.layout.leftJoystick!.y,
              joystickLayout: widget.layout.leftJoystick,
              onPositionChanged: (x, y) {
                widget.onLayoutChanged?.call(widget.layout.copyWith(
                  newLeftJoystick: widget.layout.leftJoystick!.copyWith(
                    newX: x,
                    newY: y,
                  ),
                ));
              },
              child: JoystickWidget(
                isDraggable: widget.layout.isEditable,
                layout: widget.layout.leftJoystick!,
                state: widget.state.leftJoystickState,
                onJoystickMove: widget.layout.isEditable
                    ? null
                    : (dx, dy, intensity, angle) {
                        widget.onStateChanged?.call(widget.state.copyWith(
                          newLeftJoystickState: JoystickState(
                            dx: dx,
                            dy: dy,
                            intensity: intensity,
                            angle: angle,
                            isPressed: intensity > 0,
                          ),
                        ));
                      },
              ),
            ),

          // Render right joystick
          if (widget.layout.rightJoystick != null)
            _wrapWithDraggable(
              x: widget.layout.rightJoystick!.x,
              y: widget.layout.rightJoystick!.y,
              joystickLayout: widget.layout.rightJoystick,
              onPositionChanged: (x, y) {
                widget.onLayoutChanged?.call(widget.layout.copyWith(
                  newRightJoystick: widget.layout.rightJoystick!.copyWith(
                    newX: x,
                    newY: y,
                  ),
                ));
              },
              child: JoystickWidget(
                isDraggable: widget.layout.isEditable,
                layout: widget.layout.rightJoystick!,
                state: widget.state.rightJoystickState,
                onJoystickMove: widget.layout.isEditable
                    ? null
                    : (dx, dy, intensity, angle) {
                        widget.onStateChanged?.call(widget.state.copyWith(
                          newRightJoystickState: JoystickState(
                            dx: dx,
                            dy: dy,
                            intensity: intensity,
                            angle: angle,
                            isPressed: intensity > 0,
                          ),
                        ));
                      },
              ),
            ),

          // Render DPad
          if (widget.layout.dpadLayout != null)
            _wrapWithDraggable(
              x: widget.layout.dpadLayout!.centerX -
                  (widget.layout.dpadLayout!.size / 2),
              y: widget.layout.dpadLayout!.centerY -
                  (widget.layout.dpadLayout!.size / 2),
              dpadLayout: widget.layout.dpadLayout,
              onPositionChanged: (x, y) {
                widget.onLayoutChanged?.call(widget.layout.copyWith(
                  newDPadLayout: widget.layout.dpadLayout!.copyWith(
                    newCenterX: x + (widget.layout.dpadLayout!.size / 2),
                    newCenterY: y + (widget.layout.dpadLayout!.size / 2),
                  ),
                ));
              },
              child: DPadWidget(
                layout: widget.layout.dpadLayout!,
                state: widget.state.dpadState,
                isDraggable: widget.layout.isEditable,
                onDirectionChanged: widget.layout.isEditable
                    ? (direction, isPressed) {}
                    : (direction, isPressed) {
                        widget.onStateChanged?.call(widget.state
                            .updateDPadDirection(direction, isPressed));
                      },
              ),
            ),
        ],
      ),
    );
  }
}
