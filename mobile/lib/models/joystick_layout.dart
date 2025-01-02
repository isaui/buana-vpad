import 'dart:math';

class JoystickLayout {
  final double x;           
  final double y;          
  final double outerSize;   
  final double innerSize;   
  final double deadzone;    
  final double maxDistance;
  final bool isDraggable;   
  final bool isFixed;       
  final bool hapticEnabled;

  JoystickLayout({
    required this.x,
    required this.y,
    this.outerSize = 150.0,
    this.innerSize = 50.0,
    this.deadzone = 0.1,
    this.maxDistance = 1.0,
    this.isDraggable = false,
    this.isFixed = false,
    this.hapticEnabled = true,
  });

  // Copy with method untuk membuat instance baru dengan beberapa perubahan
  JoystickLayout copyWith({
    double? newX,
    double? newY,
    double? newOuterSize,
    double? newInnerSize,
    double? newDeadzone,
    double? newMaxDistance,
    bool? newIsDraggable,
    bool? newIsFixed,
    bool? newHapticEnabled,
  }) {
    return JoystickLayout(
      x: newX ?? x,
      y: newY ?? y,
      outerSize: newOuterSize ?? outerSize,
      innerSize: newInnerSize ?? innerSize,
      deadzone: newDeadzone ?? deadzone,
      maxDistance: newMaxDistance ?? maxDistance,
      isDraggable: newIsDraggable ?? isDraggable,
      isFixed: newIsFixed ?? isFixed,
      hapticEnabled: newHapticEnabled ?? hapticEnabled,
    );
  }

  // Cek apakah touch point dalam area joystick
  bool containsPoint(double touchX, double touchY) {
    final radius = outerSize / 2;
    final dx = touchX - (x + radius);
    final dy = touchY - (y + radius);
    return (dx * dx + dy * dy) <= radius * radius;
  }

  // Get nilai dx, dy dari posisi touch (-1.0 sampai 1.0)
 Map<String, double> getJoystickValues(double touchX, double touchY) {
    // Dapat posisi lokal relatif terhadap joystick
    final localX = touchX;  // touchX sudah dalam koordinat lokal widget
    final localY = touchY;
    
    // Center adalah selalu tengah dari outer circle
    final center = outerSize / 2;
    
    // Hitung delta dari center
    final dx = localX - center;
    final dy = localY - center;
    
    print('Touch Local: ($localX, $localY)');
    print('Center Local: ($center, $center)');
    print('Delta: ($dx, $dy)');
    
    // Hitung jarak
    final distance = sqrt(dx * dx + dy * dy);
    if (distance == 0) {
        return {'dx': 0, 'dy': 0};
    }
    
    // Normalisasi ke -1 sampai 1
    var normalizedDx = dx / center;
    var normalizedDy = dy / center;
    
    // Batasi ke maxDistance jika perlu
    final normalizedDistance = sqrt(normalizedDx * normalizedDx + normalizedDy * normalizedDy);
    if (normalizedDistance > maxDistance) {
        final scale = maxDistance / normalizedDistance;
        normalizedDx *= scale;
        normalizedDy *= scale;
    }
    
    return {
        'dx': normalizedDx,
        'dy': normalizedDy
    };
}
  // Helper untuk mendapatkan center point
  Map<String, double> get center {
    return {
      'x': x + outerSize / 2,
      'y': y + outerSize / 2,
    };
  }
}