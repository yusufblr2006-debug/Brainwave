import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../widgets/neu_card.dart';
import '../widgets/grad_button.dart';
import '../providers/app_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final initials = (provider.userName ?? 'User').split(' ').map((e) => e.substring(0, 1)).join();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: BlobBackground(
        child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            left: 20, right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  GestureDetector(onTap: () => context.pop(), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Color(0xFFB8D4E8), blurRadius: 8, offset: Offset(2, 2))]), child: const Icon(Icons.arrow_back_ios_new, size: 16))),
                  const SizedBox(width: 12),
                  Text('My Profile', style: AppTextStyles.headlineMedium),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // User Card
                    NeuCard(
                      child: Column(
                        children: [
                          Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 16),
                          Text(provider.userName ?? 'John Doe', style: AppTextStyles.labelLarge),
                          Text(provider.userEmail ?? 'john@example.com', style: AppTextStyles.bodyMedium),
                          if (provider.userPhone != null) Text(provider.userPhone!, style: AppTextStyles.bodySmall),
                          const SizedBox(height: 8),
                          Text('Session ID: ${provider.sessionId.substring(0, 8)}...', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMid.withValues(alpha: 0.5))),
                          const SizedBox(height: 16),
                          GradButton(text: 'Edit Profile', onPressed: () {}, small: true),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: 0.1),
                    
                    const SizedBox(height: 24),
                    
                    // Stats Row
                    Row(
                      children: [
                        _statCard('Total', '8', AppColors.gradBlue),
                        _statCard('Active', '3', AppColors.gold),
                        _statCard('Won', '5', AppColors.success),
                      ],
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 32),
                    
                    // Sections
                    _sectionTitle('Case History'),
                    const SizedBox(height: 12),
                    ...DummyData.cases.map((c) => _caseItem(context, c)),
                    
                    const SizedBox(height: 32),
                    
                    GradButton(
                      text: 'Sign Out', 
                      onPressed: () {
                        context.read<AppProvider>().logout();
                        context.go('/auth');
                      }, 
                      icon: Icons.logout,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String val, Color color) {
    return Expanded(
      child: NeuCard(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(val, style: AppTextStyles.displayMedium.copyWith(color: color)),
            Text(label, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Text(title, style: AppTextStyles.labelLarge),
        const Spacer(),
        Text('See All', style: AppTextStyles.bodySmall.copyWith(color: AppColors.gradBlue)),
      ],
    );
  }

  Widget _caseItem(BuildContext context, Map c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NeuCard(
        padding: EdgeInsets.zero,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.cardTint, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.folder_shared, color: AppColors.gradBlue),
            ),
            title: Text(c['title'], style: AppTextStyles.labelMedium),
            subtitle: Text('ID: ${c['id']} · ${c['filed']}', style: AppTextStyles.bodySmall),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (c['risk'] == 'HIGH' ? AppColors.danger : AppColors.success).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                c['risk'],
                style: TextStyle(
                  color: c['risk'] == 'HIGH' ? AppColors.danger : AppColors.success,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(color: AppColors.cardTint),
                    const SizedBox(height: 8),
                    _detailRow('Case Type', c['title'].toString().split(' — ').last),
                    const SizedBox(height: 8),
                    _detailRow('Status', 'Under Review'),
                    const SizedBox(height: 12),
                    Text('Last AI Analysis:', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      'Based on the provided documents, there is a strong case for property restoration under Section 441...',
                      style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 16),
                    GradButton(
                      text: 'View Full Case',
                      onPressed: () => context.push('/case-detail', extra: c),
                      small: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        Text(val, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.textDark)),
      ],
    );
  }
}
