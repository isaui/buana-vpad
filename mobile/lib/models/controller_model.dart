import 'package:buana_vpad/models/controller_layout.dart';
import 'package:buana_vpad/models/controller_state.dart';

class ControllerModel {
  final String id;
  final String controllerName;
  final ControllerLayout layout; // blueprint layout
  final ControllerState state; // state saat ini

  ControllerModel({
    required this.id,
    required this.controllerName,
    required this.layout,
    required this.state,
  });

  ControllerModel copyWith({
    ControllerState? newState,
  }) {
    return ControllerModel(
      id: id,
      controllerName: controllerName,
      layout: layout,
      state: newState ?? state,
    );
  }
}
