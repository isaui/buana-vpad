import 'dart:math' show pi, cos, sin;
import 'package:buana_vpad/enums/button_shape.dart';

class ButtonLayout {
  final String id;
  final double x;
  final double y;
  final ButtonShape shape;
  final String label;

  final double width;
  final double height;
  final double angle;
  final double sensitivity;
  final double deadzone;
  final bool isAnalog;

  final double cornerRadius;
  final bool hapticFeedback;

  ButtonLayout({
    required this.id,
    required this.x,
    required this.y,
    required this.shape,
    required this.label,
    required this.width,
    this.height = 0,
    this.angle = 0,
    this.sensitivity = 1.0,
    this.deadzone = 0.1,
    this.isAnalog = false,
    this.cornerRadius = 8.0,
    this.hapticFeedback = true,
  });

  bool get isDigital => !isAnalog;

  bool containsPoint(double touchX, double touchY) {
    switch (shape) {
      case ButtonShape.circle:
        return _checkCircleCollision(touchX, touchY);
      case ButtonShape.rectangle:
        return _checkRectCollision(touchX, touchY);
    }
  }

  // Collision detection untuk lingkaran
  bool _checkCircleCollision(double touchX, double touchY) {
    final radius = width / 2;
    final dx = touchX - (x + radius);
    final dy = touchY - (y + radius);
    return (dx * dx + dy * dy) <= radius * radius;
  }

  // Collision detection untuk persegi panjang
  bool _checkRectCollision(double touchX, double touchY) {
    final actualHeight = height > 0 ? height : width;
    return touchX >= x &&
        touchX <= x + width &&
        touchY >= y &&
        touchY <= y + actualHeight;
  }

  // Collision untuk tombol diagonal (seperti d-pad)
  bool _checkDiagonalCollision(double touchX, double touchY) {
    // Transform touch point berdasarkan rotasi
    final centerX = x + width / 2;
    final centerY = y + height / 2;

    final rotatedX = (touchX - centerX) * cos(-angle * pi / 180) -
        (touchY - centerY) * sin(-angle * pi / 180) +
        centerX;
    final rotatedY = (touchX - centerX) * sin(-angle * pi / 180) +
        (touchY - centerY) * cos(-angle * pi / 180) +
        centerY;

    // Cek collision dengan rectangle yang sudah dirotasi
    return _checkRectCollision(rotatedX, rotatedY);
  }

  // Collision untuk trigger (analog)
  bool _checkTriggerCollision(double touchX, double touchY) {
    // Untuk trigger, kita bisa menggunakan rectangle collision
    // tapi dengan perhitungan nilai analog berdasarkan posisi Y
    if (!_checkRectCollision(touchX, touchY)) return false;

    // Kalau isAnalog true, kita bisa menghitung nilai analognya
    if (isAnalog) {
      final actualHeight = height > 0 ? height : width;
      final progress = (touchY - y) / actualHeight;
      return progress >= deadzone;
    }

    return true;
  }

  // Method untuk mendapatkan nilai analog dari posisi touch
  double getAnalogValue(double touchX, double touchY) {
    if (!isAnalog) return 1.0;

    switch (shape) {
      default:
        return 1.0; // Default untuk tombol digital
    }
  }

  // Helper untuk mendapatkan center point tombol
  Map<String, double> get center {
    final actualHeight = height > 0 ? height : width;
    return {
      'x': x + width / 2,
      'y': y + actualHeight / 2,
    };
  }

  ButtonLayout copyWith({
    String? newId,
    double? newX,
    double? newY,
    ButtonShape? newShape,
    String? newLabel,
    double? newWidth,
    double? newHeight,
    double? newAngle,
    double? newSensitivity,
    double? newDeadzone,
    bool? newIsAnalog,
    double? newCornerRadius,
    bool? newHapticFeedback,
  }) {
    return ButtonLayout(
      id: newId ?? id,
      x: newX ?? x,
      y: newY ?? y,
      shape: newShape ?? shape,
      label: newLabel ?? label,
      width: newWidth ?? width,
      height: newHeight ?? height,
      angle: newAngle ?? angle,
      sensitivity: newSensitivity ?? sensitivity,
      deadzone: newDeadzone ?? deadzone,
      isAnalog: newIsAnalog ?? isAnalog,
      cornerRadius: newCornerRadius ?? cornerRadius,
      hapticFeedback: newHapticFeedback ?? hapticFeedback,
    );
  }
}
