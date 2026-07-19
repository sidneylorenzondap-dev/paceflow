import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/training_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/neo_brutalist_container.dart';
import '../../../core/ui/responsive_layout.dart';

class TrainingAdjustChatScreen extends StatefulWidget {
  const TrainingAdjustChatScreen({super.key});

  @override
  State<TrainingAdjustChatScreen> createState() => _TrainingAdjustChatScreenState();
}

class _TrainingAdjustChatScreenState extends State<TrainingAdjustChatScreen> {
  final TrainingService _service = TrainingService();
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      'role': 'system', 
      'text': "Paceflow engine flags minor heart strain from your Tuesday thresholds. Should we optimize tomorrow's speed work?"
    },
    {
      'role': 'user', 
      'text': "Let's optimize it. I slept well but my legs still feel quite heavy."
    },
    {
      'role': 'system', 
      'text': "Understood. I've adjusted Wednesday's intervals: 6x 400m instead of 8x. Keeps your performance load at high efficiency."
    },
    {
      'role': 'user', 
      'text': "Awesome, let's lock that modified speed plan in."
    },
  ];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    // Mock response for visual prototype
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
      _messages.add({
        'role': 'system', 
        'text': 'Processing your request... Your plan has been dynamically updated.'
      });
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
      children: [
        _buildMobileHeader(context),
        Expanded(child: _buildChatList()),
        _buildInputArea(isMobile: true),
      ],
    );
  }

  Widget _buildMobileHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0E0E10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/training');
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFC4C02), // Orange
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: const Icon(Icons.star_border, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI COACH',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Unbounded',
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'PACEFLOW ENGINE v2.1 ACTIVE',
                style: TextStyle(
                  color: Color(0xFFCCFF00),
                  fontFamily: 'Unbounded',
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                ),
              ),
            ],
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
                      // Left Column: Chat
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            Expanded(child: _buildChatList()),
                            _buildInputArea(isMobile: false),
                          ],
                        ),
                      ),
                      const SizedBox(width: 40),
                      // Right Column: Active Plan Context
                      Expanded(
                        flex: 4,
                        child: _buildDesktopContextPanel(),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI WORKOUT ADVICE',
          style: TextStyle(color: Color(0xFFFC4C02), fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text(
              'AI COACH DIRECT',
              style: TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 40),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () => context.go('/training'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181C),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: const Text('BACK TO PLAN', style: TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 10)),
              ),
            ),
          ],
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
          _buildDesktopSidebarItem(context, Icons.crop_square, 'PLAN', '/training', true),
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

  Widget _buildDesktopContextPanel() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF18181C),
        border: Border.all(color: Colors.black, width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ACTIVE PLAN CONTEXT', style: TextStyle(color: Color(0xFFFC4C02), fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 11)),
          const SizedBox(height: 8),
          const Text('SUB-45 10K SPEED', style: TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 24)),
          
          const SizedBox(height: 32),
          
          const Text('CURRENT WORKOUT LOAD', style: TextStyle(color: Color(0xFF8E8E93), fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 10)),
          const SizedBox(height: 8),
          const Text('Week 3 // 62% Done', style: TextStyle(color: Color(0xFFCCFF00), fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 20)),
          
          const SizedBox(height: 48),
          
          const Text('PLAN ADJUSTMENTS', style: TextStyle(color: Color(0xFF8E8E93), fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 10)),
          const SizedBox(height: 16),
          
          const Text('INTERVAL MODIFICATION', style: TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 12)),
          const SizedBox(height: 4),
          const Text('Reduced volume to 6x400m to mitigate muscle fatigue.', style: TextStyle(color: Color(0xFF8E8E93), fontFamily: 'Geist', fontSize: 13, height: 1.4)),
          
          const SizedBox(height: 24),
          
          const Text('RECOVERY PACE EXPANSION', style: TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 12)),
          const SizedBox(height: 4),
          const Text('Target slow runs relaxed at 5:45/km rather than 5:30/km.', style: TextStyle(color: Color(0xFF8E8E93), fontFamily: 'Geist', fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  // --- CONTENT BUILDER ---

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 24),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isUser = msg['role'] == 'user';

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isUser ? const Color(0xFFCCFF00) : const Color(0xFF18181C),
                  border: isUser 
                    ? Border.all(color: Colors.black, width: 3)
                    : Border.all(color: const Color(0xFFCCFF00), width: 3),
                ),
                child: Text(
                  msg['text']!,
                  style: TextStyle(
                    color: isUser ? Colors.black : Colors.white,
                    fontFamily: 'Geist',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 0, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0E0E10),
      ),
      child: Column(
        children: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 16.0),
              child: LinearProgressIndicator(color: Color(0xFFCCFF00), backgroundColor: Colors.transparent),
            ),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2E), // Dark input background
                    border: Border.all(color: Colors.black, width: 3),
                  ),
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white, fontFamily: 'Geist', fontSize: 14),
                    decoration: InputDecoration(
                      hintText: isMobile ? 'Ask coach about fatigue or sleep...' : 'Ask coach about fatigue, load adjustments or target paces...',
                      hintStyle: const TextStyle(color: Color(0xFF8E8E93), fontFamily: 'Geist', fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCCFF00),
                    border: Border.all(color: Colors.black, width: 3),
                  ),
                  child: const Text('SEND', style: TextStyle(color: Colors.black, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
