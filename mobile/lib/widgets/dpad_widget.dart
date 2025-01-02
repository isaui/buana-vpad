import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:buana_vpad/models/dpad_layout.dart';
import 'package:buana_vpad/models/dpad_state.dart';

class DPadWidget extends StatelessWidget {
  final DPadLayout layout;
  final DPadState? state;
  final Function(String direction, bool isPressed) onDirectionChanged;
  final bool isDraggable;

  const DPadWidget({
    super.key,
    required this.layout,
    this.state,
    required this.onDirectionChanged,
    this.isDraggable = false,
  });

  @override
  Widget build(BuildContext context) {
    // Ubah ke aspect ratio 1:1 untuk bentuk plus yang sempurna
    final dpadContent = Container(
      width: layout.size,
      height: layout.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
      ),
      child: Stack(
        children: [
          // Base DPad paint
          CustomPaint(
            size: Size.square(layout.size),
            painter: CrossPainter(
              upPressed: state?.upPressed ?? false,
              rightPressed: state?.rightPressed ?? false,
              downPressed: state?.downPressed ?? false,
              leftPressed: state?.leftPressed ?? false,
            ),
          ),
          // Touch areas sebagai plus
          _buildDirectionalTouchAreas(),
        ],
      ),
    );

    if (isDraggable) return dpadContent;

    return Positioned(
      left: layout.centerX - layout.size / 2,
      top: layout.centerY - layout.size / 2,
      child: dpadContent,
    );
  }

  Widget _buildDirectionalTouchAreas() {
    return Stack(
      children: [
        // Up
        Align(
          alignment: Alignment.topCenter,
          child: _buildTouchArea(
            width: layout.size * 0.33, // Sesuaikan dengan ukuran cross
            height: layout.size * 0.45,
            direction: 'up',
          ),
        ),
        // Right
        Align(
          alignment: Alignment.centerRight,
          child: _buildTouchArea(
            width: layout.size * 0.45,
            height: layout.size * 0.33,
            direction: 'right',
          ),
        ),
        // Down
        Align(
          alignment: Alignment.bottomCenter,
          child: _buildTouchArea(
            width: layout.size * 0.33,
            height: layout.size * 0.45,
            direction: 'down',
          ),
        ),
        // Left
        Align(
          alignment: Alignment.centerLeft,
          child: _buildTouchArea(
            width: layout.size * 0.45,
            height: layout.size * 0.33,
            direction: 'left',
          ),
        ),
      ],
    );
  }

  Widget _buildTouchArea({
    required double width,
    required double height,
    required String direction,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: GestureDetector(
        onTapDown: (_) {
          onDirectionChanged(direction, true);
          if (layout.hapticEnabled) {
            HapticFeedback.lightImpact();
          }
        },
        onTapUp: (_) => onDirectionChanged(direction, false),
        onTapCancel: () => onDirectionChanged(direction, false),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}

class CrossPainter extends CustomPainter {
  final bool upPressed;
  final bool rightPressed;
  final bool downPressed;
  final bool leftPressed;

  CrossPainter({
    this.upPressed = false,
    this.rightPressed = false,
    this.downPressed = false,
    this.leftPressed = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Warna biru yang lebih solid seperti di gambar
    final basePaint = Paint()
      ..color = const Color(0xFF1E4B82) // Warna biru PS4-like
      ..style = PaintingStyle.fill;

    final pressedPaint = Paint()
      ..color = Colors.blue[700]!
      ..style = PaintingStyle.fill;

    // Buat plus shape yang lebih tight dan sharp
    final crossPath = Path();

    // Ukuran yang lebih proporsional
    final armWidth = size.width * 0.25; // Lebih tipis
    final armLength = size.width * 0.35; // Sedikit lebih pendek

    // Helper untuk membuat sharp edges dengan radius minimal
    void addArm(double startX, double startY, double width, double height) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(startX, startY),
          width: width,
          height: height,
        ),
        const Radius.circular(2), // Radius sangat kecil untuk sharp look
      );
      crossPath.addRRect(rect);
    }

    // Vertical dan horizontal arms dengan gap yang minimal
    addArm(
        center.dx, center.dy - armLength / 2, armWidth, armLength); // Up-Down
    addArm(center.dx, center.dy + armLength / 2, armWidth, armLength);
    addArm(center.dx - armLength / 2, center.dy, armLength,
        armWidth); // Left-Right
    addArm(center.dx + armLength / 2, center.dy, armLength, armWidth);

    // Subtle shadow
    canvas.drawPath(
        crossPath.shift(const Offset(0, 1)),
        Paint()
          ..color = Colors.black.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));

    // Draw base cross
    canvas.drawPath(crossPath, basePaint);

    // Center circle yang lebih kecil dan sharp
    canvas.drawCircle(
      center,
      armWidth * 0.25, // Jauh lebih kecil
      Paint()..color = const Color(0xFF1E4B82), // Sama dengan warna base
    );

    // Handle pressed states
    if (upPressed)
      _drawPressedArm(canvas, 'up', center, armWidth, armLength, pressedPaint);
    if (rightPressed)
      _drawPressedArm(
          canvas, 'right', center, armWidth, armLength, pressedPaint);
    if (downPressed)
      _drawPressedArm(
          canvas, 'down', center, armWidth, armLength, pressedPaint);
    if (leftPressed)
      _drawPressedArm(
          canvas, 'left', center, armWidth, armLength, pressedPaint);
  }

  void _drawPressedArm(Canvas canvas, String direction, Offset center,
      double armWidth, double armLength, Paint paint) {
    final pressedPath = Path();
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: switch (direction) {
          'up' => Offset(center.dx, center.dy - armLength / 2),
          'right' => Offset(center.dx + armLength / 2, center.dy),
          'down' => Offset(center.dx, center.dy + armLength / 2),
          'left' => Offset(center.dx - armLength / 2, center.dy),
          String() => center,
        },
        width:
            direction == 'left' || direction == 'right' ? armLength : armWidth,
        height: direction == 'up' || direction == 'down' ? armLength : armWidth,
      ),
      const Radius.circular(2),
    );
    pressedPath.addRRect(rect);
    canvas.drawPath(pressedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
