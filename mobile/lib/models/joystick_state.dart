
class JoystickState {
  final double dx;          // posisi horizontal (-1.0 sampai 1.0)
  final double dy;          // posisi vertikal (-1.0 sampai 1.0)
  final bool isPressed;     
  final double intensity;   // kekuatan dorongan (0.0 - 1.0)
  final double angle;       // sudut dalam radian
  final DateTime timestamp;

  JoystickState({
    required this.dx,
    required this.dy,
    required this.isPressed,
    required this.intensity,
    required this.angle,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  // Helpers
  bool get isIdle => dx == 0 && dy == 0;
  bool get isAtMaxIntensity => intensity >= 0.95;

  Map<String, dynamic> toJson() {
    return {
      'dx': dx,
      'dy': dy,
      'isPressed': isPressed,
      'intensity': intensity,
      'angle': angle,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}