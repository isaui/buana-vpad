import 'dart:ui';

import 'package:buana_vpad/enums/button_shape.dart';
import 'package:buana_vpad/models/controller_layout.dart';
import 'package:buana_vpad/models/dpad_layout.dart';
import 'package:buana_vpad/models/joystick_layout.dart';

class LayoutPercentage {
  final double screenWidth;
  final double screenHeight;

  LayoutPercentage({
    required this.screenWidth,
    required this.screenHeight,
  });

  static ControllerLayout convertLayoutToCurrentScreen(
      ControllerLayout originalLayout, Size currentScreenSize) {
    final originalPercentage = LayoutPercentage(
      screenWidth: originalLayout.width,
      screenHeight: originalLayout.height,
    );

    final currentPercentage = LayoutPercentage(
      screenWidth: currentScreenSize.width,
      screenHeight: currentScreenSize.height,
    );

    // Convert buttons berdasarkan shape
    final convertedButtons = originalLayout.buttons.map((key, button) {
      if (button.shape == ButtonShape.circle) {
        final percentages = originalPercentage.getSquarePercentageLayout(
            button.x, button.y, button.width);

        final newAbsolute = currentPercentage.getAbsoluteSquareLayout(
            percentages['x']!, percentages['y']!, percentages['size']!);

        return MapEntry(
          key,
          button.copyWith(
            newX: newAbsolute['x'],
            newY: newAbsolute['y'],
            newWidth: newAbsolute['size'],
          ),
        );
      } else {
        final percentages = originalPercentage.getRectPercentageLayout(
            button.x, button.y, button.width, button.height);

        final newAbsolute = currentPercentage.getAbsoluteRectLayout(
            percentages['x']!,
            percentages['y']!,
            percentages['width']!,
            percentages['height']!);

        return MapEntry(
          key,
          button.copyWith(
            newX: newAbsolute['x'],
            newY: newAbsolute['y'],
            newWidth: newAbsolute['width'],
            newHeight: newAbsolute['height'],
          ),
        );
      }
    });

    // Convert Joysticks
    JoystickLayout? convertedLeftJoystick;
    if (originalLayout.leftJoystick != null) {
      final leftPercentages = originalPercentage.getSquarePercentageLayout(
          originalLayout.leftJoystick!.x,
          originalLayout.leftJoystick!.y,
          originalLayout.leftJoystick!.outerSize);

      final newLeftAbsolute = currentPercentage.getAbsoluteSquareLayout(
          leftPercentages['x']!,
          leftPercentages['y']!,
          leftPercentages['size']!);

      convertedLeftJoystick = originalLayout.leftJoystick!.copyWith(
        newX: newLeftAbsolute['x'],
        newY: newLeftAbsolute['y'],
        newOuterSize: newLeftAbsolute['size'],
        newInnerSize:
            newLeftAbsolute['size']! * 0.4, // Maintain inner/outer ratio
      );
    }

    JoystickLayout? convertedRightJoystick;
    if (originalLayout.rightJoystick != null) {
      final rightPercentages = originalPercentage.getSquarePercentageLayout(
          originalLayout.rightJoystick!.x,
          originalLayout.rightJoystick!.y,
          originalLayout.rightJoystick!.outerSize);

      final newRightAbsolute = currentPercentage.getAbsoluteSquareLayout(
          rightPercentages['x']!,
          rightPercentages['y']!,
          rightPercentages['size']!);

      convertedRightJoystick = originalLayout.rightJoystick!.copyWith(
        newX: newRightAbsolute['x'],
        newY: newRightAbsolute['y'],
        newOuterSize: newRightAbsolute['size'],
        newInnerSize: newRightAbsolute['size']! * 0.4,
      );
    }

    // Convert DPad
    DPadLayout? convertedDPad;
    if (originalLayout.dpadLayout != null) {
      final dpadPercentages = originalPercentage.getSquarePercentageLayout(
          originalLayout.dpadLayout!.centerX -
              (originalLayout.dpadLayout!.size / 2),
          originalLayout.dpadLayout!.centerY -
              (originalLayout.dpadLayout!.size / 2),
          originalLayout.dpadLayout!.size);

      final newDPadAbsolute = currentPercentage.getAbsoluteSquareLayout(
          dpadPercentages['x']!,
          dpadPercentages['y']!,
          dpadPercentages['size']!);

      convertedDPad = originalLayout.dpadLayout!.copyWith(
        newCenterX: newDPadAbsolute['x']! + (newDPadAbsolute['size']! / 2),
        newCenterY: newDPadAbsolute['y']! + (newDPadAbsolute['size']! / 2),
        newSize: newDPadAbsolute['size'],
      );
    }

    return originalLayout.copyWith(
        newWidth: currentScreenSize.width,
        newHeight: currentScreenSize.height,
        newButtons: convertedButtons,
        newLeftJoystick: convertedLeftJoystick,
        newRightJoystick: convertedRightJoystick,
        newDPadLayout: convertedDPad);
  }

