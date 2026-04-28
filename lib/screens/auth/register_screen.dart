import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../widgets/pill_input.dart';
import '../../widgets/grad_button.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _register() async {
    if (_passCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match'), backgroundColor: AppColors.danger),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final auth = ref.read(authProvider);
      await auth.register(_nameCtrl.text.trim(), _emailCtrl.text.trim(), _passCtrl.text.trim());
      ref.read(isLoggedInProvider.notifier).state = true;
      ref.read(userNameProvider.notifier).state = _nameCtrl.text.trim();
      if (mounted) context.go('/role-select');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: BlobBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                        child: const Icon(Icons.shield_rounded, color: Colors.white, size: 48),
                      ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
                      const SizedBox(height: 12),
                      Text('JudisAI', style: AppTextStyles.displayLarge.copyWith(color: Colors.white, fontSize: 28))
                          .animate().fadeIn(delay: 200.ms),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FrostedGlassPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Create Account', style: AppTextStyles.displaySmall),
                        const SizedBox(height: 4),
                        Text('Join JudisAI today', style: AppTextStyles.bodyMedium),
                        const SizedBox(height: 28),
                        PillInput(hintText: 'Full Name', prefixIcon: Icons.badge_outlined, controller: _nameCtrl),
                        const SizedBox(height: 16),
                        PillInput(hintText: 'Email address', prefixIcon: Icons.email_outlined, controller: _emailCtrl),
                        const SizedBox(height: 16),
                        PillInput(hintText: 'Password', obscureText: true, prefixIcon: Icons.lock_outline, controller: _passCtrl),
                        const SizedBox(height: 16),
                        PillInput(hintText: 'Confirm Password', obscureText: true, prefixIcon: Icons.lock_outline, controller: _confirmCtrl),
                        const SizedBox(height: 28),
                        GradButton(text: 'Create Account', onPressed: _register, isLoading: _loading),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: Center(
                            child: RichText(
                              text: TextSpan(
                                text: 'Already have an account? ',
                                style: AppTextStyles.bodyMedium,
                                children: [
                                  TextSpan(text: 'Sign in', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gradBlue, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
