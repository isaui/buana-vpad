# Changelog

All notable changes to the BuanaVPad mobile application will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-01-03

### Added
- Initial release of BuanaVPad mobile application
- Multiple controller layout support with customizable configurations
- Real-time controller input preview
- Controller layout management system
  - Create new layouts
  - Edit existing layouts
  - Delete layouts
  - Save and load layouts
- Network connectivity features
  - PC connection via WiFi
  - Network scanning capability
  - Connection status monitoring
- Debug information panel
  - Input state tracking
  - Connection status
  - Layout ID display
  - Joystick position values
- User interface components
  - Main dashboard
  - Controller layout editor
  - Connection manager
  - Settings panel
- Support for various controller inputs
  - Shoulder buttons (LT, RT, LB, RB)
  - Face buttons (A, B, X, Y)
  - Dual analog sticks
  - Menu buttons
- Visual feedback for button presses
- Layout persistence across app sessions

### Technical Details
- Built with Flutter for Android
- Minimum SDK version: Android 6.0 (API level 23)
- Target SDK version: Android 13 (API level 33)
- Network protocol: WebSocket

### Known Issues
- May experience slight input lag on some devices
- Network scanning might take longer on complex networks
- Debug panel may impact performance when enabled

### Development Notes
- Remote server functionality is under development