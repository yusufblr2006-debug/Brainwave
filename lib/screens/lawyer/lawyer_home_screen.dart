import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../widgets/neu_card.dart';
import '../../widgets/bottom_nav.dart';
import '../../providers/auth_provider.dart';

class LawyerHomeScreen extends ConsumerWidget {
  const LawyerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riskColors = {'LOW': AppColors.success, 'MEDIUM': const Color(0xFFD97706), 'HIGH': AppColors.danger};

    return Scaffold(
      body: BlobBackground(
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(children: [
                        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), shape: BoxShape.circle), child: const Icon(Icons.menu, color: AppColors.textDark)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Adv. Rajesh Kumar', style: AppTextStyles.labelLarge),
                          Text('Case Triage Dashboard', style: AppTextStyles.bodySmall),
                        ])),
                        GestureDetector(
                          onTap: () {
                            ref.read(userRoleProvider.notifier).state = 'citizen';
                            context.go('/home');
                          },
                          child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Color(0xFFB8D4E8), blurRadius: 8, offset: Offset(2, 2))]), child: const Icon(Icons.swap_horiz, color: AppColors.gradBlue, size: 20)),
                        ),
                      ]),
                    ).animate().fadeIn(),

                    // Stats row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(children: [
                        Expanded(child: _statCard('12', 'Active')),
                        const SizedBox(width: 12),
                        Expanded(child: _statCard('3', 'Urgent')),
                        const SizedBox(width: 12),
                        Expanded(child: _statCard('89%', 'Avg Win')),
                      ]),
                    ).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text('Active Cases', style: AppTextStyles.headlineMedium),
                    ),
                    const SizedBox(height: 16),

                    // Case list
                    ...DummyData.cases.asMap().entries.map((e) {
                      final c = e.value;
                      final risk = c['risk'] as String;
                      final riskColor = riskColors[risk] ?? AppColors.textMid;
                      final progress = c['progress'] as double;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                        child: NeuCard(
                          onTap: () => context.push('/case-detail/${c['id']}'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text('#${c['id']}', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: riskColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(50)),
                                  child: Text('$risk RISK', style: AppTextStyles.bodySmall.copyWith(color: riskColor, fontWeight: FontWeight.w600, fontSize: 10)),
                                ),
                              ]),
                              const SizedBox(height: 8),
                              Text(c['title'] as String, style: AppTextStyles.labelMedium),
                              const SizedBox(height: 4),
                              Text('Client: ${c['client']}', style: AppTextStyles.bodySmall),
                              Text('${c['lawyer']} · Filed ${c['filed']}', style: AppTextStyles.bodySmall),
                              const SizedBox(height: 12),
                              Row(children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(50),
                                    child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: AppColors.cardTint, valueColor: const AlwaysStoppedAnimation(AppColors.gradBlue)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text('${(progress * 100).toInt()}%', style: AppTextStyles.labelMedium.copyWith(color: AppColors.gradBlue)),
                                const Spacer(),
                                Text('View →', style: AppTextStyles.bodySmall.copyWith(color: AppColors.gradBlue, fontWeight: FontWeight.w600)),
                              ]),
                            ],
                          ),
                        ).animate().fadeIn(delay: Duration(milliseconds: 150 * e.key)).slideY(begin: 0.03),
                      );
                    }),
                  ],
                ),
              ),

              Positioned(
                left: 0, right: 0, bottom: 0,
                child: BottomNav(currentIndex: 0, onTap: (_) {}),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String value, String label) {
    return NeuCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(children: [
        Text(value, style: AppTextStyles.displayMedium.copyWith(color: AppColors.gradBlue)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.bodySmall),
      ]),
    );
  }
}
