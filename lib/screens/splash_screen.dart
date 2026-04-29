import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../providers/app_provider.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _checkAndNavigate();
  }

  Future<void> _checkAndNavigate() async {
    try {
      await ApiService.checkHealth().timeout(const Duration(seconds: 5));
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      final provider = context.read<AppProvider>();
      if (provider.userId == null) {
        context.go('/auth');
      } else {
        context.go('/home');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _offline = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlobBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
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
                if (_offline) ...[
                  const SizedBox(height: 32),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.cloud_off, color: Colors.white, size: 28),
                        const SizedBox(height: 8),
                        Text('Server Unavailable', style: AppTextStyles.labelMedium.copyWith(color: Colors.white)),
                        const SizedBox(height: 4),
                        Text('Check your connection or backend', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            setState(() => _offline = false);
                            _checkAndNavigate();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Text('Retry', style: AppTextStyles.labelMedium.copyWith(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                ],
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

