import 'package:buana_vpad/models/button_state.dart';
import 'package:buana_vpad/models/joystick_state.dart';
import 'package:buana_vpad/models/dpad_state.dart';

class ControllerState {
  final Map<String, ButtonState> buttonStates;
  final JoystickState? leftJoystickState;
  final JoystickState? rightJoystickState;
  final DPadState? dpadState;
  final DateTime timestamp;

  ControllerState({
    required this.buttonStates,
    this.leftJoystickState,
    this.rightJoystickState,
    this.dpadState,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  // Copy with untuk update state
  ControllerState copyWith({
    Map<String, ButtonState>? newButtonStates,
    JoystickState? newLeftJoystickState,
    JoystickState? newRightJoystickState,
    DPadState? newDPadState, // Tambah di copyWith
  }) {
    return ControllerState(
      buttonStates: newButtonStates ?? buttonStates,
      leftJoystickState: newLeftJoystickState ?? leftJoystickState,
      rightJoystickState: newRightJoystickState ?? rightJoystickState,
      dpadState: newDPadState ?? dpadState,
    );
  }

  // Helper untuk update DPad state
  ControllerState updateDPadDirection(String direction, bool isPressed) {
    final newDPadState = dpadState?.updateDirection(direction, isPressed) ??
        DPadState().updateDirection(direction, isPressed);

    return copyWith(newDPadState: newDPadState);
  }

  Map<String, dynamic> toJson() {
    return {
      'buttonStates':
          buttonStates.map((key, value) => MapEntry(key, value.toJson())),
      'leftJoystickState': leftJoystickState?.toJson(),
      'rightJoystickState': rightJoystickState?.toJson(),
      'dpadState': dpadState?.toJson(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
