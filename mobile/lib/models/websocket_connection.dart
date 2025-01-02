import 'package:buana_vpad/enums/connection_status.dart';

class WebSocketConnection {
  final String deviceId; // untuk identifikasi unik tiap controller
  final String serverUrl; // contoh: "ws://192.168.1.10:8080"
  final ConnectionStatus status;
  final String? errorMessage;
  final DateTime? lastConnected;
  final String? deviceName; // nama device untuk display (optional)

  WebSocketConnection({
    required this.deviceId,
    required this.serverUrl,
    this.status = ConnectionStatus.disconnected,
    this.errorMessage,
    this.lastConnected,
    this.deviceName,
  });

  // Helper untuk update status
  WebSocketConnection copyWith({
    String? deviceId,
    String? serverUrl,
    ConnectionStatus? status,
    String? errorMessage,
    DateTime? lastConnected,
    String? deviceName,
  }) {
    return WebSocketConnection(
      deviceId: deviceId ?? this.deviceId,
      serverUrl: serverUrl ?? this.serverUrl,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      lastConnected: lastConnected ?? this.lastConnected,
      deviceName: deviceName ?? this.deviceName,
    );
  }
}
