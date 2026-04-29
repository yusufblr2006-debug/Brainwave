import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../widgets/neu_card.dart';
import '../widgets/grad_button.dart';

class LawyerProfileScreen extends StatelessWidget {
  final Map lawyer;
  const LawyerProfileScreen({super.key, required this.lawyer});

  @override
  Widget build(BuildContext context) {
    final initials = lawyer['name'].split(' ').map((e) => e.substring(0, 1)).join();
    final winRate = ((lawyer['won'] / lawyer['total']) * 100).toStringAsFixed(1);

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
                  Text(lawyer['name'], style: AppTextStyles.headlineMedium),
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
                      // Top Card
                      NeuCard(
                        child: Column(
                          children: [
                            Container(
                              width: 70, height: 70,
                              decoration: BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 16),
                            Text(lawyer['name'], style: AppTextStyles.labelLarge),
                            Text('${lawyer['spec']} · ${lawyer['city']}', style: AppTextStyles.bodyMedium),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text('${lawyer['rating']} / 5.0', style: AppTextStyles.labelMedium),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(50)),
                                  child: Text(lawyer['badge'], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn().slideY(begin: 0.1),

                      const SizedBox(height: 24),

                      // Stats row
                      Row(
                        children: [
                          _stat('Cases', lawyer['total'].toString()),
                          _stat('Won', lawyer['won'].toString()),
                          _stat('Win%', '$winRate%'),
                          _stat('Exp', lawyer['experience'].toString().split(' ')[0]),
                        ],
                      ).animate().fadeIn(delay: 200.ms),

                      const SizedBox(height: 32),

                      Text('About', style: AppTextStyles.labelLarge),
                      const SizedBox(height: 12),
                      Text(lawyer['about'] ?? lawyer['bio'], style: AppTextStyles.bodyMedium),

                      const SizedBox(height: 24),

                      Text('Expertise', style: AppTextStyles.labelLarge),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: [
                          _chip(lawyer['spec']),
                          _chip('IPC'),
                          _chip('High Court'),
                          _chip('Bail Matters'),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Price Card
                      NeuCard(
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Consultation Fee', style: AppTextStyles.bodySmall),
                                Text('₹${lawyer['price']}', style: AppTextStyles.displayMedium.copyWith(color: AppColors.textDark)),
                              ],
                            ),
                            const Spacer(),
                            GradButton(
                              text: 'Book Now', 
                              onPressed: () => context.push('/payment', extra: lawyer),
                              small: true,
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 400.ms),
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

  Widget _stat(String label, String val) {
    return Expanded(
      child: NeuCard(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(val, style: AppTextStyles.labelMedium.copyWith(color: AppColors.gradBlue)),
            Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMid)),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(50), border: Border.all(color: AppColors.cardTint)),
    child: Text(label, style: AppTextStyles.bodySmall),
  );
}
