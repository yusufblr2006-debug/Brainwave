import 'dart:ui';
import 'package:flutter/material.dart';

class AppColors {
  static const bgBase = Color(0xFFD6EEF8);
  static const gradBlue = Color(0xFF2563EB);
  static const gradGreen = Color(0xFF34D399);
  static const blobBlue = Color(0xFF1D4ED8);
  static const cardWhite = Color(0xFFFFFFFF);
  static const cardTint = Color(0xFFF0F7FF);
  static const textDark = Color(0xFF1E293B);
  static const textMid = Color(0xFF64748B);
  static const danger = Color(0xFFDC2626);
  static const success = Color(0xFF10B981);
  static const gold = Color(0xFFCFAB52);

  static const primaryGradient = LinearGradient(colors: [gradBlue, gradGreen]);
  static const dangerGradient = LinearGradient(colors: [danger, Color(0xFFF97316)]);
}

class AppTextStyles {
  static const _font = 'Inter';
  static const _fallbacks = ['Arial', 'Helvetica', 'sans-serif'];

  static final displayLarge = TextStyle(fontFamily: _font, fontFamilyFallback: _fallbacks, fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textDark, letterSpacing: -0.5);
  static final displayMedium = TextStyle(fontFamily: _font, fontFamilyFallback: _fallbacks, fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textDark, letterSpacing: -0.5);
  static final displaySmall = TextStyle(fontFamily: _font, fontFamilyFallback: _fallbacks, fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textDark);
  
  static final headlineMedium = TextStyle(fontFamily: _font, fontFamilyFallback: _fallbacks, fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark);
  
  static final labelLarge = TextStyle(fontFamily: _font, fontFamilyFallback: _fallbacks, fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark);
  static final labelMedium = TextStyle(fontFamily: _font, fontFamilyFallback: _fallbacks, fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark);
  
  static final bodyLarge = TextStyle(fontFamily: _font, fontFamilyFallback: _fallbacks, fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textDark);
  static final bodyMedium = TextStyle(fontFamily: _font, fontFamilyFallback: _fallbacks, fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textMid);
  static final bodySmall = TextStyle(fontFamily: _font, fontFamilyFallback: _fallbacks, fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textMid);

  static final buttonText = TextStyle(fontFamily: _font, fontFamilyFallback: _fallbacks, fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bgBase,
      primaryColor: AppColors.gradBlue,
      textTheme: const TextTheme().apply(
        fontFamily: 'Inter',
        bodyColor: AppColors.textDark,
        displayColor: AppColors.textDark,
      ),
      colorScheme: const ColorScheme.light(
        primary: AppColors.gradBlue,
        secondary: AppColors.gradGreen,
        error: AppColors.danger,
        surface: AppColors.bgBase,
      ),
    );
  }
}

class BlobBackground extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const BlobBackground({super.key, required this.child, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: isDark ? const Color(0xFF0F172A) : AppColors.bgBase),
        Positioned(
          top: -60, left: -40,
          child: _blob(280, isDark ? [AppColors.blobBlue, AppColors.danger] : [AppColors.gradBlue, AppColors.gradGreen]),
        ),
        Positioned(
          bottom: -80, right: -60,
          child: _blob(260, isDark ? [AppColors.danger, AppColors.blobBlue] : [AppColors.gradGreen, AppColors.gradBlue]),
        ),
        child,
      ],
    );
  }

  Widget _blob(double size, List<Color> colors) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(colors: colors),
    ),
  );
}

class FrostedGlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const FrostedGlassPanel({super.key, required this.child, this.padding = const EdgeInsets.all(24)});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0xCCFFFFFF), // 80% white
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0x40FFFFFF), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

// PillInput → lib/widgets/pill_input.dart
// GradButton → lib/widgets/grad_button.dart
