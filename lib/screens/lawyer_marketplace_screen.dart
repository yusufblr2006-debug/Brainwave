import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../widgets/neu_card.dart';
import '../widgets/pill_input.dart';
import '../widgets/grad_button.dart';
import '../services/api_service.dart';
import '../models/lawyer.dart';

class LawyerMarketplaceScreen extends StatefulWidget {
  const LawyerMarketplaceScreen({super.key});
  @override
  State<LawyerMarketplaceScreen> createState() => _LawyerMarketplaceScreenState();
}

class _LawyerMarketplaceScreenState extends State<LawyerMarketplaceScreen> {
  int _activeFilter = 0;
  final _filters = ['All', 'Criminal', 'Property', 'Family', 'Corporate', 'Cyber'];
  List<Lawyer> _lawyers = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchLawyers();
  }

  void _showError(BuildContext ctx, dynamic e) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      backgroundColor: const Color(0xFFDC2626),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Text(e.toString().replaceAll('Exception:', '').trim()),
    ));
  }

  Future<void> _fetchLawyers() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.matchLawyer(_filters[_activeFilter]);
      if (mounted) setState(() => _lawyers = res);
    } catch (e) {
      if (mounted) {
        _showError(context, e);
        // Fallback
        setState(() {
          _lawyers = DummyData.lawyers.map((l) => Lawyer.fromJson(Map<String, dynamic>.from(l))).toList();
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onFilter(int idx) {
    setState(() => _activeFilter = idx);
    _fetchLawyers();
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
                        onTap: () => _onFilter(e.key),
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
                child: _loading
                  ? Center(child: Text('Loading lawyers...', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gradBlue)))
                        .animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(color: AppColors.gradBlue.withValues(alpha: 0.3))
                  : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _lawyers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (_, i) {
                    final l = _lawyers[i];
                    final badgeStr = l.rating > 4.8 ? 'Platinum' : (l.rating > 4.5 ? 'Gold' : 'Silver');
                    final badgeColor = badgeStr == 'Gold' ? AppColors.gold : (badgeStr == 'Platinum' ? AppColors.gradBlue : AppColors.textMid);
                    final lawyerMap = {
                      'name': l.name, 'spec': l.specialization, 'city': l.city,
                      'rating': l.rating, 'won': 0, 'total': 0, 'badge': badgeStr,
                      'experience': '—',
                      'about': 'Experienced ${l.specialization} advocate in ${l.city}.',
                      'price': 2000,
                    };
                    return GestureDetector(
                      onTap: () => context.push('/lawyer-profile', extra: lawyerMap),
                      child: NeuCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(width: 50, height: 50, decoration: const BoxDecoration(color: AppColors.cardTint, shape: BoxShape.circle), child: const Icon(Icons.person, color: AppColors.gradBlue, size: 24)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Flexible(child: Text(l.name, style: AppTextStyles.labelMedium, overflow: TextOverflow.ellipsis)),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(50)),
                                      child: Text('🏆 $badgeStr', style: AppTextStyles.bodySmall.copyWith(color: badgeColor, fontSize: 10, fontWeight: FontWeight.w600)),
                                    ),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text(l.specialization, style: AppTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text('⭐ ${l.rating} · 10 yrs · ${l.city}', style: AppTextStyles.bodySmall),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 90,
                              child: GradButton(text: 'Consult', onPressed: () => context.push('/lawyer-profile', extra: lawyerMap), small: true),
                            ),
                          ],
                        ),
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
