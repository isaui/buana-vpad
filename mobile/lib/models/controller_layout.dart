import 'package:buana_vpad/models/button_layout.dart';
import 'package:buana_vpad/models/joystick_layout.dart';
import 'package:buana_vpad/models/dpad_layout.dart';

class ControllerLayout {
  final String id;
  final String name;
  final Map<String, ButtonLayout> buttons;
  final JoystickLayout? leftJoystick;
  final JoystickLayout? rightJoystick;
  final DPadLayout? dpadLayout; // Tambah DPad layout
  final double width;
  final double height;
  final bool isEditable;

  ControllerLayout({
    required this.id,
    required this.name,
    required this.buttons,
    required this.width,
    required this.height,
    this.leftJoystick,
    this.rightJoystick,
    this.dpadLayout, // Tambah di constructor
    this.isEditable = false,
  });

  Map<String, dynamic>? getTouchedControl(double touchX, double touchY) {
    // Cek buttons dulu
    for (var entry in buttons.entries) {
      if (entry.value.containsPoint(touchX, touchY)) {
        return {
          'type': 'button',
          'id': entry.key,
          'layout': entry.value,
        };
      }
    }

    // Cek DPad
    if (dpadLayout?.containsPoint(touchX, touchY) ?? false) {
      return {
        'type': 'dpad',
        'id': 'dpad',
        'layout': dpadLayout,
      };
    }

    // Cek joysticks
    if (leftJoystick?.containsPoint(touchX, touchY) ?? false) {
      return {
        'type': 'joystick',
        'id': 'left',
        'layout': leftJoystick,
      };
    }

    if (rightJoystick?.containsPoint(touchX, touchY) ?? false) {
      return {
        'type': 'joystick',
        'id': 'right',
        'layout': rightJoystick,
      };
    }

    return null;
  }

  ControllerLayout copyWith(
      {Map<String, ButtonLayout>? newButtons,
      JoystickLayout? newLeftJoystick,
      JoystickLayout? newRightJoystick,
      DPadLayout? newDPadLayout, // Tambah di copyWith
      double? newWidth,
      double? newHeight,
      bool? newIsEditable,
      String? newName}) {
    return ControllerLayout(
      id: id,
      name: newName ?? name,
      buttons: newButtons ?? buttons,
      width: newWidth ?? width,
      height: newHeight ?? height,
      leftJoystick: newLeftJoystick ?? leftJoystick,
      rightJoystick: newRightJoystick ?? rightJoystick,
      dpadLayout: newDPadLayout ?? dpadLayout, // Include di return
      isEditable: newIsEditable ?? isEditable,
    );
  }
}
