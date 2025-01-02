import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:buana_vpad/database/db_helper.dart';
import 'package:buana_vpad/models/controller_layout.dart';
import 'package:buana_vpad/screens/controller_mode_page.dart';
import 'package:buana_vpad/utils/network_scanner.dart';
import 'package:buana_vpad/utils/settings_manager.dart';

class ConnectToPcPage extends StatefulWidget {
  const ConnectToPcPage({super.key});

  @override
  State<ConnectToPcPage> createState() => _ConnectToPcPageState();
}

class _ConnectToPcPageState extends State<ConnectToPcPage> {
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '8080');
  final _networkScanner = NetworkScanner();

  bool _isLoading = true;
  bool _isConnecting = false;
  bool _isConnected = false;
  bool _isScanning = false;
  WebSocket? _socket;
  List<ControllerLayout> _layouts = [];
  ControllerLayout? _selectedLayout;
  List<PCDevice> _discoveredDevices = [];
  StreamSubscription? _scanSubscription;
  String? _deviceId;
  String? _deviceName;

  @override
  void initState() {
    super.initState();
    _loadLayouts();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final deviceId = await SettingsManager.getDeviceId();
    final deviceName = await SettingsManager.getDeviceName();
    setState(() {
      _deviceId = deviceId;
      _deviceName = deviceName;
    });
  }

  Future<void> _loadLayouts() async {
    setState(() => _isLoading = true);
    try {
      final dbHelper = DatabaseHelper();
      final layouts = await dbHelper.getAllControllerLayouts();
      setState(() {
        _layouts = layouts;
        _selectedLayout = layouts.isNotEmpty ? layouts.first : null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading layouts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _selectDevice(PCDevice device) {
    setState(() {
      _ipController.text = device.ip;
      _portController.text = device.port.toString();
    });
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _discoveredDevices = [];
    });

    try {
      final deviceStream = await _networkScanner.startScan();
      _scanSubscription = deviceStream.listen(
        (devices) {
          setState(() => _discoveredDevices = devices);
        },
        onDone: () {
          setState(() => _isScanning = false);
          if (_discoveredDevices.isEmpty) {
            _showNoDevicesFound();
          }
        },
        onError: (error) {
          setState(() => _isScanning = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Scan error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    } catch (e) {
      setState(() => _isScanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start scan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showNoDevicesFound() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No PCs Found'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please make sure:'),
            const SizedBox(height: 8),
            _buildBulletPoint('Virtual Controller app is running on your PC'),
            _buildBulletPoint(
                'PC is connected to the same WiFi/hotspot network'),
            _buildBulletPoint('Try scanning again'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startScan();
            },
            child: const Text('Scan Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  void _stopScan() {
    _scanSubscription?.cancel();
    _networkScanner.stopScan();
    setState(() => _isScanning = false);
  }

  // Validasi format IP
  String? _validateIP(String? value) {
    if (value == null || value.isEmpty) {
      return 'IP address is required';
    }

    final parts = value.split('.');
    if (parts.length != 4) {
      return 'Invalid IP format';
    }

    for (var part in parts) {
      final number = int.tryParse(part);
      if (number == null || number < 0 || number > 255) {
        return 'Invalid IP format';
      }
    }

    return null;
  }

  // Validasi port number
  String? _validatePort(String? value) {
    if (value == null || value.isEmpty) {
      return 'Port is required';
    }

    final port = int.tryParse(value);
    if (port == null || port <= 0 || port > 65535) {
      return 'Port must be between 1 and 65535';
    }

    return null;
  }

  Future<void> _connect() async {
    if (_formKey.currentState!.validate()) {
      // Check device ID dan selected layout
      if (_deviceId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device ID not found. Please restart the app.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_selectedLayout == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a controller layout first'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isConnecting = true);

      try {
        // Connect ke websocket
        _socket = await WebSocket.connect(
                'ws://${_ipController.text}:${_portController.text}/ws/controller/$_deviceId')
            .timeout(const Duration(seconds: 5), onTimeout: () {
          throw 'Connection timeout. Please check if the IP and port are correct.';
        });

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ControllerModePage(
                layout: _selectedLayout!,
                socket: _socket!,
                deviceId: _deviceId!,
                deviceName: _deviceName ?? 'Unknown Device',
                onConnect: () {
                  setState(() {
                    _isConnecting = false;
                    _isConnected = true;
                  });
                },
                onDisconnect: () {
                  _disconnect();
                },
              ),
            ),
          );
        }
      } catch (e) {
        _disconnect();

        String errorMessage = 'Connection failed';
        if (e.toString().contains('timeout')) {
          errorMessage =
              'Connection timeout. Please check if the IP and port are correct.';
        } else if (e.toString().contains('refused')) {
          errorMessage =
              'Connection refused. Please make sure the server is running.';
        } else if (e.toString().contains('network is unreachable')) {
          errorMessage =
              'Network unreachable. Please check your network connection.';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _disconnect() {
    _socket?.close();
    setState(() {
      _isConnecting = false;
      _isConnected = false;
      _socket = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Connect to PC',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.grey[900],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[900]!,
              Colors.grey[850]!,
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Connection Status
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[850],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _isConnected
                                      ? Colors.green
                                      : Colors.grey[800]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _isConnected
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _isConnected
                                        ? 'Connected'
                                        : 'Not Connected',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            // IP Input
                            TextFormField(
                              controller: _ipController,
                              enabled: !_isConnected,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'IP Address',
                                labelStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.7)),
                                hintText: '192.168.1.100',
                                hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.3)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: Colors.blue),
                                ),
                              ),
                              validator: _validateIP,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.]')),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Port Input
                            TextFormField(
                              controller: _portController,
                              enabled: !_isConnected,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Port',
                                labelStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.7)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: Colors.blue),
                                ),
                              ),
                              validator: _validatePort,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Controller Layout Selection
                            if (_layouts.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning,
                                      color: Colors.red.withOpacity(0.8),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'No controller layouts found. Please create one first.',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Select Controller Layout',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[800],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<ControllerLayout>(
                                        value: _selectedLayout,
                                        isExpanded: true,
                                        dropdownColor: Colors.grey[850],
                                        style: const TextStyle(
                                            color: Colors.white),
                                        items: _layouts.map((layout) {
                                          return DropdownMenuItem(
                                            value: layout,
                                            child: Text(layout.name),
                                          );
                                        }).toList(),
                                        onChanged: _isConnected
                                            ? null
                                            : (layout) {
                                                setState(() {
                                                  _selectedLayout = layout;
                                                });
                                              },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 32),

                            // Discovered Devices Section
                            if (_isScanning || _discoveredDevices.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Discovered PCs',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (_isScanning)
                                        const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[850],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                    child: Column(
                                      children:
                                          _discoveredDevices.map((device) {
                                        return ListTile(
                                          title: Text(
                                            device.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${device.ip}:${device.port}',
                                            style: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.7),
                                            ),
                                          ),
                                          trailing: const Icon(
                                            Icons.arrow_forward_ios,
                                            color: Colors.blue,
                                            size: 16,
                                          ),
                                          onTap: () => _selectDevice(device),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ),

                            // Scan Network Button
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: _isConnected ? null : _startScan,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.wifi_find,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Scan Network',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.9),
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_isScanning)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.stop,
                                          color: Colors.red,
                                        ),
                                        onPressed: _stopScan,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Fixed Connect Button at bottom
                  Container(
                    padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      bottom: MediaQuery.of(context).padding.bottom + 24,
                      top: 24,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (_layouts.isEmpty || _isConnecting)
                            ? null
                            : () {
                                if (_isConnected) {
                                  _disconnect();
                                } else {
                                  _connect();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isConnected ? Colors.red : Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isConnecting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(
                                _isConnected ? 'Disconnect' : 'Connect',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _scanSubscription?.cancel();
    _networkScanner.stopScan();
    super.dispose();
  }
}
