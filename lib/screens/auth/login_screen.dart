import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../widgets/neu_card.dart';
import '../../widgets/pill_input.dart';
import '../../widgets/grad_button.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      final auth = ref.read(authProvider);
      await auth.signIn(_emailCtrl.text.trim(), _passCtrl.text.trim());
      ref.read(isLoggedInProvider.notifier).state = true;
      ref.read(userNameProvider.notifier).state = auth.displayName ?? 'User';
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
              // Top: Logo area
              Expanded(
                flex: 2,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shield_rounded, color: Colors.white, size: 48),
                      ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
                      const SizedBox(height: 12),
                      Text('JudisAI', style: AppTextStyles.displayLarge.copyWith(color: Colors.white, fontSize: 28))
                          .animate().fadeIn(delay: 200.ms),
                    ],
                  ),
                ),
              ),

              // Bottom: Login form
              Expanded(
                flex: 5,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FrostedGlassPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Welcome Back', style: AppTextStyles.displaySmall),
                        const SizedBox(height: 4),
                        Text('Sign in to continue', style: AppTextStyles.bodyMedium),
                        const SizedBox(height: 28),

                        PillInput(
                          hintText: 'Email address',
                          prefixIcon: Icons.person_outline,
                          controller: _emailCtrl,
                        ),
                        const SizedBox(height: 16),
                        PillInput(
                          hintText: 'Password',
                          obscureText: _obscure,
                          prefixIcon: Icons.lock_outline,
                          controller: _passCtrl,
                          suffix: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppColors.textMid, size: 20),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text('Forgot Password?', style: AppTextStyles.bodySmall.copyWith(color: AppColors.gradGreen, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(height: 24),

                        GradButton(text: 'Sign In', onPressed: _signIn, isLoading: _loading),
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            const Expanded(child: Divider(color: Colors.black12)),
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('Or', style: AppTextStyles.bodySmall)),
                            const Expanded(child: Divider(color: Colors.black12)),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Google
                        NeuCard(
                          onTap: _signIn,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.g_mobiledata, size: 28),
                              const SizedBox(width: 8),
                              Text('Continue with Google', style: AppTextStyles.labelMedium),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Facebook
                        GestureDetector(
                          onTap: _signIn,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1877F2),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.facebook, color: Colors.white),
                                const SizedBox(width: 8),
                                Text('Continue with Facebook', style: AppTextStyles.labelMedium.copyWith(color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        GestureDetector(
                          onTap: () => context.go('/register'),
                          child: Center(
                            child: RichText(
                              text: TextSpan(
                                text: 'New user? ',
                                style: AppTextStyles.bodyMedium,
                                children: [
                                  TextSpan(text: 'Register here', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gradBlue, fontWeight: FontWeight.w600)),
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
