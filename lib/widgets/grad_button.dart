import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Gradient pill button — every primary action uses this.
class GradButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool small;

  const GradButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        height: small ? 40 : 54,
        padding: small ? const EdgeInsets.symmetric(horizontal: 16) : null,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: AppColors.gradBlue.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: small ? MainAxisSize.min : MainAxisSize.max,
          children: isLoading
              ? [const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))]
              : [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: small ? 16 : 20),
                    const SizedBox(width: 8),
                  ],
                  Text(text, style: AppTextStyles.buttonText.copyWith(fontSize: small ? 13 : 16)),
                ],
        ),
      ),
    );
  }
}
