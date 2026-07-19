import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/auth_service.dart';
import '../../../core/theme/app_theme.dart';
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
          const SizedBox(height: 24),
          _buildMobileHeader(),
          const SizedBox(height: 48),
          _buildForm(),
        ],
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: const BoxDecoration(
            color: Color(0xFFCCFF00),
          ),
          child: const Text(
            'FAST // AI',
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: Colors.black,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'PACEFLOW',
          style: TextStyle(
            fontFamily: 'Unbounded',
            fontWeight: FontWeight.w900,
            fontSize: 36,
            color: Colors.white,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'WELCOME BACK',
          style: TextStyle(
            fontFamily: 'Unbounded',
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xFFFC4C02),
          ),
        ),
      ],
    );
  }

  // --- FORM ---

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField('EMAIL ADDRESS', _emailController, false, 'alex.runner@paceflow.io'),
        const SizedBox(height: 24),
        _buildTextField('PASSWORD', _passwordController, true, '••••••••••••'),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {},
          child: const Text(
            'Forgot Password?',
            style: TextStyle(
              fontFamily: 'Geist',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFFCCFF00),
              decoration: TextDecoration.underline,
              decorationColor: Color(0xFFCCFF00),
            ),
          ),
        ),
        const SizedBox(height: 48),
        if (_isLoading)
          const Center(child: CircularProgressIndicator(color: Color(0xFFCCFF00)))
        else ...[
          GestureDetector(
            onTap: _signIn,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFCCFF00),
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
              ),
              child: const Center(
                child: Text(
                  'LOG IN',
                  style: TextStyle(
                    fontFamily: 'Unbounded',
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _signUp,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Center(
                child: Text(
                  'SIGN UP',
                  style: TextStyle(
                    fontFamily: 'Unbounded',
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool obscureText, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Unbounded',
            fontWeight: FontWeight.w800,
            fontSize: 11,
            color: Color(0xFF8E8E93),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2E),
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 14,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          flex: 1,
          child: Container(
            color: const Color(0xFFFC4C02),
            padding: const EdgeInsets.all(64.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCCFF00),
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: const Text('PF', style: TextStyle(color: Colors.black, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 28)),
                    ),
                    const SizedBox(width: 8),
                    const Text('PACEFLOW', style: TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 28)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FAST // AI\nRUN COACHING',
                      style: TextStyle(
                        fontFamily: 'Unbounded',
                        fontWeight: FontWeight.w900,
                        fontSize: 48,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Join over 50,000 runners optimizing their thresholds, sleep, and\nrecovery with direct real-time artificial intelligence advice.',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 18,
                        color: Colors.white,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCCFF00),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: const Text(
                    '+15% AVG PACE IMPROVEMENT',
                    style: TextStyle(
                      fontFamily: 'Unbounded',
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Right Side: Form
        Expanded(
          flex: 1,
          child: Container(
            color: const Color(0xFF0E0E10),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Container(
                  padding: const EdgeInsets.all(48),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181C),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'FAST // AI ACCESS',
                        style: TextStyle(
                          fontFamily: 'Unbounded',
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          color: Color(0xFFFC4C02),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'WELCOME BACK',
                        style: TextStyle(
                          fontFamily: 'Unbounded',
                          fontWeight: FontWeight.w900,
                          fontSize: 28,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 48),
                      _buildForm(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