  // Position methods (tetap sama)
  double getXPercent(double absoluteX) {
    return (absoluteX / screenWidth) * 100;
  }

  double getAbsoluteX(double percentX) {
    return (percentX / 100) * screenWidth;
  }

  double getYPercent(double absoluteY) {
    return (absoluteY / screenHeight) * 100;
  }

  double getAbsoluteY(double percentY) {
    return (percentY / 100) * screenHeight;
  }

  // Width dan height methods
  double getWidthPercent(double absoluteWidth) {
    return (absoluteWidth / screenWidth) * 100;
  }

  double getAbsoluteWidth(double percentWidth) {
    return (percentWidth / 100) * screenWidth;
  }

  double getHeightPercent(double absoluteHeight) {
    return (absoluteHeight / screenHeight) * 100;
  }

  double getAbsoluteHeight(double percentHeight) {
    return (percentHeight / 100) * screenHeight;
  }

  // Size methods (untuk komponan yang square/circle)
  double getSizePercent(double absoluteSize) {
    double smallestScreenDimension =
        screenWidth < screenHeight ? screenWidth : screenHeight;
    return (absoluteSize / smallestScreenDimension) * 100;
  }

  double getAbsoluteSize(double percentSize) {
    double smallestScreenDimension =
        screenWidth < screenHeight ? screenWidth : screenHeight;
    return (percentSize / 100) * smallestScreenDimension;
  }

  // Helper untuk rectangle components (buttons, etc)
  Map<String, double> getRectPercentageLayout(
      double x, double y, double width, double height) {
    return {
      'x': getXPercent(x),
      'y': getYPercent(y),
      'width': getWidthPercent(width),
      'height': getHeightPercent(height)
    };
  }

  // Helper untuk square/circle components (joystick, dpad)
  Map<String, double> getSquarePercentageLayout(
      double x, double y, double size) {
    return {
      'x': getXPercent(x),
      'y': getYPercent(y),
      'size': getSizePercent(size)
    };
  }

  // Convert rectangle percentage ke absolute
  Map<String, double> getAbsoluteRectLayout(double xPercent, double yPercent,
      double widthPercent, double heightPercent) {
    return {
      'x': getAbsoluteX(xPercent),
      'y': getAbsoluteY(yPercent),
      'width': getAbsoluteWidth(widthPercent),
      'height': getAbsoluteHeight(heightPercent)
    };
  }

  // Convert square/circle percentage ke absolute
  Map<String, double> getAbsoluteSquareLayout(
      double xPercent, double yPercent, double sizePercent) {
    return {
      'x': getAbsoluteX(xPercent),
      'y': getAbsoluteY(yPercent),
      'size': getAbsoluteSize(sizePercent)
    };
  }

  // Maintain aspect ratio saat resize
  Map<String, double> getMaintainedAspectRatio(
      double width, double height, double newWidth) {
    double aspectRatio = width / height;
    double newHeight = newWidth / aspectRatio;
    return {'width': newWidth, 'height': newHeight};
  }

  // Clamp dan validasi
  bool isWithinBounds(double xPercent, double yPercent) {
    return xPercent >= 0 && xPercent <= 100 && yPercent >= 0 && yPercent <= 100;
  }

  double clampPercent(double value) {
    return value.clamp(0.0, 100.0);
  }

  double get aspectRatio => screenWidth / screenHeight;
}
