import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/neo_brutalist_button.dart';
import '../../../core/ui/neo_brutalist_container.dart';
import '../../../core/ui/responsive_layout.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      final auth = ref.read(authServiceProvider);
      await auth.signInWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp() async {
    setState(() => _isLoading = true);
    try {
      final auth = ref.read(authServiceProvider);
      await auth.signUpWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check your email for confirmation!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signup failed: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E10),
      body: SafeArea(
        child: ResponsiveLayout(
          mobile: _buildMobileContent(),
          desktop: _buildDesktopContent(),
        ),
      ),
    );
  }

  // --- MOBILE LAYOUT ---

  Widget _buildMobileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 48),
          _buildBrandHeader(),
          const SizedBox(height: 64),
          _buildForm(),
        ],
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFCCFF00),
            border: Border.all(color: Colors.black, width: 3),
            boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
          ),
          child: const Text(
            'PACEFLOW',
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontWeight: FontWeight.w900,
              fontSize: 32,
              color: Colors.black,
              letterSpacing: 2.0,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'AI-POWERED RUNNING\nCOACH & ANALYTICS',
          style: TextStyle(
            fontFamily: 'Unbounded',
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: Colors.white,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField('EMAIL', _emailController, false),
        const SizedBox(height: 24),
        _buildTextField('PASSWORD', _passwordController, true),
        const SizedBox(height: 48),
        if (_isLoading)
          const Center(child: CircularProgressIndicator(color: Color(0xFFCCFF00)))
        else
          NeoBrutalistButton(
            onPressed: _signIn,
            backgroundColor: const Color(0xFFCCFF00),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'ENTER THE FLOW',
                style: TextStyle(
                  fontFamily: 'Unbounded',
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Colors.black,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: _isLoading ? null : _signUp,
          child: const Text(
            'CREATE ACCOUNT',
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: Color(0xFFFC4C02),
              decoration: TextDecoration.underline,
              decorationColor: Color(0xFFFC4C02),
              decorationThickness: 2,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool obscureText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Unbounded',
            fontWeight: FontWeight.w900,
            fontSize: 12,
            color: Colors.white,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 3),
            boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  // --- DESKTOP LAYOUT ---

  Widget _buildDesktopContent() {
    return Row(
      children: [
        // Left Side: Brand Splash
        Expanded(
          flex: 5,
          child: Container(
            color: const Color(0xFFFC4C02),
            child: Stack(
              children: [
                // Background pattern or big text
                Positioned(
                  left: -50,
                  bottom: -100,
                  child: Text(
                    'PF',
                    style: TextStyle(
                      fontFamily: 'Unbounded',
                      fontWeight: FontWeight.w900,
                      fontSize: 400,
                      color: Colors.black.withOpacity(0.1),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(64.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCCFF00),
                          border: Border.all(color: Colors.black, width: 4),
                          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(8, 8))],
                        ),
                        child: const Text(
                          'PACEFLOW',
                          style: TextStyle(
                            fontFamily: 'Unbounded',
                            fontWeight: FontWeight.w900,
                            fontSize: 48,
                            color: Colors.black,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      const Text(
                        'Unlock your peak performance\nwith AI-driven training plans\nand live telemetry pacing.',
                        style: TextStyle(
                          fontFamily: 'Unbounded',
                          fontWeight: FontWeight.w900,
                          fontSize: 32,
                          color: Colors.black,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Right Side: Form
        Expanded(
          flex: 4,
          child: Container(
            color: const Color(0xFF18181C),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: _buildForm(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
