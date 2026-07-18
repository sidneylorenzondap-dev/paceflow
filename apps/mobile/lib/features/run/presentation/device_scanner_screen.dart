import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/ble_service.dart';
import '../../../core/ui/neo_brutalist_container.dart';
import '../../../core/ui/responsive_layout.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E10),
      body: SafeArea(
        child: ResponsiveLayout(
          mobile: _buildMobileContent(context),
          desktop: _buildDesktopContent(context),
        ),
      ),
    );
  }

  // --- MOBILE LAYOUT ---

  Widget _buildMobileContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMobileHeader(context),
        Expanded(
          child: _buildScannerContent(isMobile: true),
        ),
      ],
    );
  }

  Widget _buildMobileHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF18181C),
        border: Border(bottom: BorderSide(color: Colors.black, width: 3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
            child: Row(
              children: [
                const Icon(Icons.chevron_left, color: Color(0xFFFC4C02), size: 24),
                const SizedBox(width: 4),
                const Text(
                  'DASHBOARD',
                  style: TextStyle(color: Color(0xFFFC4C02), fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ],
            ),
          ),
          const Text(
            'DEVICE SCANNER',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Unbounded',
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // --- DESKTOP LAYOUT ---

  Widget _buildDesktopContent(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDesktopSidebar(context),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDesktopHeader(context),
                const SizedBox(height: 32),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: _buildScannerContent(isMobile: false),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopSidebar(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF18181C),
        border: Border(right: BorderSide(color: Colors.black, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFCCFF00),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: const Text('PF', style: TextStyle(color: Colors.black, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 16)),
              ),
              const SizedBox(width: 8),
              const Text('PACEFLOW', style: TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 20)),
            ],
          ),
          const SizedBox(height: 48),
          _buildDesktopSidebarItem(context, Icons.crop_square, 'DASHBOARD', '/dashboard', true),
          const SizedBox(height: 16),
          _buildDesktopSidebarItem(context, Icons.crop_square, 'PLAN', '/training', false),
          const SizedBox(height: 16),
          _buildDesktopSidebarItem(context, Icons.circle, 'LIVE RUN', '/dashboard', false, iconSize: 10),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFC4C02),
              border: Border.all(color: Colors.black, width: 3),
              boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PACEFLOW PREMIUM', style: TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 12)),
                SizedBox(height: 12),
                Text('Unlock advanced AI metrics, live ghost pacing & audio recovery engine.', style: TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Geist')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebarItem(BuildContext context, IconData icon, String label, String route, bool isSelected, {double iconSize = 18}) {
    return GestureDetector(
      onTap: () {
        if (!isSelected) context.go(route);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFCCFF00) : Colors.transparent,
          border: isSelected ? Border.all(color: Colors.black, width: 2) : Border.all(color: Colors.transparent, width: 2),
          boxShadow: isSelected ? const [BoxShadow(color: Colors.black, offset: Offset(4, 4))] : [],
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.black : const Color(0xFF8E8E93), size: iconSize),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : const Color(0xFF8E8E93),
                fontFamily: 'Unbounded',
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.go('/dashboard'),
          child: const Text(
            '< DASHBOARD',
            style: TextStyle(color: Color(0xFFFC4C02), fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 14),
          ),
        ),
        const SizedBox(width: 24),
        const Text(
          'DEVICE SCANNER',
          style: TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 24),
        ),
      ],
    );
  }

  // --- CONTENT BUILDER ---

  Widget _buildScannerContent({required bool isMobile}) {
    if (kIsWeb) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF18181C),
            border: Border.all(color: const Color(0xFFFC4C02), width: 4),
            boxShadow: const [BoxShadow(color: Color(0xFFFC4C02), offset: Offset(8, 8))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bluetooth_disabled_rounded, size: 64, color: Color(0xFFFC4C02)),
              const SizedBox(height: 24),
              Text(
                'NOT SUPPORTED ON WEB',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Unbounded',
                  fontWeight: FontWeight.w900,
                  fontSize: isMobile ? 18 : 24,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Bluetooth Heart Rate Monitors can only be connected when running Paceflow as a native Android or iOS app.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8E8E93), fontFamily: 'Geist', fontSize: 16, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    final state = ref.watch(bleProvider);
    final notifier = ref.read(bleProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'PAIR YOUR SENSOR',
            style: TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 32),
          ),
          const SizedBox(height: 8),
          const Text(
            'Supported Devices: Bluetooth Heart Rate Monitors, Footpods.',
            style: TextStyle(color: Color(0xFF8E8E93), fontFamily: 'Geist', fontSize: 16),
          ),
          const SizedBox(height: 32),
          
          if (state.connectedDevice != null) ...[
            const Text('CONNECTED', style: TextStyle(color: Color(0xFFCCFF00), fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 14)),
            const SizedBox(height: 12),
            NeoBrutalistContainer(
              backgroundColor: const Color(0xFF18181C),
              shadowColor: const Color(0xFFCCFF00),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.favorite, color: Color(0xFFFC4C02), size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.connectedDevice!.platformName.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 20),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${state.currentHeartRate} BPM',
                          style: const TextStyle(color: Color(0xFFCCFF00), fontFamily: 'Geist', fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => notifier.disconnect(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: const Text('DISCONNECT', style: TextStyle(color: Colors.black, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('DISCOVERED DEVICES', style: TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 14)),
              if (state.isScanning)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFCCFF00)),
                )
              else
                GestureDetector(
                  onTap: () => notifier.startScan(),
                  child: const Icon(Icons.refresh, color: Color(0xFFCCFF00), size: 24),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (state.scanResults.isEmpty && !state.isScanning)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF8E8E93), width: 2),
                color: Colors.transparent,
              ),
              child: const Text(
                'NO DEVICES FOUND',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8E8E93), fontFamily: 'Unbounded', fontWeight: FontWeight.bold, fontSize: 14),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.scanResults.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final result = state.scanResults[index];
                if (state.connectedDevice?.remoteId == result.device.remoteId) {
                  return const SizedBox.shrink();
                }
                
                return NeoBrutalistContainer(
                  backgroundColor: Colors.white,
                  shadowColor: Colors.black,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.bluetooth, color: Colors.black, size: 24),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result.device.platformName.isEmpty ? 'UNKNOWN DEVICE' : result.device.platformName.toUpperCase(),
                              style: const TextStyle(color: Colors.black, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                            Text(
                              result.device.remoteId.toString(),
                              style: const TextStyle(color: Colors.black54, fontFamily: 'Geist', fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => notifier.connectToDevice(result.device),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFCCFF00),
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: const Text('CONNECT', style: TextStyle(color: Colors.black, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
