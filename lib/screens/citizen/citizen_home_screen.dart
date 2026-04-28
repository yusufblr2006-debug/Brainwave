import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../widgets/neu_card.dart';
import '../../widgets/grad_button.dart';
import '../../widgets/pill_input.dart';
import '../../widgets/bottom_nav.dart';
import '../../providers/auth_provider.dart';

class CitizenHomeScreen extends ConsumerStatefulWidget {
  const CitizenHomeScreen({super.key});
  @override
  ConsumerState<CitizenHomeScreen> createState() => _CitizenHomeScreenState();
}

class _CitizenHomeScreenState extends ConsumerState<CitizenHomeScreen> {
  int _navIndex = 0;

  void _onNav(int i) {
    setState(() => _navIndex = i);
    switch (i) {
      case 0: break; // already home
      case 1: context.push('/ai-engine'); break;
      case 2: context.push('/advocate-call'); break;
      case 3: context.push('/marketplace'); break;
      case 4: break; // profile placeholder
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = ref.watch(userNameProvider);

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
                    // ─── TOP BAR ───
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), shape: BoxShape.circle),
                            child: const Icon(Icons.menu, color: AppColors.textDark),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Hello, $name 👋', style: AppTextStyles.labelLarge),
                                Text('Bengaluru, Karnataka', style: AppTextStyles.bodySmall),
                              ],
                            ),
                          ),
                          const Icon(Icons.notifications_none_rounded, color: AppColors.textMid),
                          const SizedBox(width: 16),
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person, color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms),

                    // ─── SEARCH BAR ───
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const PillInput(hintText: 'Search legal topics...', prefixIcon: Icons.search),
                    ).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: 24),

                    // ─── SECTION 1: EMERGENCY BANNER ───
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: NeuCard(
                        padding: EdgeInsets.zero,
                        onTap: () => context.push('/emergency'),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: AppColors.dangerGradient,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                                child: const Icon(Icons.shield, color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('EMERGENCY LEGAL AID', style: AppTextStyles.labelLarge.copyWith(color: Colors.white, letterSpacing: 1)),
                                    const SizedBox(height: 4),
                                    Text('Know your rights instantly', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                            ],
                          ),
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2500.ms, color: Colors.white24),
                    ),

                    const SizedBox(height: 28),

                    // ─── SECTION 2: QUICK ACTIONS 2×2 ───
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _quickAction(Icons.auto_awesome, 'AI Legal\nEngine', AppColors.gradBlue, () => context.push('/ai-engine'))),
                              const SizedBox(width: 16),
                              Expanded(child: _quickAction(Icons.camera_alt, 'Evidence\nAnalyzer', AppColors.gradGreen, () => context.push('/evidence'))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _quickAction(Icons.mic, 'Voice FIR\nReport', const Color(0xFF9333EA), () => context.push('/voice-fir'))),
                              const SizedBox(width: 16),
                              Expanded(child: _quickAction(Icons.balance, 'Know Your\nRights', const Color(0xFFD97706), () => context.push('/know-rights'))),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),

                    const SizedBox(height: 28),

                    // ─── SECTION 3: DIGITAL ADVOCATE HERO ───
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: NeuCard(
                        padding: EdgeInsets.zero,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: const Border(left: BorderSide(color: AppColors.gradBlue, width: 4)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.bolt, color: AppColors.gradBlue, size: 28),
                                    const SizedBox(width: 8),
                                    Text('Digital Advocate', style: AppTextStyles.headlineMedium),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'AI speaks on your behalf during police encounters in real-time.',
                                  style: AppTextStyles.bodyMedium,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Text('Status: READY', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 8),
                                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                GestureDetector(
                                  onTap: () => context.push('/advocate-call'),
                                  child: Container(
                                    height: 54, width: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: AppColors.dangerGradient,
                                      borderRadius: BorderRadius.circular(50),
                                      boxShadow: [BoxShadow(color: AppColors.danger.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
                                    ),
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.mic, color: Colors.white),
                                        const SizedBox(width: 8),
                                        Text('ACTIVATE ADVOCATE', style: AppTextStyles.buttonText.copyWith(letterSpacing: 1)),
                                      ],
                                    ),
                                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(end: 1.02, duration: 800.ms),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05),

                    const SizedBox(height: 28),

                    // ─── SECTION 4: ACTIVE CASE ───
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: NeuCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            Container(
                              height: 160,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                color: AppColors.gradBlue.withValues(alpha: 0.1),
                              ),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                          colors: [AppColors.gradBlue.withValues(alpha: 0.15), AppColors.gradBlue.withValues(alpha: 0.05)],
                                        ),
                                      ),
                                      child: const Center(child: Icon(Icons.balance, size: 64, color: AppColors.gradBlue)),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 12, left: 16,
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(50)),
                                          child: Text('● Active', style: AppTextStyles.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(color: const Color(0xFFD97706), borderRadius: BorderRadius.circular(50)),
                                          child: Text('MEDIUM Risk', style: AppTextStyles.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Property Dispute Resolution', style: AppTextStyles.labelLarge),
                                  const SizedBox(height: 4),
                                  Text('Adv. Rajesh Kumar · #MN-23109', style: AppTextStyles.bodySmall),
                                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: AppColors.cardTint)),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Progress: 40% (2/5 done)', style: AppTextStyles.bodySmall),
                                            const SizedBox(height: 8),
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(50),
                                              child: const LinearProgressIndicator(value: 0.4, minHeight: 8, backgroundColor: AppColors.cardTint, valueColor: AlwaysStoppedAnimation(AppColors.gradBlue)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      CircularPercentIndicator(
                                        radius: 30, lineWidth: 6, percent: 0.72,
                                        center: Text('72%', style: AppTextStyles.labelMedium),
                                        linearGradient: AppColors.primaryGradient,
                                        backgroundColor: AppColors.cardTint,
                                        circularStrokeCap: CircularStrokeCap.round,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.05),

                    const SizedBox(height: 28),

                    // ─── SECTION 5: TOP LAWYERS HORIZONTAL ───
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          const Icon(Icons.people, color: AppColors.gradBlue, size: 20),
                          const SizedBox(width: 8),
                          Text('Top Lawyers', style: AppTextStyles.headlineMedium),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => context.push('/marketplace'),
                            child: Text('See All →', style: AppTextStyles.bodySmall.copyWith(color: AppColors.gradBlue, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 190,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: DummyData.lawyers.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (_, i) {
                          final l = DummyData.lawyers[i];
                          return SizedBox(width: 200, child: _lawyerMiniCard(l));
                        },
                      ),
                    ).animate().fadeIn(delay: 500.ms),

                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // ─── BOTTOM NAV ───
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: BottomNav(currentIndex: _navIndex, onTap: _onNav),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickAction(IconData icon, String title, Color color, VoidCallback onTap) {
    return NeuCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.6)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 12),
          Text(title, style: AppTextStyles.labelMedium),
        ],
      ),
    );
  }

  Widget _lawyerMiniCard(Map<String, dynamic> l) {
    return NeuCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(color: AppColors.cardTint, shape: BoxShape.circle),
                child: const Icon(Icons.person, color: AppColors.gradBlue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l['name'] as String, style: AppTextStyles.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('🥇 ${l['badge']}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.gold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('${l['spec']}', style: AppTextStyles.bodySmall),
          Text('⭐ ${l['rating']} · ${l['experience']}', style: AppTextStyles.bodySmall),
          const Spacer(),
          GradButton(text: 'Consult', onPressed: () {}, small: true),
        ],
      ),
    );
  }
}
