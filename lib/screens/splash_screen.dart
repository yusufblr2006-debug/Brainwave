import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    final loggedIn = ref.read(isLoggedInProvider);
    if (loggedIn) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlobBackground(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_rounded, color: Colors.white, size: 64),
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.0, 1.0), curve: Curves.elasticOut, duration: 800.ms),
                const SizedBox(height: 24),
                Text(
                  'JudisAI',
                  style: AppTextStyles.displayLarge.copyWith(color: Colors.white, fontSize: 32),
                ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
                const SizedBox(height: 8),
                Text(
                  'AI-Powered Legal Assistant',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                ).animate().fadeIn(delay: 600.ms, duration: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
