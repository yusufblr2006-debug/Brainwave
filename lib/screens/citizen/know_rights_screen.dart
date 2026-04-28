import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../widgets/neu_card.dart';

class KnowRightsScreen extends StatefulWidget {
  const KnowRightsScreen({super.key});
  @override
  State<KnowRightsScreen> createState() => _KnowRightsScreenState();
}

class _KnowRightsScreenState extends State<KnowRightsScreen> {
  int _activeTab = 0;
  int _expandedIndex = -1;

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
                  const Icon(Icons.balance, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Text('Know Your Rights', style: AppTextStyles.headlineMedium),
                ]),
              ),
              // Tab chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: DummyData.rightsCategories.asMap().entries.map((e) {
                      final active = e.key == _activeTab;
                      return GestureDetector(
                        onTap: () => setState(() { _activeTab = e.key; _expandedIndex = -1; }),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: active ? AppColors.primaryGradient : null,
                            color: active ? null : Colors.white,
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: active ? null : const [BoxShadow(color: Color(0xFFB8D4E8), blurRadius: 4, offset: Offset(2, 2))],
                          ),
                          child: Text(e.value, style: AppTextStyles.bodySmall.copyWith(color: active ? Colors.white : AppColors.textMid, fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ).animate().fadeIn(),

              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: NeuCard(
                    child: Column(
                      children: DummyData.fundamentalRights.asMap().entries.map((e) {
                        final r = e.value;
                        final isOpen = _expandedIndex == e.key;
                        return GestureDetector(
                          onTap: () => setState(() => _expandedIndex = isOpen ? -1 : e.key),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(border: e.key < DummyData.fundamentalRights.length - 1 ? const Border(bottom: BorderSide(color: AppColors.cardTint)) : null),
                            child: Column(
                              children: [
                                Row(children: [
                                  Icon(Icons.play_arrow, color: AppColors.gradBlue, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(r['title']!, style: AppTextStyles.labelMedium)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: AppColors.gradBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(50)),
                                    child: Text(r['articles']!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.gradBlue, fontSize: 10)),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(isOpen ? Icons.expand_less : Icons.expand_more, color: AppColors.textMid, size: 20),
                                ]),
                                if (isOpen)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12, left: 26),
                                    child: Text(r['desc']!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDark, height: 1.5)),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ).animate().fadeIn(delay: 100.ms),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(gradient: AppColors.dangerGradient, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.danger.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))]),
        child: const Icon(Icons.sos, color: Colors.white),
      ),
    );
  }
}
