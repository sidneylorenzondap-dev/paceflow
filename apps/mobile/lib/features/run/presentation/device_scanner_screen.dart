import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/ble_service.dart';

class DeviceScannerScreen extends ConsumerStatefulWidget {
  const DeviceScannerScreen({super.key});

  @override
  ConsumerState<DeviceScannerScreen> createState() => _DeviceScannerScreenState();
}

class _DeviceScannerScreenState extends ConsumerState<DeviceScannerScreen> {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(bleProvider.notifier).startScan();
      });
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      // ignore: invalid_use_of_visible_for_testing_member
      ref.read(bleProvider.notifier).stopScan();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Container(
        height: 400,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bluetooth_disabled_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Not Supported on Web',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bluetooth Heart Rate Monitors can only be connected when running Paceflow as a native Android or iOS app.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            )
          ],
        ),
      );
    }

    final state = ref.watch(bleProvider);
    final notifier = ref.read(bleProvider.notifier);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sensors',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (state.isScanning)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => notifier.startScan(),
                  ),
              ],
            ),
          ),
          
          if (state.connectedDevice != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Card(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Theme.of(context).colorScheme.primary),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.favorite, color: Colors.red),
                  title: Text(state.connectedDevice!.platformName),
                  subtitle: Text('Connected • ${state.currentHeartRate} BPM'),
                  trailing: TextButton(
                    onPressed: () => notifier.disconnect(),
                    child: const Text('Disconnect'),
                  ),
                ),
              ),
            ),
            
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: state.scanResults.length,
              itemBuilder: (context, index) {
                final result = state.scanResults[index];
                if (state.connectedDevice?.remoteId == result.device.remoteId) {
                  return const SizedBox.shrink(); // Don't show connected device in the list
                }
                
                return ListTile(
                  leading: const Icon(Icons.bluetooth),
                  title: Text(result.device.platformName),
                  subtitle: Text(result.device.remoteId.toString()),
                  trailing: ElevatedButton(
                    onPressed: () => notifier.connectToDevice(result.device),
                    child: const Text('Connect'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
