import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/avatar_utils.dart';

/// FIFA Ultimate Team-style card for profiles and leaderboard.
enum PlayerCardTier { gold, silver, bronze, standard }

class PlayerCard extends StatelessWidget {
  final String name;
  final String? avatar;
  final String? userId;
  final int? rank;
  final int? stars;
  final Map<String, String>? stats;
  final PlayerCardTier tier;
  final double? width;

  const PlayerCard({
    super.key,
    required this.name,
    this.avatar,
    this.userId,
    this.rank,
    this.stars,
    this.stats,
    this.tier = PlayerCardTier.standard,
    this.width,
  });

  LinearGradient get _gradient {
    switch (tier) {
      case PlayerCardTier.gold:
        return const LinearGradient(
          colors: [Color(0xFFD4AF37), Color(0xFFB8960F), Color(0xFFD4AF37)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case PlayerCardTier.silver:
        return const LinearGradient(
          colors: [Color(0xFFC0C0C0), Color(0xFFA0A0A0), Color(0xFFC0C0C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case PlayerCardTier.bronze:
        return const LinearGradient(
          colors: [Color(0xFFCD7F32), Color(0xFFA0522D), Color(0xFFCD7F32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case PlayerCardTier.standard:
        return const LinearGradient(
          colors: [Color(0xFF1B2B40), Color(0xFF0D1525), Color(0xFF1B2B40)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Color get _ringColor {
    switch (tier) {
      case PlayerCardTier.gold:
        return const Color(0xFFD4AF37);
      case PlayerCardTier.silver:
        return const Color(0xFFC0C0C0);
      case PlayerCardTier.bronze:
        return const Color(0xFFCD7F32);
      case PlayerCardTier.standard:
        return AppColors.primaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardWidth = width ?? 160.0;
    final cardHeight = cardWidth * 1.35;
    final avatarUrl = AvatarUtils.getAvatarUrl(avatar, userId ?? '');

    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: _gradient,
          boxShadow: [
            BoxShadow(
              color: _ringColor.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Rank badge
            if (rank != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: _ringColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: cardWidth * 0.2,
                backgroundColor: _ringColor.withValues(alpha: 0.2),
                backgroundImage: NetworkImage(avatarUrl),
              ),
            ),

            const SizedBox(height: 10),

            // Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),

            // Stars
            if (stars != null) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, color: AppColors.accent, size: 14),
                  const SizedBox(width: 3),
                  Text(
                    '$stars',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],

            // Stats
            if (stats != null && stats!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: stats!.entries.take(4).map((e) {
                    return Column(
                      children: [
                        Text(
                          e.value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text(
                          e.key,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
