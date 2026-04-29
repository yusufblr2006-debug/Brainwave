import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Neumorphic pill-shaped text field with soft shadows.
class PillInput extends StatelessWidget {
  final String hintText;
  final bool isPassword;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final Widget? suffix;
  final int maxLines;
  final int minLines;
  final ValueChanged<String>? onChanged;

  const PillInput({
    super.key,
    required this.hintText,
    this.isPassword = false,
    this.controller,
    this.prefixIcon,
    this.suffix,
    this.maxLines = 1,
    this.minLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(maxLines > 1 ? 20 : 50),
        boxShadow: const [
          BoxShadow(color: Color(0xFFB8D4E8), blurRadius: 8, offset: Offset(3, 3)),
          BoxShadow(color: Colors.white, blurRadius: 8, offset: Offset(-3, -3)),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        maxLines: maxLines,
        minLines: minLines,
        onChanged: onChanged,
        style: AppTextStyles.bodyLarge,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTextStyles.bodyMedium,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: maxLines > 1 ? 16 : 16),
          prefixIcon: prefixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: Icon(prefixIcon, color: AppColors.textMid, size: 20),
                )
              : null,
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: suffix,
        ),
      ),
    );
  }
}
