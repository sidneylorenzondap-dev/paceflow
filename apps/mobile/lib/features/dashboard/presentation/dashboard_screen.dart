import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {},
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
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
                child: ElevatedButton.icon(
                  onPressed: _showGoalBottomSheet,
                  icon: const Icon(Icons.calendar_month, color: Colors.white),
                  label: const Text(
                    'AI TRAINING PLAN',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2), // Nice Blue
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
        ),
      ),
    );
  }
}

class GoalSelectionBottomSheet extends StatefulWidget {
  const GoalSelectionBottomSheet({super.key});

  @override
  State<GoalSelectionBottomSheet> createState() => _GoalSelectionBottomSheetState();
}

class _GoalSelectionBottomSheetState extends State<GoalSelectionBottomSheet> {
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
            'Target Event',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/training', extra: 'Distance: $_selectedDistance, Target Pace: $_formattedPace');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90E2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'GENERATE AI PLAN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PreRunSetupBottomSheet extends StatefulWidget {
  const PreRunSetupBottomSheet({super.key});

  @override
  State<PreRunSetupBottomSheet> createState() => _PreRunSetupBottomSheetState();
}

class _PreRunSetupBottomSheetState extends State<PreRunSetupBottomSheet> {
  String _selectedDistance = '5K';
  double _paceSeconds = 360; // 6:00/km in seconds
  String _strictness = 'Standard';
  bool _isGhostRacing = false;

  final List<String> _distances = ['5K', '10K', 'Half Marathon', 'Marathon'];
  final List<String> _strictnessLevels = ['Strict (Race)', 'Standard', 'Relaxed'];

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
              Navigator.pop(context);
              context.push('/run', extra: {
                'distance': _selectedDistance,
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
