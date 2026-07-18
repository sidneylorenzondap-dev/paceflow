import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../training/presentation/saved_plans_screen.dart';
import '../../run/presentation/device_scanner_screen.dart';
import '../../run/data/ble_service.dart';
import '../../activities/presentation/activities_screen.dart';
import '../../activities/data/activity_service.dart';
import '../../training/data/saved_plan_service.dart';
import '../../user/data/user_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/neo_brutalist_container.dart';
import '../../../core/ui/neo_brutalist_button.dart';
import '../../../core/ui/responsive_layout.dart';
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  bool _isLoadingStrava = false;

  Future<void> _importFromStrava() async {
    setState(() {
      _isLoadingStrava = true;
    });

    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/strava/import');
      final response = await http.get(url);
      
      setState(() {
        _isLoadingStrava = false;
      });

      if (response.statusCode == 200) {
        if (mounted) {
          context.push('/analytics', extra: response.body);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to import Strava run: ${response.statusCode}')));
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingStrava = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Network error: $e')));
      }
    }
  }

  void _showGoalBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const GoalSelectionBottomSheet(),
    );
  }

  void _showPreRunSetupBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PreRunSetupBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileScaffold(context),
      desktop: _buildDesktopScaffold(context),
    );
  }

  Widget _buildMobileScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PACEFLOW'),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final profileAsync = ref.watch(userProfileProvider);
              return profileAsync.when(
                data: (profile) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4C8DFF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF4C8DFF)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF4C8DFF)),
                          const SizedBox(width: 4),
                          Text(
                            '${profile.aiCredits}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4C8DFF)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.person_outline),
            offset: const Offset(0, 40),
            color: const Color(0xFF1E1E1E),
            onSelected: (value) async {
              if (value == 'logout') {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'preferences',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Preferences', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 1),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildHomeView(),
            const ActivitiesScreen(),
            const SavedPlansScreen(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: AppTheme.backgroundColor,
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24, top: 12),
        decoration: BoxDecoration(
          border: const Border(top: BorderSide(color: AppTheme.primaryColor, width: 2)),
          color: AppTheme.backgroundColor,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_filled, 'HOME', 0),
            _buildNavItem(Icons.history, 'ACTIVITIES', 1),
            _buildNavItem(Icons.event_note, 'PLANS', 2),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Row(
        children: [
          _buildDesktopSidebar(),
          Expanded(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: const Text('PACEFLOW', style: TextStyle(fontFamily: 'Unbounded', fontWeight: FontWeight.w900)),
                backgroundColor: Colors.transparent,
                elevation: 0,
                actions: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.person_outline),
                    color: AppTheme.surfaceColor,
                    onSelected: (value) async {
                      if (value == 'logout') {
                        await Supabase.instance.client.auth.signOut();
                        if (mounted) context.go('/login');
                      } else if (value == 'preferences') {
                        context.push('/onboarding');
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'preferences',
                        child: Row(
                          children: [
                            Icon(Icons.settings, size: 20, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Preferences', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(height: 1),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, size: 20, color: Colors.redAccent),
                            SizedBox(width: 8),
                            Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              body: IndexedStack(
                index: _currentIndex,
                children: [
                  _buildHomeDesktopView(),
                  const SavedPlansScreen(),
                  Container(), // Live Run Placeholder
                  const ActivitiesScreen(), // Analytics Placeholder
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    return Container(
      width: 250,
      color: AppTheme.backgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0xFF333333), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                ),
                child: const Text('PF', style: TextStyle(color: Colors.black, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 16)),
              ),
              const SizedBox(width: 12),
              const Text('PACEFLOW', style: TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 48),
          _buildSidebarItem(Icons.home_filled, 'DASHBOARD', 0),
          const SizedBox(height: 16),
          _buildSidebarItem(Icons.crop_square, 'PLAN', 1),
          const SizedBox(height: 16),
          _buildSidebarItem(Icons.circle, 'LIVE RUN', 2, iconSize: 10),
          const SizedBox(height: 16),
          _buildSidebarItem(Icons.circle, 'ANALYTICS', 3, iconSize: 10),
          const Spacer(),
          // Premium Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFF5200), // Orange
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PACEFLOW PREMIUM', style: TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 11)),
                SizedBox(height: 8),
                Text('Unlock advanced AI metrics, live ghost pacing & audio recovery engine.', style: TextStyle(color: Colors.white, fontSize: 10, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Profile section
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: 40,
                  height: 40,
                  color: Colors.grey[800],
                  child: const Icon(Icons.person, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ALEX RUNS', style: TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 12)),
                  SizedBox(height: 2),
                  Text('Premium Member', style: TextStyle(color: AppTheme.secondaryTextColor, fontSize: 10)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String label, int index, {double iconSize = 20}) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          border: isSelected ? Border.all(color: Colors.black, width: 2) : Border.all(color: Colors.transparent, width: 2),
          boxShadow: isSelected 
              ? [const BoxShadow(color: Colors.black, offset: Offset(3, 3))]
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.black : AppTheme.secondaryTextColor, size: iconSize),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : AppTheme.secondaryTextColor,
                fontFamily: 'Unbounded',
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          border: isSelected ? Border.all(color: Colors.black, width: 2) : Border.all(color: Colors.transparent, width: 2),
          boxShadow: isSelected 
              ? [const BoxShadow(color: Colors.black, offset: Offset(2, 2))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Colors.black : AppTheme.secondaryTextColor),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontFamily: 'Unbounded',
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHomeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildWelcomeHeader(),
          const SizedBox(height: 32),
          _buildPrSection(),
          const SizedBox(height: 32),
          _buildActiveGoalSection(),
          const SizedBox(height: 32),
          _buildActionsSection(),
        ],
      ),
    );
  }

  Widget _buildHomeDesktopView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDesktopWelcomeHeader(),
          const SizedBox(height: 40),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPrSection(),
                    const SizedBox(height: 32),
                    _buildAiOptimizeCard(),
                  ],
                ),
              ),
              const SizedBox(width: 40),
              SizedBox(
                width: 450,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDesktopActiveGoalSection(),
                    const SizedBox(height: 32),
                    _buildRecentActivitySection(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopWelcomeHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'WELCOME BACK,',
              style: TextStyle(
                fontFamily: 'Geist',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppTheme.secondaryTextColor,
              ),
            ),
            Text(
              'ALEXANDER',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
            ),
          ],
        ),
        NeoBrutalistButton(
          onPressed: _showPreRunSetupBottomSheet,
          backgroundColor: AppTheme.primaryColor,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Text(
              'START NEW RUN',
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'Unbounded',
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiOptimizeCard() {
    return NeoBrutalistContainer(
      backgroundColor: const Color(0xFFFC4C02),
      borderWidth: 3,
      shadowOffset: 4,
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      'PACEFLOW ENGINE V2.1',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'REGENERATE AI PLAN',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 22, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Re-analyze sleep, load, and muscle fatigue to optimize your remaining 5 weeks of the Sub-45 10K schedule.',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          NeoBrutalistButton(
            onPressed: () {},
            backgroundColor: AppTheme.primaryColor,
            borderWidth: 2,
            child: const Text(
              'OPTIMIZE NOW',
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'Unbounded',
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopActiveGoalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACTIVE GOAL',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 12),
        NeoBrutalistContainer(
          backgroundColor: AppTheme.surfaceColor,
          shadowColor: AppTheme.primaryColor,
          borderWidth: 3,
          shadowOffset: 4,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SUB-45:00 10K',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 18),
                  ),
                  NeoBrutalistContainer(
                    backgroundColor: const Color(0xFFFC4C02),
                    borderWidth: 2,
                    shadowOffset: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      'AI ADJUSTED',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '62% COMPLETED',
                    style: TextStyle(
                      fontFamily: 'Unbounded',
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Text(
                    'Week 3 of 8',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      color: AppTheme.secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 16,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 62,
                      child: Container(color: AppTheme.primaryColor),
                    ),
                    Expanded(
                      flex: 38,
                      child: Container(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pace Target: 4:30/km',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      color: AppTheme.secondaryTextColor,
                      fontSize: 13,
                    ),
                  ),
                  NeoBrutalistButton(
                    onPressed: () {},
                    backgroundColor: Colors.white,
                    child: const Text(
                      'VIEW PLAN',
                      style: TextStyle(
                        fontFamily: 'Unbounded',
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RECENT ACTIVITY',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            _buildActivityItem('8.2 KM INTENSITY RUN', '46:12', 'Today, 6:00 AM', const Color(0xFFFC4C02)),
            const SizedBox(height: 12),
            _buildActivityItem('5.0 KM RECOVERY', '28:45', 'Yesterday, 5:30 PM', AppTheme.primaryColor),
            const SizedBox(height: 12),
            _buildActivityItem('10.0 KM LONG RUN', '58:20', 'Saturday, 6:30 AM', AppTheme.accentColor),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String time, String date, Color color) {
    return NeoBrutalistContainer(
      backgroundColor: AppTheme.surfaceColor,
      borderWidth: 2,
      shadowOffset: 0,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 40,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Unbounded',
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    color: AppTheme.secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontFamily: 'Unbounded',
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'WELCOME BACK,',
              style: TextStyle(
                fontFamily: 'Geist',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppTheme.secondaryTextColor,
              ),
            ),
            Text(
              'RUNNER',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 22),
            ),
          ],
        ),
        NeoBrutalistContainer(
          backgroundColor: AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          borderWidth: 2,
          borderRadius: 4,
          shadowOffset: 2,
          child: Row(
            children: [
              const Icon(Icons.star, size: 14, color: Colors.black),
              const SizedBox(width: 4),
              Text(
                'PREMIUM',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.black,
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'PERSONAL BESTS',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 14),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.emoji_events, color: Colors.white, size: 18),
          ],
        ),
        const SizedBox(height: 12),
        const PersonalRecordsWidget(),
      ],
    );
  }

  Widget _buildActiveGoalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACTIVE GOAL',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 12),
        NeoBrutalistContainer(
          backgroundColor: AppTheme.surfaceColor,
          shadowColor: AppTheme.primaryColor,
          borderWidth: 3,
          shadowOffset: 4,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SUB-45:00 10K',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 18),
                  ),
                  NeoBrutalistContainer(
                    backgroundColor: AppTheme.accentColor,
                    borderWidth: 2,
                    shadowOffset: 2,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      'AI',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 12, color: Colors.black),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: 0.7,
                minHeight: 12,
                backgroundColor: Colors.black,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NeoBrutalistButton(
          onPressed: _isLoadingStrava ? () {} : _importFromStrava,
          backgroundColor: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoadingStrava)
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
              else
                const Icon(Icons.sync, color: Colors.black),
              const SizedBox(width: 8),
              Text(
                _isLoadingStrava ? 'IMPORTING...' : 'IMPORT STRAVA',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        NeoBrutalistButton(
          onPressed: _showGoalBottomSheet,
          backgroundColor: AppTheme.primaryColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome, color: Colors.black),
              const SizedBox(width: 8),
              const Text('AI TRAINING PLAN'),
              const SizedBox(width: 8),
              Consumer(
                builder: (context, ref, child) {
                  final profileAsync = ref.watch(userProfileProvider);
                  return profileAsync.when(
                    data: (profile) => NeoBrutalistContainer(
                      backgroundColor: Colors.white,
                      borderWidth: 2,
                      shadowOffset: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      child: Text(
                        '${profile.aiCredits}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black),
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        NeoBrutalistButton(
          onPressed: _showPreRunSetupBottomSheet,
          backgroundColor: AppTheme.accentColor,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow_rounded, color: Colors.black, size: 28),
              SizedBox(width: 8),
              Text('START RUN'),
            ],
          ),
        ),
      ],
    );
  }
}

class PersonalRecordsWidget extends ConsumerWidget {
  const PersonalRecordsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(runHistoryProvider);

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => const Center(child: Text('Error loading records', style: TextStyle(color: Colors.grey))),
      data: (history) {
        if (history.isEmpty) {
          return const Center(child: Text('No runs yet. Start running to set records!', style: TextStyle(color: Colors.grey)));
        }

        // Buckets
        double? pb5k;
        double? pb10k;
        double? pbHalf;
        double? pbFull;

        for (final run in history) {
          final dist = run.distanceMeters;
          final pace = run.avgPace;
          
          if (dist >= 4500 && dist <= 5500) {
            if (pb5k == null || pace < pb5k) pb5k = pace;
          } else if (dist >= 9500 && dist <= 10500) {
            if (pb10k == null || pace < pb10k) pb10k = pace;
          } else if (dist >= 20000 && dist <= 22000) {
            if (pbHalf == null || pace < pbHalf) pbHalf = pace;
          } else if (dist >= 40000 && dist <= 45000) {
            if (pbFull == null || pace < pbFull) pbFull = pace;
          }
        }

        String formatPace(double? pace) {
          if (pace == null) return '--:--';
          final minutes = pace.floor();
          final seconds = ((pace - minutes) * 60).round();
          return '$minutes:${seconds.toString().padLeft(2, '0')}';
        }

        Widget buildRecordCard(String title, double? pace) {
          final hasRecord = pace != null;
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: NeoBrutalistContainer(
              backgroundColor: AppTheme.surfaceColor,
              shadowColor: Colors.black,
              borderWidth: 2,
              borderRadius: 8,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 16,
                          color: hasRecord ? AppTheme.primaryColor : Colors.grey[700],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatPace(pace),
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 15,
                          color: hasRecord ? Colors.white : Colors.grey[800],
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasRecord ? 'Recent' : 'No Data',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 11,
                      color: hasRecord ? AppTheme.secondaryTextColor : Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              buildRecordCard('5K', pb5k),
              buildRecordCard('10K', pb10k),
              buildRecordCard('Half', pbHalf),
              buildRecordCard('Full', pbFull),
            ],
          ),
        );
      },
    );
  }
}

class GoalSelectionBottomSheet extends ConsumerStatefulWidget {
  const GoalSelectionBottomSheet({super.key});

  @override
  ConsumerState<GoalSelectionBottomSheet> createState() => _GoalSelectionBottomSheetState();
}

class _GoalSelectionBottomSheetState extends ConsumerState<GoalSelectionBottomSheet> {
  String _selectedDistance = '10K';
  double _paceSeconds = 330; // 5:30/km in seconds

  final List<String> _distances = ['5K', '10K', 'Half Marathon', 'Marathon'];

  String get _formattedPace {
    final minutes = (_paceSeconds / 60).floor();
    final seconds = (_paceSeconds % 60).floor().toString().padLeft(2, '0');
    return '$minutes:$seconds /km';
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final savedPlansAsync = ref.watch(savedPlansProvider);
    
    String? existingGoalPace;
    String? existingPlanId;
    String? existingPlanGoalString;

    if (savedPlansAsync.value != null) {
      final existingPlan = savedPlansAsync.value!.where((p) => p.goal.contains('Distance: $_selectedDistance')).firstOrNull;
      if (existingPlan != null) {
        existingPlanId = existingPlan.id;
        existingPlanGoalString = existingPlan.goal;

        // Try to get adjusted target pace first from planData
        String? adjustedPace;
        if (existingPlan.planData is Map && existingPlan.planData['adjustedTargetPace'] != null) {
          adjustedPace = existingPlan.planData['adjustedTargetPace'] as String;
        }

        if (adjustedPace != null && adjustedPace.isNotEmpty) {
          existingGoalPace = adjustedPace;
        } else {
          final match = RegExp(r'Target Pace:\s*(.*? /km)').firstMatch(existingPlan.goal);
          if (match != null) {
            existingGoalPace = match.group(1);
          } else {
            existingGoalPace = 'set';
          }
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.only(top: 8, left: 24, right: 24, bottom: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Target Event',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              userProfileAsync.when(
                data: (profile) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: profile.aiCredits > 0 ? const Color(0xFF4A90E2).withOpacity(0.2) : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: profile.aiCredits > 0 ? const Color(0xFF4A90E2) : Colors.red,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: profile.aiCredits > 0 ? const Color(0xFF4A90E2) : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${profile.aiCredits} AI Credits',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: profile.aiCredits > 0 ? const Color(0xFF4A90E2) : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _distances.map((dist) {
                final isSelected = _selectedDistance == dist;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(dist),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedDistance = dist);
                    },
                    selectedColor: const Color(0xFFFC4C02).withOpacity(0.2),
                    backgroundColor: Colors.grey[900],
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFFFC4C02) : Colors.grey,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFFFC4C02) : Colors.grey[800]!,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Target Pace',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          if (existingGoalPace != null)
            Container(
              margin: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.amber, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You already have a plan for $_selectedDistance at $existingGoalPace',
                          style: const TextStyle(fontSize: 13, color: Colors.amber, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        context.pop();
                        context.push('/training', extra: {
                          'goal': existingPlanGoalString,
                          'planId': existingPlanId,
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.amber,
                        side: const BorderSide(color: Colors.amber),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text('View Plan', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _formattedPace,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFC4C02),
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFFFC4C02),
              inactiveTrackColor: Colors.grey[800],
              thumbColor: Colors.white,
              overlayColor: const Color(0xFFFC4C02).withOpacity(0.2),
              trackHeight: 8.0,
            ),
            child: Slider(
              value: _paceSeconds,
              min: 210, // 3:30/km
              max: 480, // 8:00/km
              onChanged: (val) {
                setState(() {
                  _paceSeconds = val;
                });
              },
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('3:30/km', style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text('8:00/km', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 32),
          userProfileAsync.when(
            data: (profile) => Column(
              children: [
                NeoBrutalistButton(
                  onPressed: () {
                    if (profile.subscriptionTier == 'free') {
                      Navigator.pop(context);
                      context.push('/training', extra: 'Distance: $_selectedDistance, Target Pace: $_formattedPace');
                      ref.refresh(userProfileProvider.future);
                    } else if (profile.aiCredits <= 0) {
                      Navigator.pop(context);
                      _showPremiumPaywall(context);
                    } else {
                      Navigator.pop(context);
                      context.push('/training', extra: 'Distance: $_selectedDistance, Target Pace: $_formattedPace');
                      ref.refresh(userProfileProvider.future);
                    }
                  },
                  backgroundColor: AppTheme.primaryColor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (profile.subscriptionTier == 'premium')
                        const Icon(Icons.auto_awesome, color: Colors.black, size: 20),
                      if (profile.subscriptionTier == 'premium')
                        const SizedBox(width: 8),
                      Text(
                        profile.subscriptionTier == 'free' ? 'GENERATE PLAN (STATIC)' : (profile.aiCredits > 0 ? 'REGENERATE AI PLAN' : 'OUT OF CREDITS'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Unbounded',
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                if (profile.subscriptionTier == 'free') ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _showPremiumPaywall(context),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, color: Colors.grey, size: 16),
                        SizedBox(width: 4),
                        Text('Unlock dynamic AI plans with Premium', style: TextStyle(color: Colors.grey, decoration: TextDecoration.underline)),
                      ],
                    ),
                  )
                ],
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          ),
        ],
      ),
    );
  }

  void _showPremiumPaywall(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFC4C02).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFFFC4C02),
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Paceflow Premium',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'You\'ve used up your free AI credits! Upgrade to Premium to generate unlimited highly-personalized AI Training Plans, get Live Audio Coaching, and access Fatigue Heatmaps.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: NeoBrutalistButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Implement Premium Checkout
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Checkout coming soon!')),
                    );
                  },
                  backgroundColor: AppTheme.accentColor,
                  child: const Text(
                    'UPGRADE FOR \$9.99/mo',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Unbounded',
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Maybe Later',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PreRunSetupBottomSheet extends ConsumerStatefulWidget {
  const PreRunSetupBottomSheet({super.key});

  @override
  ConsumerState<PreRunSetupBottomSheet> createState() => _PreRunSetupBottomSheetState();
}

class _PreRunSetupBottomSheetState extends ConsumerState<PreRunSetupBottomSheet> {
  String _selectedDistance = '5K';
  double _paceSeconds = 360; // 6:00/km in seconds
  String _strictness = 'Standard';
  bool _isGhostRacing = false;

  final List<String> _distances = ['5K', '10K', 'Half Marathon', 'Marathon', 'Other...'];
  final List<String> _strictnessLevels = ['Cheerleader', 'Standard', 'Drill Sergeant'];
  final TextEditingController _customDistanceController = TextEditingController();

  @override
  void dispose() {
    _customDistanceController.dispose();
    super.dispose();
  }

  String get _formattedPace {
    final minutes = (_paceSeconds / 60).floor();
    final seconds = (_paceSeconds % 60).floor().toString().padLeft(2, '0');
    return '$minutes:$seconds /km';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.only(top: 8, left: 24, right: 24, bottom: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            "Today's Workout",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _distances.map((dist) {
                final isSelected = _selectedDistance == dist;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(dist),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedDistance = dist);
                    },
                    selectedColor: const Color(0xFFFC4C02).withOpacity(0.2),
                    backgroundColor: Colors.grey[900],
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFFFC4C02) : Colors.grey,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFFFC4C02) : Colors.grey[800]!,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (_selectedDistance == 'Other...') ...[
            const SizedBox(height: 16),
            TextField(
              controller: _customDistanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                labelText: 'Custom Distance (km)',
                labelStyle: const TextStyle(color: Colors.grey),
                hintText: 'e.g. 7.5',
                hintStyle: TextStyle(color: Colors.grey[800]),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFC4C02)),
                ),
                filled: true,
                fillColor: Colors.grey[900],
                suffixText: 'km',
                suffixStyle: const TextStyle(color: Colors.grey),
              ),
            ),
          ],
          const SizedBox(height: 32),

          const Text(
            'Target Pace',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _formattedPace,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFC4C02),
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFFFC4C02),
              inactiveTrackColor: Colors.grey[800],
              thumbColor: Colors.white,
              overlayColor: const Color(0xFFFC4C02).withOpacity(0.2),
              trackHeight: 8.0,
            ),
            child: Slider(
              value: _paceSeconds,
              min: 210, // 3:30/km
              max: 480, // 8:00/km
              onChanged: (val) {
                setState(() {
                  _paceSeconds = val;
                });
              },
            ),
          ),
          const SizedBox(height: 32),
          
          const Text(
            'AI Coach Strictness',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _strictnessLevels.map((level) {
                final isSelected = _strictness == level;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(level),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _strictness = level);
                    },
                    selectedColor: const Color(0xFF4A90E2).withOpacity(0.2),
                    backgroundColor: Colors.grey[900],
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFF4A90E2) : Colors.grey,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF4A90E2) : Colors.grey[800]!,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          
          InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const DeviceScannerScreen(),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bluetooth, color: Colors.grey),
                      SizedBox(width: 12),
                      Text('Sensors', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                  Consumer(
                    builder: (context, ref, _) {
                      final bleState = ref.watch(bleProvider);
                      final status = bleState.connectedDevice != null 
                        ? bleState.connectedDevice!.platformName 
                        : '[ None Connected ]';
                      return Text(
                        status,
                        style: TextStyle(
                          color: bleState.connectedDevice != null ? Colors.green : Colors.grey,
                          fontSize: 14,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.group_outlined, color: Colors.grey),
                  SizedBox(width: 12),
                  Text('Race a Ghost', style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
              Switch(
                value: _isGhostRacing,
                activeColor: const Color(0xFFFC4C02),
                onChanged: (val) {
                  setState(() {
                    _isGhostRacing = val;
                  });
                },
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          NeoBrutalistButton(
            onPressed: () {
              final finalDistance = _selectedDistance == 'Other...' 
                  ? (_customDistanceController.text.isNotEmpty ? '${_customDistanceController.text}K' : 'Custom') 
                  : _selectedDistance;
                  
              Navigator.pop(context);
              context.push('/run', extra: {
                'distance': finalDistance,
                'paceSeconds': _paceSeconds,
                'strictness': _strictness,
                'isGhostRacing': _isGhostRacing,
              });
            },
            backgroundColor: AppTheme.primaryColor,
            child: const Text(
              'START RUN',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'Unbounded',
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
