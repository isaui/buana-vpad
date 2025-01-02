class DPadLayout {
  final double centerX;
  final double centerY;
  final double size;
  final bool hapticEnabled;

  DPadLayout({
    required this.centerX,
    required this.centerY,
    this.size = 150.0,
    this.hapticEnabled = true,
  });

  // Cek apakah touch point dalam area DPad
  bool containsPoint(double touchX, double touchY) {
    // DPad area adalah sebuah kotak dengan ukuran size x size
    // dengan center di (centerX, centerY)
    final left = centerX - size/2;
    final top = centerY - size/2;
    final right = centerX + size/2;
    final bottom = centerY + size/2;

    return touchX >= left &&
           touchX <= right &&
           touchY >= top &&
           touchY <= bottom;
  }

  DPadLayout copyWith({
    double? newCenterX,
    double? newCenterY,
    double? newSize,
    bool? newHapticEnabled,
  }) {
    return DPadLayout(
      centerX: newCenterX ?? centerX,
      centerY: newCenterY ?? centerY,
      size: newSize ?? size,
      hapticEnabled: newHapticEnabled ?? hapticEnabled,
    );
  }
}