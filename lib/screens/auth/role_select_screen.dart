import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../../widgets/grad_button.dart';
import '../../providers/auth_provider.dart';

class RoleSelectScreen extends ConsumerStatefulWidget {
  const RoleSelectScreen({super.key});
  @override
  ConsumerState<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends ConsumerState<RoleSelectScreen> {
  String _selected = 'citizen';

  Future<void> _continue() async {
    ref.read(userRoleProvider.notifier).state = _selected;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', _selected);
    if (!mounted) return;
    context.go(_selected == 'lawyer' ? '/lawyer-home' : '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlobBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('I am a...', style: AppTextStyles.displayMedium.copyWith(color: Colors.white))
                      .animate().fadeIn(),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(child: _roleCard('citizen', Icons.person_rounded, 'Client', 'I need\nlegal help')),
                      const SizedBox(width: 20),
                      Expanded(child: _roleCard('lawyer', Icons.balance, 'Lawyer', 'I manage\ncases')),
                    ],
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                  const SizedBox(height: 48),
                  GradButton(text: 'Continue', onPressed: _continue)
                      .animate().fadeIn(delay: 400.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleCard(String value, IconData icon, String title, String subtitle) {
    final active = _selected == value;
    return GestureDetector(
      onTap: () => setState(() => _selected = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(24),
          border: active ? Border.all(color: AppColors.gradBlue, width: 2.5) : null,
          boxShadow: [
            BoxShadow(
              color: active ? AppColors.gradBlue.withValues(alpha: 0.3) : const Color(0xFFB8D4E8),
              offset: const Offset(6, 6),
              blurRadius: 16,
            ),
            const BoxShadow(color: Color(0xFFFFFFFF), offset: Offset(-6, -6), blurRadius: 16),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: active ? AppColors.gradBlue : AppColors.textMid),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.labelLarge.copyWith(color: active ? AppColors.gradBlue : AppColors.textDark)),
            const SizedBox(height: 8),
            Text(subtitle, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
