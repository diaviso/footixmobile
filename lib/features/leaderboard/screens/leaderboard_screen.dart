import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/avatar_utils.dart';

import '../../../data/models/leaderboard_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/service_providers.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/staggered_fade_in.dart';
import '../../../shared/widgets/scoreboard_header.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  List<LeaderboardEntryModel> _leaderboard = [];
  UserPositionModel? _userPosition;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final service = ref.read(leaderboardServiceProvider);
      final results = await Future.wait([
        service.getLeaderboard(),
        service.getMyPosition(),
      ]);
      if (!mounted) return;
      setState(() {
        _leaderboard = results[0] as List<LeaderboardEntryModel>;
        _userPosition = results[1] as UserPositionModel;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  String _getInitials(String firstName, String lastName) {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return '$f$l'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    if (_isLoading) {
      return Scaffold(
        body: SafeArea(child: _buildShimmer()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.error),
          const SizedBox(height: 16),
          const Text('Impossible de charger le classement'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _fetchData, child: const Text('Réessayer')),
        ])),
      );
    }

    final isUserInTop100 = _userPosition != null && _userPosition!.rank > 0 && _userPosition!.rank <= 100;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchData,
          color: AppColors.primary,
          child: CustomScrollView(slivers: [
            // Header
            SliverToBoxAdapter(child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16, right: 16, bottom: 8,
              ),
              child: Column(children: [
                Row(children: [
                  IconButton(
                    icon: const Icon(Icons.menu_rounded, size: 28),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                  const SizedBox(width: 4),
                ]),
                const SizedBox(height: 4),
                ScoreboardHeader(
                  title: 'Ligue Footix',
                  subtitle: 'Top 100 joueurs par nombre d\'étoiles',
                  icon: Icons.emoji_events_rounded,
                  live: true,
                ),
              ]),
            )),

            // User position card (if NOT in top 100)
            if (_userPosition != null && !isUserInTop100 && _userPosition!.rank > 0)
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${currentUser?.firstName ?? ''} ${currentUser?.lastName ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      const Text('Votre position', style: TextStyle(fontSize: 12, color: AppColors.textMutedLight)),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text.rich(TextSpan(children: [
                        TextSpan(text: '${_userPosition!.rank}',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        TextSpan(text: _userPosition!.rank == 1 ? 'er' : 'ème',
                            style: const TextStyle(fontSize: 13, color: AppColors.textMutedLight)),
                      ])),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF5A623)),
                        const SizedBox(width: 2),
                        Text('${_userPosition!.stars} étoiles',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMutedLight)),
                      ]),
                    ]),
                  ]),
                ),
              )),

            // Podium top 3
            if (_leaderboard.length >= 3)
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  // 2nd place
                  Expanded(child: Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: _buildPodiumCard(_leaderboard[1], currentUser?.id),
                  )),
                  const SizedBox(width: 8),
                  // 1st place
                  Expanded(child: _buildPodiumCard(_leaderboard[0], currentUser?.id)),
                  const SizedBox(width: 8),
                  // 3rd place
                  Expanded(child: Padding(
                    padding: const EdgeInsets.only(top: 36),
                    child: _buildPodiumCard(_leaderboard[2], currentUser?.id),
                  )),
                ]),
              )),

            // Top 100 header
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: Row(children: [
                const Icon(Icons.emoji_events_rounded, size: 20, color: Color(0xFFF5A623)),
                const SizedBox(width: 8),
                const Text('Top 100', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ]),
            )),

            // Leaderboard list
            if (_leaderboard.isEmpty)
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(children: [
                  Icon(Icons.emoji_events_rounded, size: 48, color: AppColors.textMutedLight.withValues(alpha: 0.4)),
                  const SizedBox(height: 8),
                  const Text('Aucun utilisateur', style: TextStyle(color: AppColors.textMutedLight)),
                ]),
              ))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                sliver: SliverList.separated(
                  itemCount: _leaderboard.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final entry = _leaderboard[index];
                    final isCurrentUser = entry.userId == currentUser?.id;
                    return StaggeredFadeIn(
                      index: index,
                      child: _buildLeaderboardRow(entry, isCurrentUser),
                    );
                  },
                ),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _buildPodiumCard(LeaderboardEntryModel entry, String? currentUserId) {
    final rank = entry.rank;
    final isFirst = rank == 1;
    final isCurrentUser = entry.userId == currentUserId;

    final Color ringColor;
    final Color badgeColor;
    final IconData badgeIcon;
    final double avatarRadius;

    switch (rank) {
      case 1:
        ringColor = const Color(0xFFD4AF37);
        badgeColor = const Color(0xFFD4AF37);
        badgeIcon = Icons.workspace_premium_rounded;
        avatarRadius = 32;
      case 2:
        ringColor = const Color(0xFF9CA3AF);
        badgeColor = const Color(0xFF9CA3AF);
        badgeIcon = Icons.military_tech_rounded;
        avatarRadius = 26;
      case 3:
        ringColor = const Color(0xFFD97706);
        badgeColor = const Color(0xFFD97706);
        badgeIcon = Icons.military_tech_rounded;
        avatarRadius = 24;
      default:
        ringColor = AppColors.borderLight;
        badgeColor = AppColors.textMutedLight;
        badgeIcon = Icons.military_tech_rounded;
        avatarRadius = 24;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: isFirst ? 16 : 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ringColor.withValues(alpha: 0.15),
            ringColor.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ringColor.withValues(alpha: 0.35), width: isFirst ? 2 : 1.5),
        boxShadow: [
          BoxShadow(
            color: ringColor.withValues(alpha: isFirst ? 0.2 : 0.1),
            blurRadius: isFirst ? 16 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Avatar with badge
        Stack(clipBehavior: Clip.none, children: [
          CircleAvatar(
            radius: avatarRadius,
            backgroundColor: ringColor.withValues(alpha: 0.15),
            child: ClipOval(
              child: SvgPicture.network(
                AvatarUtils.generateAvatarUrl(entry.userId),
                width: (avatarRadius - 3) * 2,
                height: (avatarRadius - 3) * 2,
                placeholderBuilder: (context) => Text(
                  _getInitials(entry.firstName, entry.lastName),
                  style: TextStyle(
                    color: ringColor,
                    fontWeight: FontWeight.bold,
                    fontSize: isFirst ? 18 : 14,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -4, right: -4,
            child: Container(
              width: isFirst ? 26 : 22,
              height: isFirst ? 26 : 22,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: badgeColor.withValues(alpha: 0.4), blurRadius: 4)],
              ),
              child: Icon(badgeIcon, size: isFirst ? 16 : 13, color: Colors.white),
            ),
          ),
        ]),
        SizedBox(height: isFirst ? 10 : 8),

        // Rank number
        Text('$rank', style: TextStyle(
          fontSize: isFirst ? 26 : 20,
          fontWeight: FontWeight.bold,
          color: ringColor,
        )),

        // Name
        Text(
          '${entry.firstName} ${entry.lastName.isNotEmpty ? '${entry.lastName[0]}.' : ''}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: isFirst ? 13 : 11,
            color: isCurrentUser ? AppColors.primary : null,
          ),
          maxLines: 1, overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),

        // Stars
        Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF5A623)),
          const SizedBox(width: 2),
          Text('${entry.stars}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }

  Widget _buildShimmer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        const SizedBox(height: 16),
        // Podium shimmer
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ShimmerLoading(height: 100, width: 80, borderRadius: 12),
          const SizedBox(width: 12),
          ShimmerLoading(height: 120, width: 80, borderRadius: 12),
          const SizedBox(width: 12),
          ShimmerLoading(height: 90, width: 80, borderRadius: 12),
        ]),
        const SizedBox(height: 24),
        ...List.generate(6, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ShimmerLoading(height: 56, borderRadius: 12),
        )),
      ]),
    );
  }

  Widget _buildLeaderboardRow(LeaderboardEntryModel entry, bool isCurrentUser) {
    final isTop3 = entry.rank <= 3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.primary.withValues(alpha: 0.06)
            : (isTop3 ? const Color(0xFFF5A623).withValues(alpha: 0.04) : null),
        borderRadius: BorderRadius.circular(16),
        border: isCurrentUser
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5)
            : (isTop3 ? Border.all(color: const Color(0xFFF5A623).withValues(alpha: 0.15)) : null),
        boxShadow: isCurrentUser
            ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 2))]
            : (isTop3 ? [BoxShadow(color: const Color(0xFFF5A623).withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))] : []),
      ),
      child: Row(children: [
        // Rank
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            gradient: isTop3
                ? const LinearGradient(colors: [Color(0xFFF5A623), Color(0xFFD97706)])
                : null,
            color: isTop3 ? null : AppColors.neutral50,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isTop3
                ? [BoxShadow(color: const Color(0xFFF5A623).withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))]
                : [],
          ),
          child: Center(child: isTop3
              ? _getRankIcon(entry.rank)
              : Text('${entry.rank}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
        ),
        const SizedBox(width: 10),

        // Avatar
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: ClipOval(
            child: SvgPicture.network(
              AvatarUtils.generateAvatarUrl(entry.userId),
              width: 36,
              height: 36,
              placeholderBuilder: (context) => Text(
                _getInitials(entry.firstName, entry.lastName),
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Name
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(child: Text(
              '${entry.firstName} ${entry.lastName}',
              style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14,
                color: isCurrentUser ? AppColors.primary : null,
              ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            )),
            if (isCurrentUser)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Vous', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
          ]),
          Text('Rang #${entry.rank}', style: const TextStyle(fontSize: 11, color: AppColors.textMutedLight)),
        ])),

        // Stars badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF5A623)),
            const SizedBox(width: 4),
            Text('${entry.stars}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFB45309))),
          ]),
        ),
      ]),
    );
  }

  Widget _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 22);
      case 2:
        return const Icon(Icons.military_tech_rounded, color: Colors.white, size: 22);
      case 3:
        return const Icon(Icons.military_tech_rounded, color: Colors.white, size: 22);
      default:
        return Text('$rank', style: const TextStyle(fontWeight: FontWeight.bold));
    }
  }
}
