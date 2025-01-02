class DPadState {
  final bool upPressed;
  final bool rightPressed;
  final bool downPressed;
  final bool leftPressed;
  final DateTime timestamp;

  DPadState({
    this.upPressed = false,
    this.rightPressed = false,
    this.downPressed = false,
    this.leftPressed = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  // Helper untuk cek diagonal press
  bool get isUpRight => upPressed && rightPressed;
  bool get isUpLeft => upPressed && leftPressed;
  bool get isDownRight => downPressed && rightPressed;
  bool get isDownLeft => downPressed && leftPressed;

  // Helper untuk mendapatkan current direction dalam string
  String? get currentDirection {
    if (isUpRight) return 'upright';
    if (isUpLeft) return 'upleft';
    if (isDownRight) return 'downright';
    if (isDownLeft) return 'downleft';
    if (upPressed) return 'up';
    if (rightPressed) return 'right';
    if (downPressed) return 'down';
    if (leftPressed) return 'left';
    return null;
  }

  // Method untuk update state
  DPadState copyWith({
    bool? newUpPressed,
    bool? newRightPressed,
    bool? newDownPressed,
    bool? newLeftPressed,
  }) {
    return DPadState(
      upPressed: newUpPressed ?? upPressed,
      rightPressed: newRightPressed ?? rightPressed,
      downPressed: newDownPressed ?? downPressed,
      leftPressed: newLeftPressed ?? leftPressed,
    );
  }

  // Method untuk update specific direction
  DPadState updateDirection(String direction, bool isPressed) {
    switch (direction) {
      case 'up':
        return copyWith(newUpPressed: isPressed);
      case 'right':
        return copyWith(newRightPressed: isPressed);
      case 'down':
        return copyWith(newDownPressed: isPressed);
      case 'left':
        return copyWith(newLeftPressed: isPressed);
      default:
        return this;
    }
  }

  // Method untuk reset semua direction
  DPadState clearAll() {
    return DPadState(
      upPressed: false,
      rightPressed: false,
      downPressed: false,
      leftPressed: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'upPressed': upPressed,
      'rightPressed': rightPressed,
      'downPressed': downPressed,
      'leftPressed': leftPressed,
      'currentDirection': currentDirection,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}