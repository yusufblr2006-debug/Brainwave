import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../widgets/neu_card.dart';

class RightsDetailScreen extends StatelessWidget {
  final String id;
  const RightsDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final data = DummyData.rightsData[id] ?? DummyData.rightsData['police']!;
    final title = data['title'] as String;
    final rights = data['rights'] as List<String>;
    final whatToSay = data['whatToSay'] as List<String>;

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
                    child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Color(0xFFB8D4E8), blurRadius: 8, offset: Offset(2, 2))]), child: const Icon(Icons.arrow_back_ios_new, size: 16)),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.shield, color: AppColors.gradBlue),
                  const SizedBox(width: 8),
                  Expanded(child: Text(title, style: AppTextStyles.headlineMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    left: 20, right: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Action pills
                      Row(children: [
                        _actionPill(Icons.volume_up, 'Read Aloud'),
                        const SizedBox(width: 8),
                        _actionPill(Icons.share, 'Share'),
                        const SizedBox(width: 8),
                        _actionPill(Icons.download, 'Save Offline'),
                      ]).animate().fadeIn(),
                      const SizedBox(height: 24),

                      // Your Rights card
                      NeuCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.shield, color: AppColors.gradBlue, size: 20),
                              const SizedBox(width: 8),
                              Text('Your Rights', style: AppTextStyles.labelLarge),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.gradBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(50)),
                                child: Text('${rights.length} rights', style: AppTextStyles.bodySmall.copyWith(color: AppColors.gradBlue, fontWeight: FontWeight.w600)),
                              ),
                            ]),
                            const SizedBox(height: 16),
                            ...rights.asMap().entries.map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 24, height: 24,
                                    decoration: BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                                    alignment: Alignment.center,
                                    child: Text('${e.key + 1}', style: AppTextStyles.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(e.value, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDark, height: 1.4))),
                                ],
                              ),
                            )),
                          ],
                        ),
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05),

                      const SizedBox(height: 20),

                      // What to say card
                      NeuCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.chat_bubble_outline, color: AppColors.gradGreen, size: 20),
                              const SizedBox(width: 8),
                              Text('What You Should Say', style: AppTextStyles.labelLarge),
                            ]),
                            const SizedBox(height: 16),
                            ...whatToSay.map((s) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.cardTint,
                                  borderRadius: BorderRadius.circular(16),
                                  border: const Border(left: BorderSide(color: AppColors.gradBlue, width: 3)),
                                ),
                                child: Text(s, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDark, fontStyle: FontStyle.italic)),
                              ),
                            )),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.dangerGradient, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: AppColors.danger.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.sos, color: Colors.white),
      ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(end: 1.1, duration: 800.ms),
    );
  }

  Widget _actionPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(50), border: Border.all(color: AppColors.gradBlue.withValues(alpha: 0.3)), boxShadow: const [BoxShadow(color: Color(0xFFB8D4E8), blurRadius: 4, offset: Offset(2, 2))]),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: AppColors.gradBlue), const SizedBox(width: 4), Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.gradBlue, fontWeight: FontWeight.w500))]),
    );
  }
}
