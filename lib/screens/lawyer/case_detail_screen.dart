import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../widgets/neu_card.dart';
import '../../widgets/grad_button.dart';
import '../../providers/case_provider.dart';

class CaseDetailScreen extends ConsumerWidget {
  final String id;
  const CaseDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checklist = ref.watch(evidenceChecklistProvider);
    final caseData = DummyData.cases.firstWhere((c) => c['id'] == id, orElse: () => DummyData.cases[0]);

    return Scaffold(
      body: BlobBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Color(0xFFB8D4E8), blurRadius: 8, offset: Offset(2, 2))]),
                      child: const Icon(Icons.arrow_back_ios_new, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Case #$id', style: AppTextStyles.headlineMedium),
                ]),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Win Probability
                      NeuCard(
                        child: Row(
                          children: [
                            CircularPercentIndicator(
                              radius: 50,
                              lineWidth: 10,
                              percent: (caseData['winRate'] as double),
                              center: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('${((caseData['winRate'] as double) * 100).toInt()}%', style: AppTextStyles.displayMedium.copyWith(color: AppColors.gradBlue)),
                                  Text('Win Rate', style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
                                ],
                              ),
                              linearGradient: AppColors.primaryGradient,
                              backgroundColor: AppColors.cardTint,
                              circularStrokeCap: CircularStrokeCap.round,
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(caseData['title'] as String, style: AppTextStyles.labelLarge),
                                  const SizedBox(height: 4),
                                  Text('Client: ${caseData['client']}', style: AppTextStyles.bodySmall),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: Text('High Chance', style: AppTextStyles.bodySmall.copyWith(color: AppColors.success, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().slideY(begin: 0.05),

                      const SizedBox(height: 20),

                      // AI Assessment
                      NeuCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.smart_toy, color: AppColors.gradBlue, size: 20),
                              const SizedBox(width: 8),
                              Text('AI Assessment', style: AppTextStyles.labelLarge),
                            ]),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: AppColors.cardTint)),
                            Text(
                              'Based on the evidence collected so far, the case has a strong foundation. '
                              'The property tax receipts establish clear ownership history. However, the missing '
                              'rent agreement page 2 and neighbor witness statement are critical for establishing '
                              'continuous possession. Recommend prioritizing these before the next hearing.',
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDark, height: 1.5),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05),

                      const SizedBox(height: 20),

                      // Evidence Checklist
                      NeuCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.checklist, color: AppColors.gradGreen, size: 20),
                              const SizedBox(width: 8),
                              Text('Evidence Checklist', style: AppTextStyles.labelLarge),
                            ]),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: AppColors.cardTint)),
                            ...DummyData.evidenceChecklist.asMap().entries.map((e) {
                              final done = checklist[e.key];
                              return GestureDetector(
                                onTap: () {
                                  final updated = List<bool>.from(checklist);
                                  updated[e.key] = !updated[e.key];
                                  ref.read(evidenceChecklistProvider.notifier).state = updated;
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 24, height: 24,
                                        decoration: BoxDecoration(
                                          gradient: done ? AppColors.primaryGradient : null,
                                          color: done ? null : Colors.transparent,
                                          borderRadius: BorderRadius.circular(6),
                                          border: done ? null : Border.all(color: AppColors.textMid, width: 1.5),
                                        ),
                                        child: done ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          e.value['item'] as String,
                                          style: AppTextStyles.bodyMedium.copyWith(
                                            color: done ? AppColors.textDark : AppColors.textMid,
                                            decoration: done ? TextDecoration.none : null,
                                          ),
                                        ),
                                      ),
                                      if (done) Text('verified', style: AppTextStyles.bodySmall.copyWith(color: AppColors.success, fontSize: 10)),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),

                      const SizedBox(height: 20),

                      // Action buttons
                      Row(children: [
                        Expanded(child: GradButton(text: '📞 Contact', onPressed: () {}, small: true, icon: Icons.phone)),
                        const SizedBox(width: 8),
                        Expanded(child: GradButton(text: '📤 Share', onPressed: () {}, small: true, icon: Icons.share)),
                        const SizedBox(width: 8),
                        Expanded(child: GradButton(text: '⚡ AI Strategy', onPressed: () {}, small: true, icon: Icons.auto_awesome)),
                      ]).animate().fadeIn(delay: 300.ms),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
