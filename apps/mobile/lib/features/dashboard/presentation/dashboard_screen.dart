import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../run/presentation/device_scanner_screen.dart';
import '../../run/data/ble_service.dart';
import '../../activities/presentation/activities_screen.dart';
import '../../training/presentation/saved_plans_screen.dart';
import '../../training/data/saved_plan_service.dart';
import '../../user/data/user_service.dart';

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
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, size: 20, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Profile Settings', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: const Color(0xFFFC4C02), // Strava Orange/Paceflow Primary
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Activities',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note),
            label: 'Plans',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Ready to crush your goals?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              
              // Recent Activity Card (Mock)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                  )
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NEXT GOAL',
                      style: TextStyle(
                        color: Colors.grey,
                        letterSpacing: 1.5,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sub-20 5K Time Trial',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: 0.7,
                      backgroundColor: Colors.grey[800],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoadingStrava ? null : _importFromStrava,
                  icon: _isLoadingStrava 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.sync, color: Colors.white),
                  label: Text(
                    _isLoadingStrava ? 'IMPORTING...' : 'IMPORT FROM STRAVA',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFC4C02), // Strava Orange
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _showGoalBottomSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2), // Nice Blue
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_month, color: Colors.white),
                      const SizedBox(width: 8),
                      const Text(
                        'AI TRAINING PLAN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Consumer(
                        builder: (context, ref, child) {
                          final profileAsync = ref.watch(userProfileProvider);
                          return profileAsync.when(
                            data: (profile) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: profile.aiCredits > 0 ? Colors.white.withOpacity(0.2) : Colors.red.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${profile.aiCredits}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              );
                            },
                            loading: () => const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                            error: (_, __) => const SizedBox.shrink(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: _showPreRunSetupBottomSheet,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('START RUN'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
              ),
            ],
          ),
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
    if (savedPlansAsync.value != null) {
      final existingPlan = savedPlansAsync.value!.where((p) => p.goal.contains('Distance: $_selectedDistance')).firstOrNull;
      if (existingPlan != null) {
        final match = RegExp(r'Target Pace:\s*(.*? /km)').firstMatch(existingPlan.goal);
        if (match != null) {
          existingGoalPace = match.group(1);
        } else {
          existingGoalPace = 'set';
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
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'You already have a plan for $_selectedDistance at $existingGoalPace',
                    style: const TextStyle(fontSize: 12, color: Colors.amber),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
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
            data: (profile) => ElevatedButton(
              onPressed: () {
                if (profile.aiCredits <= 0) {
                  Navigator.pop(context); // Close bottom sheet
                  _showPremiumPaywall(context);
                } else {
                  Navigator.pop(context);
                  context.push('/training', extra: 'Distance: $_selectedDistance, Target Pace: $_formattedPace');
                  // Refresh user profile after generating plan
                  ref.refresh(userProfileProvider.future);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: profile.aiCredits > 0 ? const Color(0xFF4A90E2) : Colors.red[800],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                profile.aiCredits > 0 ? 'GENERATE AI PLAN' : 'OUT OF CREDITS',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Failed to load profile', style: TextStyle(color: Colors.red))),
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
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Implement Premium Checkout
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Checkout coming soon!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFC4C02),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'UPGRADE FOR \$9.99/mo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
          ElevatedButton(
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'START GPS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
