import 'dart:async';
import 'dart:io';

class PCDevice {
  final String name;
  final String ip;
  final int port;
  final String identifier;

  PCDevice({
    required this.name,
    required this.ip,
    required this.port,
    required this.identifier,
  });

  // Ubah untuk terima String IP
  factory PCDevice.fromMessage(String message, String address) {
    final parts = message.split('|');
    return PCDevice(
      name: parts[0],
      ip: address,
      port: int.parse(parts[1]),
      identifier: parts[2],
    );
  }
}

class NetworkScanner {
  final int broadcastPort;
  
  RawDatagramSocket? _socket;
  StreamController<List<PCDevice>>? _devicesController;
  Set<String> _discoveredDevices = {};
  Timer? _scanTimer;

  NetworkScanner({this.broadcastPort = 8081});

  Future<Stream<List<PCDevice>>> startScan() async {
    _devicesController = StreamController<List<PCDevice>>();
    _discoveredDevices.clear();
    print("Clear previous devices...");
    try {
      // Bind ke '0.0.0.0' langsung sebagai String
      _socket = await RawDatagramSocket.bind('0.0.0.0', broadcastPort);
      print("Binding to 0.0.0.0");
      _socket!.broadcastEnabled = true;

      _socket!.listen((RawSocketEvent event) {
        print("Socket event received: $event");
        if (event == RawSocketEvent.read) {
          final datagram = _socket!.receive();
          if (datagram != null) {
            final message = String.fromCharCodes(datagram.data);
            try {
              final device = PCDevice.fromMessage(message, datagram.address.address);
              if (!_discoveredDevices.contains(device.identifier)) {
                _discoveredDevices.add(device.identifier);
                _devicesController?.add(_discoveredDevices
                    .map((id) => PCDevice.fromMessage(message, datagram.address.address))
                    .toList());
              }
            } catch (e) {
              print('Error parsing device message: $e');
            }
          }
        }
      });

      _scanTimer = Timer(const Duration(seconds: 5), () {
        stopScan();
      });

      return _devicesController!.stream;
    } catch (e) {
      _devicesController?.close();
      throw Exception('Failed to start network scan: $e');
    }
  }

  void stopScan() {
    _socket?.close();
    _socket = null;
    _scanTimer?.cancel();
    _scanTimer = null;
    _devicesController?.close();
    _devicesController = null;
  }
}