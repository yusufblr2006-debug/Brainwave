import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../widgets/neu_card.dart';
import '../../widgets/pill_input.dart';
import '../../widgets/grad_button.dart';

class LawyerMarketplaceScreen extends StatefulWidget {
  const LawyerMarketplaceScreen({super.key});
  @override
  State<LawyerMarketplaceScreen> createState() => _LawyerMarketplaceScreenState();
}

class _LawyerMarketplaceScreenState extends State<LawyerMarketplaceScreen> {
  int _activeFilter = 0;
  final _filters = ['All', 'Criminal', 'Property', 'Family', 'Corporate', 'Cyber'];

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
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Lawyer Marketplace', style: AppTextStyles.headlineMedium),
                    Text('Find experts across India', style: AppTextStyles.bodySmall),
                  ]),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const PillInput(hintText: 'Search lawyers...', prefixIcon: Icons.search),
              ),
              const SizedBox(height: 16),
              // Filters
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.asMap().entries.map((e) {
                      final active = e.key == _activeFilter;
                      return GestureDetector(
                        onTap: () => setState(() => _activeFilter = e.key),
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
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: DummyData.lawyers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (_, i) {
                    final l = DummyData.lawyers[i];
                    final badgeColor = l['badge'] == 'Gold' ? AppColors.gold : (l['badge'] == 'Platinum' ? AppColors.gradBlue : AppColors.textMid);
                    return NeuCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 56, height: 56, decoration: const BoxDecoration(color: AppColors.cardTint, shape: BoxShape.circle), child: const Icon(Icons.person, color: AppColors.gradBlue, size: 28)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Expanded(child: Text(l['name'] as String, style: AppTextStyles.labelMedium)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(50)),
                                    child: Text('🏅 ${l['badge']}', style: AppTextStyles.bodySmall.copyWith(color: badgeColor, fontSize: 10, fontWeight: FontWeight.w600)),
                                  ),
                                ]),
                                const SizedBox(height: 4),
                                Text(l['spec'] as String, style: AppTextStyles.bodySmall),
                                Text('⭐ ${l['rating']} · ${l['experience']} · ${l['city']}', style: AppTextStyles.bodySmall),
                                const SizedBox(height: 4),
                                Row(children: [
                                  Text('🏆 ${l['won']}/${l['total']} won', style: AppTextStyles.bodySmall.copyWith(color: AppColors.success, fontWeight: FontWeight.w500)),
                                  const Spacer(),
                                  GradButton(text: 'Consult →', onPressed: () {}, small: true),
                                ]),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: Duration(milliseconds: 80 * i)).slideX(begin: 0.03);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
