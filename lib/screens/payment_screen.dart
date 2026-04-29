import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../config/theme.dart';
import '../widgets/neu_card.dart';
import '../widgets/pill_input.dart';
import '../widgets/grad_button.dart';

class PaymentScreen extends StatefulWidget {
  final Map lawyer;
  const PaymentScreen({super.key, required this.lawyer});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _method = 'upi';
  bool _loading = false;

  void _handlePay() {
    if (mounted) setState(() => _loading = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSuccess(context);
    });
  }

  void _showSuccess(BuildContext context) {
    if (!mounted) return;
    // Generate a dedicated session for this lawyer consultation
    final sessionId = const Uuid().v4();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 64),
            const SizedBox(height: 16),
            Text('Payment Successful!',
                style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            Text(
              'Consultation booked with ${widget.lawyer['name']}',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 24),
            GradButton(
              text: 'Start Chat',
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/lawyer-chat',
                    extra: {
                      'lawyer': Map<String, dynamic>.from(widget.lawyer),
                      'sessionId': sessionId,
                    });
              },
            ),
          ],
        ),
      ),
    );
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
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0xFFB8D4E8),
                              blurRadius: 8,
                              offset: Offset(2, 2))
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Book Consultation',
                      style: AppTextStyles.headlineMedium),
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
                      // Lawyer Card
                      NeuCard(
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.gradBlue,
                              radius: 24,
                              child: Text(
                                widget.lawyer['name'].substring(0, 1),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.lawyer['name'],
                                      style: AppTextStyles.labelMedium),
                                  Text(widget.lawyer['spec'] ?? '',
                                      style: AppTextStyles.bodySmall),
                                ],
                              ),
                            ),
                            Text('₹${widget.lawyer['price']}',
                                style: AppTextStyles.labelLarge
                                    .copyWith(color: AppColors.gradBlue)),
                          ],
                        ),
                      ).animate().fadeIn(),

                      const SizedBox(height: 32),
                      Text('Select Payment Method',
                          style: AppTextStyles.labelLarge),
                      const SizedBox(height: 16),

                      _methodOption(
                          'upi', 'UPI (GPay / PhonePe)', Icons.account_balance_wallet_outlined),
                      _methodOption(
                          'card', 'Credit / Debit Card', Icons.credit_card_outlined),
                      _methodOption(
                          'net', 'Net Banking', Icons.language_outlined),

                      const SizedBox(height: 32),

                      if (_method == 'upi')
                        const PillInput(
                            hintText: 'Enter UPI ID',
                            prefixIcon: Icons.alternate_email)
                      else if (_method == 'card')
                        Column(children: [
                          const PillInput(
                              hintText: 'Card Number',
                              prefixIcon: Icons.credit_card),
                          const SizedBox(height: 12),
                          Row(children: [
                            const Expanded(
                                child: PillInput(
                                    hintText: 'Expiry',
                                    prefixIcon: Icons.date_range)),
                            const SizedBox(width: 12),
                            const Expanded(
                                child: PillInput(
                                    hintText: 'CVV', prefixIcon: Icons.lock)),
                          ]),
                        ]),

                      const SizedBox(height: 40),
                      GradButton(
                          text: 'Pay ₹${widget.lawyer['price']}',
                          onPressed: _handlePay,
                          isLoading: _loading),
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

  Widget _methodOption(String val, String label, IconData icon) {
    bool isSelected = _method == val;
    return GestureDetector(
      onTap: () => setState(() => _method = val),
      child: NeuCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? AppColors.gradBlue : AppColors.textMid),
            const SizedBox(width: 12),
            Text(label,
                style: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected
                        ? AppColors.textDark
                        : AppColors.textMid,
                    fontWeight:
                        isSelected ? FontWeight.bold : null)),
            const Spacer(),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: isSelected
                  ? AppColors.gradBlue
                  : AppColors.textMid.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}
