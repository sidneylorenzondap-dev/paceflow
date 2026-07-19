import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/ble_service.dart';
import '../../../core/ui/neo_brutalist_container.dart';
import '../../../core/ui/responsive_layout.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildRadarOverview(),
                const SizedBox(height: 32),
                _buildHardwareListHeader(),
                const SizedBox(height: 16),
                _buildHardwareList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0E0E10),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'HARDWARE SETUP',
            style: TextStyle(color: Color(0xFFFC4C02), fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 11),
          ),
          SizedBox(height: 4),
          Text(
            'DEVICE SCANNER',
            style: TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 32),
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left Column: Radar Overview
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'LIVE TELEMETRY',
                              style: TextStyle(color: Color(0xFFFC4C02), fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 10),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'RADAR OVERVIEW',
                              style: TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 20),
                            ),
                            const SizedBox(height: 16),
                            Expanded(child: _buildRadarOverview()),
                          ],
                        ),
                      ),
                      const SizedBox(width: 40),
                      // Right Column: Hardware List
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHardwareListHeader(),
                            const SizedBox(height: 16),
                            Expanded(
                              child: SingleChildScrollView(
                                child: _buildHardwareList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopHeader(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HARDWARE SETUP',
          style: TextStyle(color: Color(0xFFFC4C02), fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 11),
        ),
        SizedBox(height: 4),
        Text(
          'DEVICE SCANNER',
          style: TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 32),
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
          _buildDesktopSidebarItem(context, Icons.crop_square, 'DASHBOARD', '/dashboard', false),
          const SizedBox(height: 16),
          _buildDesktopSidebarItem(context, Icons.crop_square, 'PLAN', '/training', false),
          const SizedBox(height: 16),
          _buildDesktopSidebarItem(context, Icons.circle, 'LIVE RUN', '/dashboard', true, iconSize: 10),
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

  // --- CONTENT BUILDER ---

  Widget _buildRadarOverview() {
    return Container(
      constraints: const BoxConstraints(minHeight: 250),
      decoration: BoxDecoration(
        color: const Color(0xFF18181C), // Slightly lighter than background
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
      ),
      child: Stack(
        children: [
          // The background grid lines
          Column(
            children: [
              Expanded(child: Container(decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF2C2C2E), width: 1))))),
              Expanded(child: Container(decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF2C2C2E), width: 1))))),
              Expanded(child: Container()),
            ],
          ),
          // Custom radar graphics
          Positioned.fill(
            child: CustomPaint(
              painter: RadarPainter(),
            ),
          ),
          // The Top Left Badge
          Positioned(
            top: 24,
            left: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF18181C),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: const Text('BLUETOOTH RX ACTIVE //', style: TextStyle(color: Color(0xFFCCFF00), fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHardwareListHeader() {
    final state = ref.watch(bleProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'DISCOVERED HARDWARE',
          style: TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 14),
        ),
        if (state.isScanning && !kIsWeb)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFCCFF00)),
          ),
      ],
    );
  }

  Widget _buildHardwareList() {
    final state = ref.watch(bleProvider);
    final notifier = ref.read(bleProvider.notifier);

    // MOCK DATA for Web or if no devices found
    if (kIsWeb || (state.scanResults.isEmpty && !state.isScanning)) {
      return Column(
        children: [
          _buildDeviceCard(
            name: 'POLAR H10',
            mac: '00:22:A3:89:C1:2F',
            badgeText: 'HR MONITOR',
            rssiText: 'RSSI: STRONG',
            isConnected: true,
            onTap: () {}, // Mock
          ),
          const SizedBox(height: 16),
          _buildDeviceCard(
            name: 'STRYD POD',
            mac: '00:88:F2:A3:BC:11',
            badgeText: 'POWER METRIC',
            rssiText: 'RSSI: STABLE',
            isConnected: false,
            onTap: () {}, // Mock
          ),
          const SizedBox(height: 16),
          _buildDeviceCard(
            name: 'COROS PACE 3',
            mac: '14:AA:2F:3C:D9:AA',
            badgeText: 'SPORTS WATCH',
            rssiText: 'RSSI: WEAK',
            isConnected: false,
            onTap: () {}, // Mock
          ),
        ],
      );
    }

    // REAL DATA
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: state.scanResults.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final result = state.scanResults[index];
        final isConnected = state.connectedDevice?.remoteId == result.device.remoteId;
        
        return _buildDeviceCard(
          name: result.device.platformName.isEmpty ? 'UNKNOWN DEVICE' : result.device.platformName.toUpperCase(),
          mac: result.device.remoteId.toString(),
          badgeText: 'BLUETOOTH LE', // Generic badge for real unknown devices
          rssiText: 'RSSI: ${result.rssi}',
          isConnected: isConnected,
          onTap: () {
            if (isConnected) {
              notifier.disconnect();
            } else {
              notifier.connectToDevice(result.device);
            }
          },
        );
      },
    );
  }

  Widget _buildDeviceCard({
    required String name,
    required String mac,
    required String badgeText,
    required String rssiText,
    required bool isConnected,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF18181C),
        border: Border.all(color: Colors.black, width: 3),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'MAC: $mac',
                      style: const TextStyle(color: Color(0xFF8E8E93), fontFamily: 'Geist', fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181C),
                  border: Border.all(color: const Color(0xFFCCFF00), width: 1.5),
                ),
                child: Text(badgeText, style: const TextStyle(color: Color(0xFFCCFF00), fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 9)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                rssiText,
                style: const TextStyle(color: Color(0xFF8E8E93), fontFamily: 'Geist', fontSize: 11, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isConnected ? const Color(0xFFCCFF00) : const Color(0xFF18181C),
                    border: Border.all(color: Colors.black, width: 2),
                    boxShadow: !isConnected ? const [BoxShadow(color: Colors.black, offset: Offset(3, 3))] : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isConnected) ...[
                        const Icon(Icons.circle, color: Colors.black, size: 8),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        isConnected ? 'CONNECTED' : 'CONNECT',
                        style: TextStyle(
                          color: isConnected ? Colors.black : Colors.white,
                          fontFamily: 'Unbounded',
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RadarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Olive/neon green lines mimicking a radar scan
    final paintLine1 = Paint()
      ..color = const Color(0xFFCCFF00) // Neon Green
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final paintLine2 = Paint()
      ..color = const Color(0xFF8A9A5B) // Olive Green
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final paintCircleOrange = Paint()
      ..color = const Color(0xFFFC4C02)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final paintCircleGreen = Paint()
      ..color = const Color(0xFFCCFF00)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw lines
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.9), 
      Offset(size.width * 0.9, size.height * 0.1), 
      paintLine2
    );

    canvas.drawLine(
      Offset(size.width * 0.4, size.height * 0.5), 
      Offset(size.width * 0.85, size.height * 0.8), 
      paintLine1
    );
    
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.9), 
      Offset(size.width * 0.4, size.height * 0.5), 
      paintLine2
    );

    canvas.drawLine(
      Offset(size.width * 0.45, size.height * 0.1), 
      Offset(size.width * 0.35, size.height * 1.0), 
      paintLine1
    );

    // Draw circles (devices)
    canvas.drawCircle(Offset(size.width * 0.28, size.height * 0.65), 10, paintCircleOrange);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.3), 10, paintCircleGreen);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
