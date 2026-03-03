import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class AppBadge extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;

  const AppBadge({
    super.key,
    required this.text,
    this.backgroundColor,
    this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primarySurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor ?? AppColors.primary),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor ?? AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class DifficultyBadge extends StatelessWidget {
  final String difficulty;

  const DifficultyBadge({super.key, required this.difficulty});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    switch (difficulty) {
      case 'FACILE':
        bg = AppColors.easyBg;
        text = AppColors.easy;
        break;
      case 'MOYEN':
        bg = AppColors.mediumBg;
        text = AppColors.medium;
        break;
      case 'DIFFICILE':
        bg = AppColors.hardBg;
        text = AppColors.hard;
        break;
      default:
        bg = AppColors.neutral100;
        text = AppColors.neutral600;
    }
    return AppBadge(text: difficulty, backgroundColor: bg, textColor: text);
  }
}
