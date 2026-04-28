import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../widgets/neu_card.dart';
import '../../widgets/grad_button.dart';

class EvidenceAnalyzerScreen extends StatefulWidget {
  const EvidenceAnalyzerScreen({super.key});
  @override
  State<EvidenceAnalyzerScreen> createState() => _EvidenceAnalyzerScreenState();
}

class _EvidenceAnalyzerScreenState extends State<EvidenceAnalyzerScreen> {
  bool _picked = false;
  bool _loading = false;
  bool _showResult = false;

  Future<void> _pickImage() async {
    // Simulate image pick
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _picked = true);
  }

  Future<void> _analyze() async {
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
                  const Icon(Icons.camera_alt, color: AppColors.gradGreen),
                  const SizedBox(width: 8),
                  Text('Evidence Analyzer', style: AppTextStyles.headlineMedium),
                ]),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Upload zone
                      if (!_picked)
                        NeuCard(
                          onTap: _pickImage,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.gradBlue.withValues(alpha: 0.3), style: BorderStyle.solid, width: 2),
                            ),
                            child: Column(children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 32),
                              ),
                              const SizedBox(height: 16),
                              Text('Tap to capture or upload evidence', style: AppTextStyles.labelMedium.copyWith(color: AppColors.gradBlue)),
                              const SizedBox(height: 4),
                              Text('Supports images & documents', style: AppTextStyles.bodySmall),
                            ]),
                          ),
                        ).animate().fadeIn()
                      else ...[
                        // Image preview
                        NeuCard(
                          padding: EdgeInsets.zero,
                          child: Stack(
                            children: [
                              Container(
                                height: 200, width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  color: AppColors.cardTint,
                                ),
                                child: const Center(child: Icon(Icons.image, size: 64, color: AppColors.gradBlue)),
                              ),
                              Positioned(
                                top: 8, right: 8,
                                child: GestureDetector(
                                  onTap: () => setState(() { _picked = false; _showResult = false; }),
                                  child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 16)),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(),
                        const SizedBox(height: 20),
                        GradButton(text: 'Analyze Evidence', onPressed: _analyze, isLoading: _loading, icon: Icons.search),
                      ],

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
                              Row(children: [const Icon(Icons.warning_rounded, color: AppColors.danger, size: 20), const SizedBox(width: 8), Text('Violations Found', style: AppTextStyles.labelLarge.copyWith(color: AppColors.danger))]),
                              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: AppColors.cardTint)),
                              ...DummyData.evidenceViolations.map((v) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.error_outline, color: AppColors.danger, size: 16), const SizedBox(width: 8), Expanded(child: Text(v, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDark)))]),
                              )),
                              const SizedBox(height: 20),
                              Row(children: [const Icon(Icons.check_circle, color: AppColors.success, size: 20), const SizedBox(width: 8), Text('Actionable Next Steps', style: AppTextStyles.labelLarge.copyWith(color: AppColors.success))]),
                              const SizedBox(height: 12),
                              ...DummyData.evidenceNextSteps.asMap().entries.map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Container(width: 20, height: 20, decoration: BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle), alignment: Alignment.center, child: Text('${e.key + 1}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600))),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(e.value, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDark))),
                                ]),
                              )),
                              const SizedBox(height: 20),
                              GradButton(text: '📝 Draft Complaint Letter', onPressed: () {}, icon: Icons.edit_document),
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
