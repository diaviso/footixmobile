import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_design.dart';

/// Match ticket-style card for quiz/duel listings.
class MatchCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String difficulty; // 'FACILE', 'MOYEN', 'DIFFICILE'
  final double? score;
  final int? stars;
  final int? timeLimit;
  final int? passingScore;
  final int? questionCount;
  final bool isPremium;
  final bool isLocked;
  final bool isPassed;
  final bool isFeatured;
  final String? ribbon;
  final VoidCallback? onTap;
  final Widget? trailing;

  const MatchCard({
    super.key,
    required this.title,
    this.subtitle,
    this.difficulty = 'MOYEN',
    this.score,
    this.stars,
    this.timeLimit,
    this.passingScore,
    this.questionCount,
    this.isPremium = false,
    this.isLocked = false,
    this.isPassed = false,
    this.isFeatured = false,
    this.ribbon,
    this.onTap,
    this.trailing,
  });

  Color get _accentColor {
    switch (difficulty) {
      case 'FACILE':
        return AppColors.easy;
      case 'DIFFICILE':
        return AppColors.hard;
      default:
        return AppColors.medium;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? const Color(0xFF0D1525) : Colors.white,
          border: Border.all(
            color: isPassed
                ? AppColors.success.withValues(alpha: 0.3)
                : isDark
                    ? const Color(0xFF1B2B40)
                    : const Color(0xFFDCE6F0),
          ),
          boxShadow: AppDesign.softShadow(),
        ),
        child: Stack(
          children: [
            // Left accent band
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: _accentColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header row
                  Row(
                    children: [
                      // Difficulty badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          difficulty,
                          style: TextStyle(
                            color: _accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Stars
                      if (stars != null)
                        Row(
                          children: [
                            Icon(Icons.star_rounded, size: 14, color: AppColors.accent),
                            const SizedBox(width: 2),
                            Text(
                              '$stars',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? const Color(0xFFE2E8F5) : const Color(0xFF0A1628),
                      fontSize: isFeatured ? 17 : 15,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: const Color(0xFF5E7A9A),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Stats row
                  Row(
                    children: [
                      if (timeLimit != null) _StatChip(
                        icon: Icons.timer_outlined,
                        text: '${timeLimit}min',
                      ),
                      if (questionCount != null) _StatChip(
                        icon: Icons.quiz_outlined,
                        text: '$questionCount Q',
                      ),
                      if (passingScore != null) _StatChip(
                        icon: Icons.check_circle_outline,
                        text: '$passingScore%',
                      ),
                      const Spacer(),
                      if (trailing != null) trailing!,
                    ],
                  ),

                  // Score bar
                  if (score != null) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (score! / 100).clamp(0.0, 1.0),
                        backgroundColor: isDark ? const Color(0xFF111B2E) : const Color(0xFFEFF3F7),
                        color: score! >= (passingScore ?? 70)
                            ? AppColors.success
                            : AppColors.error,
                        minHeight: 4,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Locked overlay
            if (isLocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.6),
                  ),
                  child: Center(
                    child: Icon(Icons.lock_rounded, color: const Color(0xFF5E7A9A), size: 28),
                  ),
                ),
              ),

            // Ribbon
            if (ribbon != null)
              Positioned(
                top: 0,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Text(
                    ribbon!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _StatChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF5E7A9A)),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF5E7A9A),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
