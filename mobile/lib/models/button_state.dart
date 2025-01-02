class ButtonState {
  final String id;
  final bool isPressed;
  final double value;      // 0.0 - 1.0 untuk tombol analog
  final DateTime timestamp;

  ButtonState({
    required this.id,
    required this.isPressed,
    this.value = 1.0,     // default full press untuk digital
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  // Helper untuk analog
  bool get isFullyPressed => value >= 0.95;
  bool get isPartiallyPressed => isPressed && value < 0.95;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isPressed': isPressed,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}