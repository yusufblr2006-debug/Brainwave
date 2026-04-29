import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../config/theme.dart';
import '../widgets/neu_card.dart';
import '../widgets/grad_button.dart';

class CaseDetailScreen extends StatefulWidget {
  final Map caseData;
  const CaseDetailScreen({super.key, required this.caseData});

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  bool _analyzing = false;
  Map? _analysis;

  Future<void> _runAnalysis() async {
    setState(() => _analyzing = true);
    try {
      // For demo, we use a slightly modified version of the dummy result
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _analysis = {
            'summary': 'This case involves a boundary dispute where the neighbor has constructed a wall partially on your registered property. Evidence shows valid ownership documents but requires a new surveyor report.',
            'laws': ['IPC Section 441', 'Transfer of Property Act Section 52'],
            'missing': ['Surveyor Affidavit', 'Property Tax Receipts (last 3 years)'],
          };
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.caseData;
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
                  Text('Case Details', style: AppTextStyles.headlineMedium),
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
                    children: [
                      // Hero Card
                      NeuCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                              child: Stack(
                                children: [
                                  Image.network('https://images.unsplash.com/photo-1589829545856-d10d557cf95f?q=80&w=800&auto=format&fit=crop', height: 160, width: double.infinity, fit: BoxFit.cover),
                                  Positioned(
                                    top: 12, right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(50)),
                                      child: Text(c['risk'] ?? 'MEDIUM', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c['title'], style: AppTextStyles.labelLarge),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 14, color: AppColors.textMid),
                                      const SizedBox(width: 4),
                                      Text(c['lawyer'], style: AppTextStyles.bodySmall),
                                      const Spacer(),
                                      Text('ID: ${c['id']}', style: AppTextStyles.bodySmall),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().slideY(begin: 0.1),
                      
                      const SizedBox(height: 24),

                      // Progress section
                      _section('Progress (40%)'),
                      const SizedBox(height: 12),
                      LinearPercentIndicator(
                        lineHeight: 12,
                        percent: 0.4,
                        barRadius: const Radius.circular(10),
                        backgroundColor: Colors.white,
                        progressColor: AppColors.gradBlue,
                        animation: true,
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 16),
                      _milestone('Case Filed', true),
                      _milestone('Documents Received', true),
                      _milestone('Legal Review', false, isCurrent: true),
                      _milestone('Mediation Phase', false),
                      _milestone('Final Decision', false),

                      const SizedBox(height: 32),

                      // Probability Card
                      NeuCard(
                        child: Row(
                          children: [
                            CircularPercentIndicator(
                              radius: 40,
                              lineWidth: 8,
                              percent: 0.72,
                              center: Text('72%', style: AppTextStyles.labelLarge),
                              progressColor: AppColors.success,
                              backgroundColor: AppColors.cardTint,
                              circularStrokeCap: CircularStrokeCap.round,
                              animation: true,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Win Probability', style: AppTextStyles.labelMedium),
                                  Text('Based on similar cases and current evidence.', style: AppTextStyles.bodySmall),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // AI Analysis section
                      _section('AI Strategy Analysis'),
                      const SizedBox(height: 12),
                      if (_analysis == null)
                        GradButton(text: 'Analyze This Case', onPressed: _runAnalysis, isLoading: _analyzing)
                      else
                        _buildAnalysisResult(),

                      const SizedBox(height: 32),

                      // Assigned Lawyer
                      _section('Assigned Lawyer'),
                      const SizedBox(height: 12),
                      NeuCard(
                        child: Row(
                          children: [
                            CircleAvatar(backgroundColor: AppColors.cardTint, child: const Icon(Icons.person, color: AppColors.gradBlue)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(c['lawyer'], style: AppTextStyles.labelMedium), Text('Senior Property Advocate', style: AppTextStyles.bodySmall)])),
                            IconButton(onPressed: () {}, icon: const Icon(Icons.mail_outline, color: AppColors.gradBlue)),
                            IconButton(onPressed: () {}, icon: const Icon(Icons.chat_bubble_outline, color: AppColors.gradBlue)),
                          ],
                        ),
                      ),
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

  Widget _section(String title) => Row(children: [Text(title, style: AppTextStyles.labelLarge)]);

  Widget _milestone(String text, bool done, {bool isCurrent = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(done ? Icons.check_circle : (isCurrent ? Icons.circle : Icons.circle_outlined), size: 18, color: done ? AppColors.success : (isCurrent ? AppColors.gradBlue : AppColors.textMid.withValues(alpha: 0.3))),
          const SizedBox(width: 12),
          Text(text, style: AppTextStyles.bodyMedium.copyWith(color: done || isCurrent ? AppColors.textDark : AppColors.textMid, fontWeight: isCurrent ? FontWeight.bold : null)),
        ],
      ),
    );
  }

  Widget _buildAnalysisResult() {
    return NeuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [const Icon(Icons.auto_awesome, color: AppColors.gold, size: 16), const SizedBox(width: 8), Text('AI Insights', style: AppTextStyles.labelMedium)]),
          const SizedBox(height: 12),
          Text(_analysis!['summary'], style: AppTextStyles.bodySmall),
          const SizedBox(height: 16),
          Text('Applicable Laws:', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
          Wrap(spacing: 8, children: (_analysis!['laws'] as List).map((l) => Chip(label: Text(l, style: const TextStyle(fontSize: 10)), padding: EdgeInsets.zero)).toList()),
          const SizedBox(height: 12),
          Text('Missing Evidence:', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.danger)),
          Wrap(spacing: 8, children: (_analysis!['missing'] as List).map((l) => Chip(label: Text(l, style: const TextStyle(fontSize: 10)), backgroundColor: AppColors.danger.withValues(alpha: 0.1))).toList()),
        ],
      ),
    ).animate().fadeIn();
  }
}
