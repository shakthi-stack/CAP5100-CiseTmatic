import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleManager {
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  // Stream subscription for scanning
  StreamSubscription<DiscoveredDevice>? _scanSubscription;

  // Stream subscription for device connection
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;

  // Start scanning for BLE devices.
  void startScan(void Function(DiscoveredDevice device) onDeviceFound) {
    _scanSubscription?.cancel();
    _scanSubscription = _ble.scanForDevices(
      withServices: [], // You can filter by service UUIDs if needed.
      scanMode: ScanMode.lowLatency,
    ).listen((device) {
      onDeviceFound(device);
    }, onError: (error) {
      print("Scan error: $error");
    });
  }

  // Stop scanning
  void stopScan() {
    _scanSubscription?.cancel();
    _scanSubscription = null;
  }

  // Connect to a device by its ID.
  void connectToDevice(String deviceId, void Function(ConnectionStateUpdate) onConnectionUpdate) {
    _connectionSubscription = _ble.connectToDevice(
      id: deviceId,
      connectionTimeout: const Duration(seconds: 5),
    ).listen((update) {
      onConnectionUpdate(update);
    }, onError: (error) {
      print("Connection error: $error");
    });
  }

  // Disconnect from device.
  void disconnect() {
    _connectionSubscription?.cancel();
  }

  // Subscribe to a characteristic.
  //In a real heart rate monitor subscribe to > Heart Rate Measurement characteristic ( UUID 0x2A37 in the Heart Rate Service)
  Stream<List<int>> subscribeToCharacteristic({
    required String deviceId,
    required Uuid serviceUuid,
    required Uuid characteristicUuid,
  }) {
    final characteristic = QualifiedCharacteristic(
      deviceId: deviceId,
      serviceId: serviceUuid,
      characteristicId: characteristicUuid,
    );
    return _ble.subscribeToCharacteristic(characteristic);
  }
}
