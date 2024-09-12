import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Bluetooth Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BluetoothApp(),
    );
  }
}

class BluetoothApp extends StatefulWidget {
  @override
  _BluetoothAppState createState() => _BluetoothAppState();
}

class _BluetoothAppState extends State<BluetoothApp> {
  BluetoothDevice? _selectedDevice;
  BluetoothConnection? _connection;
  bool isConnected = false;
  String receivedData = '';
  List<BluetoothDevice> _devices = [];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    // Meminta izin yang diperlukan
    if (await Permission.bluetooth.isDenied ||
        await Permission.bluetoothScan.isDenied ||
        await Permission.bluetoothConnect.isDenied ||
        await Permission.location.isDenied) {
      await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();
    }

    // Jika izin sudah diberikan, mulai pencarian perangkat Bluetooth
    if (await Permission.bluetoothConnect.isGranted) {
      _discoverDevices();
    }
  }

  Future<void> _discoverDevices() async {
    // Menemukan perangkat yang dipasangkan
    List<BluetoothDevice> devices =
        await FlutterBluetoothSerial.instance.getBondedDevices();

    setState(() {
      _devices = devices; // Menyimpan perangkat yang ditemukan
    });

    if (_devices.isEmpty) {
      print("No paired devices found");
    } else {
      print("Devices found: ${_devices.length}");
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      BluetoothConnection connection =
          await BluetoothConnection.toAddress(device.address);
      setState(() {
        _connection = connection;
        isConnected = true;
        _selectedDevice = device;
      });

      _connection!.input!.listen((data) {
        setState(() {
          receivedData = String.fromCharCodes(data);
        });
      });

      print('Connected to ${device.name}');
    } catch (e) {
      print('Cannot connect, exception occurred: $e');
    }
  }

  Future<void> _disconnectFromDevice() async {
    if (_connection != null) {
      await _connection!.close();
      setState(() {
        _connection = null;
        isConnected = false;
        _selectedDevice = null;
        receivedData = '';
      });
      print('Disconnected');
    }
  }

  @override
  void dispose() {
    _disconnectFromDevice(); // Memutuskan koneksi saat widget dihapus
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bluetooth ESP32 Communication')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Received Data: $receivedData'),
            SizedBox(height: 16.0),
            Text(
              'Select a Bluetooth Device to Connect:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            DropdownButton<BluetoothDevice>(
              value: _selectedDevice,
              hint: Text('Select a device'),
              isExpanded: true,
              items: _devices.map((BluetoothDevice device) {
                return DropdownMenuItem<BluetoothDevice>(
                  value: device,
                  child: Text(device.name ?? 'Unknown Device'),
                );
              }).toList(),
              onChanged: (BluetoothDevice? newValue) {
                if (newValue != null) {
                  _connectToDevice(newValue);
                }
              },
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: isConnected ? _disconnectFromDevice : _discoverDevices,
              child: Text(isConnected
                  ? 'Disconnect from ${_selectedDevice?.name}'
                  : 'Refresh Device List'),
            ),
          ],
        ),
      ),
    );
  }
}
