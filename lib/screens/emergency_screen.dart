import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../widgets/neu_card.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlobBackground(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(gradient: AppColors.dangerGradient),
                child: Row(
                  children: [
                    GestureDetector(onTap: () => context.pop(), child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20)),
                    const SizedBox(width: 12),
                    const Icon(Icons.shield, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('Emergency Legal Aid', style: AppTextStyles.labelLarge.copyWith(color: Colors.white)),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    left: 20, right: 20, top: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4))),
                        child: Row(children: [
                          const Icon(Icons.info_outline, color: Color(0xFFF59E0B), size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text('Stay calm. You are protected by the Indian Constitution.', style: AppTextStyles.bodySmall.copyWith(color: const Color(0xFF92400E), fontWeight: FontWeight.w500))),
                        ]),
                      ).animate().fadeIn(),
                      const SizedBox(height: 28),
                      Text('WHAT IS YOUR SITUATION?', style: AppTextStyles.bodySmall.copyWith(letterSpacing: 1.5, fontWeight: FontWeight.w600, color: AppColors.textMid)),
                      const SizedBox(height: 16),
                      _tile(context, Icons.local_police, 'Police Stopped Me', const Color(0xFF2563EB), 'police'),
                      _tile(context, Icons.gavel, 'Arrest Situation', AppColors.danger, 'arrest'),
                      _tile(context, Icons.family_restroom, 'Domestic Violence', const Color(0xFF9333EA), 'domestic'),
                      _tile(context, Icons.language, 'Cyber Crime', const Color(0xFF0284C7), 'cyber'),
                      _tile(context, Icons.work, 'Workplace Issue', const Color(0xFFD97706), 'workplace'),
                      _tile(context, Icons.home_work, 'Property Dispute', const Color(0xFF059669), 'property'),
                      const SizedBox(height: 28),
                      Text('EMERGENCY HELPLINES', style: AppTextStyles.bodySmall.copyWith(letterSpacing: 1.5, fontWeight: FontWeight.w600, color: AppColors.textMid)),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: _helpCard(Icons.local_police, 'Police', '100')),
                        const SizedBox(width: 12),
                        Expanded(child: _helpCard(Icons.female, 'Women', '181')),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _helpCard(Icons.local_hospital, 'Ambulance', '108')),
                        const SizedBox(width: 12),
                        Expanded(child: _helpCard(Icons.child_care, 'Child', '1098')),
                      ]),
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

  Widget _tile(BuildContext ctx, IconData icon, String title, Color color, String id) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NeuCard(
        onTap: () => ctx.push('/rights-detail/$id'),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: AppTextStyles.labelMedium)),
          const Icon(Icons.chevron_right, color: AppColors.textMid),
        ]),
      ),
    );
  }

  Widget _helpCard(IconData icon, String title, String number) {
    return NeuCard(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Icon(icon, color: AppColors.gradBlue),
        const SizedBox(height: 6),
        Text(title, style: AppTextStyles.bodySmall),
        Text(number, style: AppTextStyles.headlineMedium.copyWith(color: AppColors.gradBlue)),
      ]),
    );
  }
}
