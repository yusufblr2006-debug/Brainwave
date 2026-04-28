import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../widgets/neu_card.dart';
import '../../widgets/grad_button.dart';
import '../../widgets/pill_input.dart';

class AiEngineScreen extends StatefulWidget {
  const AiEngineScreen({super.key});
  @override
  State<AiEngineScreen> createState() => _AiEngineScreenState();
}

class _AiEngineScreenState extends State<AiEngineScreen> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  bool _showResult = false;

  void _fillTemplate(String t) => setState(() => _ctrl.text = t);

  Future<void> _analyze() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() { _loading = true; _showResult = false; });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() { _loading = false; _showResult = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlobBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  GestureDetector(onTap: () => context.pop(), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Color(0xFFB8D4E8), blurRadius: 8, offset: Offset(2, 2))]), child: const Icon(Icons.arrow_back_ios_new, size: 16))),
                  const SizedBox(width: 12),
                  const Icon(Icons.auto_awesome, color: AppColors.gradBlue),
                  const SizedBox(width: 8),
                  Text('AI Legal Engine', style: AppTextStyles.headlineMedium),
                ]),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Describe your legal situation and get instant AI analysis.', style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 24),
                      NeuCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PillInput(hintText: 'Describe your legal issue in detail...', controller: _ctrl, maxLines: 5, prefixIcon: null),
                            const SizedBox(height: 16),
                            Text('Quick Templates:', style: AppTextStyles.labelMedium),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8, runSpacing: 8,
                              children: DummyData.aiTemplates.map((t) => GestureDetector(
                                onTap: () => _fillTemplate(t),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(color: AppColors.cardTint, borderRadius: BorderRadius.circular(50), border: Border.all(color: AppColors.gradBlue.withValues(alpha: 0.2))),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.bolt, color: AppColors.gradBlue, size: 14), const SizedBox(width: 4), Text(t, style: AppTextStyles.bodySmall.copyWith(color: AppColors.gradBlue))]),
                                ),
                              )).toList(),
                            ),
                            const SizedBox(height: 24),
                            GradButton(text: '✦ Analyze', onPressed: _analyze, isLoading: _loading, icon: Icons.auto_awesome),
                          ],
                        ),
                      ).animate().fadeIn().slideY(begin: 0.05),

                      if (_loading) ...[
                        const SizedBox(height: 24),
                        Center(child: Text('Extracting Legal Context...', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gradBlue)))
                            .animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(color: AppColors.gradBlue.withValues(alpha: 0.3)),
                      ],

                      if (_showResult) ...[
                        const SizedBox(height: 24),
                        NeuCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [const Icon(Icons.gavel, color: AppColors.gradBlue, size: 20), const SizedBox(width: 8), Text('Legal Assessment', style: AppTextStyles.labelLarge)]),
                              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: AppColors.cardTint)),
                              Text(DummyData.aiDummyResult, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDark, height: 1.5)),
                              const SizedBox(height: 20),
                              Row(children: [const Icon(Icons.description, color: AppColors.gradGreen, size: 18), const SizedBox(width: 8), Text('Relevant Laws:', style: AppTextStyles.labelMedium)]),
                              const SizedBox(height: 8),
                              ...DummyData.aiRelevantLaws.map((l) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('• ', style: TextStyle(color: AppColors.gradBlue)), Expanded(child: Text(l, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textDark)))]),
                              )),
                              const SizedBox(height: 20),
                              GradButton(text: '📄 Generate Full Report', onPressed: () {}, icon: Icons.description),
                            ],
                          ),
                        ).animate().fadeIn().slideY(begin: 0.1),
                      ],
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
