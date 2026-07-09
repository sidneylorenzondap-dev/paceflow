import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BleState {
  final bool isScanning;
  final List<ScanResult> scanResults;
  final BluetoothDevice? connectedDevice;
  final int currentHeartRate;
  
  BleState({
    this.isScanning = false,
    this.scanResults = const [],
    this.connectedDevice,
    this.currentHeartRate = 0,
  });

  BleState copyWith({
    bool? isScanning,
    List<ScanResult>? scanResults,
    BluetoothDevice? connectedDevice,
    int? currentHeartRate,
  }) {
    return BleState(
      isScanning: isScanning ?? this.isScanning,
      scanResults: scanResults ?? this.scanResults,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      currentHeartRate: currentHeartRate ?? this.currentHeartRate,
    );
  }
}

class BleNotifier extends Notifier<BleState> {
  StreamSubscription? _scanSubscription;
  StreamSubscription? _hrSubscription;

  @override
  BleState build() {
    return BleState();
  }

  Future<void> startScan() async {
    if (await FlutterBluePlus.isSupported == false) {
      return;
    }
    
    state = state.copyWith(isScanning: true, scanResults: []);
    
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      // Filter for devices that likely have HR or just show all named devices
      final namedResults = results.where((r) => r.device.platformName.isNotEmpty).toList();
      state = state.copyWith(scanResults: namedResults);
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    await Future.delayed(const Duration(seconds: 15));
    stopScan();
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    state = state.copyWith(isScanning: false);
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    await stopScan();
    try {
      await device.connect();
      state = state.copyWith(connectedDevice: device);
      _discoverHeartRateService(device);
    } catch (e) {
      print('Error connecting to device: $e');
    }
  }

  Future<void> disconnect() async {
    if (state.connectedDevice != null) {
      await state.connectedDevice!.disconnect();
      _hrSubscription?.cancel();
      _hrSubscription = null;
      state = state.copyWith(connectedDevice: null, currentHeartRate: 0);
    }
  }

  Future<void> _discoverHeartRateService(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    for (BluetoothService service in services) {
      // Standard HR service UUID is 0x180D
      if (service.uuid.toString().toUpperCase().contains('180D')) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          // Standard HR measurement characteristic is 0x2A37
          if (characteristic.uuid.toString().toUpperCase().contains('2A37')) {
            await characteristic.setNotifyValue(true);
            _hrSubscription = characteristic.lastValueStream.listen((value) {
              if (value.isNotEmpty) {
                // Parse standard BLE HR format
                final flags = value[0];
                final is16Bit = (flags & 0x01) != 0;
                int hr = 0;
                if (is16Bit && value.length >= 3) {
                  hr = (value[2] << 8) | value[1];
                } else if (value.length >= 2) {
                  hr = value[1];
                }
                state = state.copyWith(currentHeartRate: hr);
              }
            });
            break;
          }
        }
      }
    }
  }
}

final bleProvider = NotifierProvider<BleNotifier, BleState>(() {
  return BleNotifier();
});
