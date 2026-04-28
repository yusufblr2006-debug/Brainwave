import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Universal Neumorphic card used by every screen.
/// Wraps child in white, rounded container with dual soft shadows.
class NeuCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const NeuCard({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.onTap});

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0xFFB8D4E8), offset: Offset(6, 6), blurRadius: 16),
          BoxShadow(color: Color(0xFFFFFFFF), offset: Offset(-6, -6), blurRadius: 16),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }
    return content;
  }
}
