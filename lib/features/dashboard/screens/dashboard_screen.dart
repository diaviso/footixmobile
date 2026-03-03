import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/avatar_utils.dart';
import '../../../core/theme/app_design.dart';
import '../../../data/models/dashboard_model.dart';
import '../../../data/models/leaderboard_model.dart';
import '../../../data/models/quiz_model.dart';
import '../../../navigation/app_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/service_providers.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/staggered_fade_in.dart';
import '../../../shared/widgets/scoreboard_header.dart';
import '../../../shared/widgets/stamina_bar.dart';

/// Dashboard data holder
class _DashboardData {
  final UserStatsModel stats;
  final UserPositionModel position;
  final List<QuizAttemptModel> recentAttempts;
  final Map<String, dynamic> progress;

  const _DashboardData({
    required this.stats,
    required this.position,
    required this.recentAttempts,
    required this.progress,
  });
}

/// Riverpod provider that fetches all dashboard data in parallel.
/// Watches auth state so it auto-refreshes after login.
final _dashboardDataProvider = FutureProvider.autoDispose<_DashboardData?>((ref) async {
  // Wait until user is authenticated before fetching
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  if (!isAuthenticated) return null;

  final dashboardService = ref.watch(dashboardServiceProvider);
  final quizzesService = ref.watch(quizzesServiceProvider);
  final leaderboardService = ref.watch(leaderboardServiceProvider);

  // Fetch each independently to isolate errors
  UserStatsModel? stats;
  UserPositionModel? position;
  List<QuizAttemptModel> attempts = [];
  Map<String, dynamic> progress = {};

  try {
    stats = await dashboardService.getUserStats();
    debugPrint('[Dashboard] Stats OK: quizzes=${stats.totalQuizzes}');
  } catch (e) {
    debugPrint('[Dashboard] Stats ERROR: $e');
  }

  try {
    position = await leaderboardService.getMyPosition();
    debugPrint('[Dashboard] Position OK: rank=${position.rank}');
  } catch (e) {
    debugPrint('[Dashboard] Position ERROR: $e');
  }

  try {
    attempts = await quizzesService.getUserAttempts();
    debugPrint('[Dashboard] Attempts OK: count=${attempts.length}');
  } catch (e) {
    debugPrint('[Dashboard] Attempts ERROR: $e');
  }

  try {
    progress = await dashboardService.getUserProgress();
    debugPrint('[Dashboard] Progress OK: $progress');
  } catch (e) {
    debugPrint('[Dashboard] Progress ERROR: $e');
  }

  return _DashboardData(
    stats: stats ?? const UserStatsModel(
      totalStars: 0, uniqueQuizzesCompleted: 0, quizzesPassed: 0,
      totalQuizzes: 0, averageScore: 0, totalAttempts: 0,
    ),
    position: position ?? const UserPositionModel(rank: 0, stars: 0, totalUsers: 0),
    recentAttempts: attempts.take(5).toList(),
    progress: progress,
  );
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final dashboardAsync = ref.watch(_dashboardDataProvider);

    return dashboardAsync.when(
      loading: () => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            const SizedBox(height: 16),
            ShimmerLoading(height: 140, borderRadius: 24),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: ShimmerLoading(height: 110, borderRadius: 18)),
              const SizedBox(width: 12),
              Expanded(child: ShimmerLoading(height: 110, borderRadius: 18)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ShimmerLoading(height: 110, borderRadius: 18)),
              const SizedBox(width: 12),
              Expanded(child: ShimmerLoading(height: 110, borderRadius: 18)),
            ]),
            const SizedBox(height: 16),
            ShimmerLoading(height: 200, borderRadius: 18),
          ]),
        ),
      ),
      error: (error, stack) {
        debugPrint('[Dashboard] UI error: $error');
        debugPrint('[Dashboard] UI stack: $stack');
        return _ErrorView(
          onRetry: () => ref.invalidate(_dashboardDataProvider),
          errorMessage: error.toString(),
        );
      },
      data: (data) {
        if (data == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(_dashboardDataProvider);
          },
          child: _DashboardContent(
            user: user,
            stats: data.stats,
            position: data.position,
            recentAttempts: data.recentAttempts,
            progress: data.progress,
          ),
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  final String? errorMessage;
  const _ErrorView({required this.onRetry, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 64, color: AppColors.textMutedLight),
            const SizedBox(height: 16),
            Text(
              errorMessage ?? 'Impossible de charger le tableau de bord',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final UserModel? user;
  final UserStatsModel stats;
  final UserPositionModel position;
  final List<QuizAttemptModel> recentAttempts;
  final Map<String, dynamic> progress;

  const _DashboardContent({
    required this.user,
    required this.stats,
    required this.position,
    required this.recentAttempts,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final successRate = stats.totalAttempts > 0
        ? (stats.quizzesPassed / stats.totalAttempts) * 100
        : 0.0;

    final topPadding = MediaQuery.of(context).padding.top;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 16),
      children: [
        // ── Menu Button ──
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            icon: const Icon(Icons.menu_rounded, size: 28),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Menu',
          ),
        ),
        const SizedBox(height: 4),

        // ── Scoreboard Header ──
        StaggeredFadeIn(
          index: -1,
          child: ScoreboardHeader(
            title: 'Match Center',
            subtitle: 'Votre tableau de bord football',
            icon: Icons.sports_soccer,
            live: true,
          ),
        ),
        const SizedBox(height: 16),

        // ── Welcome Card ──
        StaggeredFadeIn(
          index: 0,
          child: _WelcomeCard(user: user, stars: user?.stars ?? 0, rank: position.rank),
        ),
        const SizedBox(height: 20),

        // ── 4 Stat Cards ──
        StaggeredFadeIn(
          index: 1,
          child: _StatCardsGrid(
            stats: stats,
            position: position,
            successRate: successRate,
            userStars: user?.stars ?? 0,
          ),
        ),
        const SizedBox(height: 20),

        // ── Progression Section ──
        StaggeredFadeIn(
          index: 2,
          child: _ProgressionSection(progress: progress),
        ),
        const SizedBox(height: 20),

        // ── Recent Attempts ──
        StaggeredFadeIn(
          index: 3,
          child: _RecentAttemptsSection(attempts: recentAttempts),
        ),
        const SizedBox(height: 20),

        // ── Quick Actions ──
        StaggeredFadeIn(
          index: 4,
          child: _QuickActionsSection(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// WELCOME CARD
// ═══════════════════════════════════════════════════════════════
class _WelcomeCard extends StatelessWidget {
  final UserModel? user;
  final int stars;
  final int rank;

  const _WelcomeCard({required this.user, required this.stars, required this.rank});

  @override
  Widget build(BuildContext context) {
    final firstName = user?.firstName ?? 'Utilisateur';
    final avatar = user?.avatar;
    final userId = user?.id;
    
    // Build full avatar URL if user has an avatar
    final avatarUrl = AvatarUtils.buildAvatarUrl(avatar);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: AppDesign.heroGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Floating particles
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: FloatingParticles(
                count: 8,
                color: AppColors.accent,
                maxSize: 6,
              ),
            ),
          ),
          // Decorative circles
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            right: -40,
            bottom: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.06),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar with gold ring
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppDesign.goldGradient,
                        boxShadow: AppDesign.glowShadow(AppColors.accent, blur: 10),
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF333333), // Changed to dark neutral
                        backgroundImage: avatarUrl != null
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: avatarUrl == null && userId != null
                            ? ClipOval(
                                child: SvgPicture.network(
                                  AvatarUtils.generateDiceBearUrl(userId),
                                  width: 48,
                                  height: 48,
                                  placeholderBuilder: (context) => Text(
                                    firstName[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                            : avatarUrl == null
                                ? Text(
                                    firstName[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bonjour, $firstName !',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Testez vos connaissances football',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Badges row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _WelcomeBadge(
                      icon: Icons.star_rounded,
                      label: '$stars étoiles',
                      iconColor: AppColors.accent,
                    ),
                    _WelcomeBadge(
                      icon: Icons.emoji_events_rounded,
                      label: 'Rang #$rank',
                      iconColor: AppColors.accent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;

  const _WelcomeBadge({required this.icon, required this.label, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STAT CARDS GRID
// ═══════════════════════════════════════════════════════════════
class _StatCardsGrid extends StatelessWidget {
  final UserStatsModel stats;
  final UserPositionModel position;
  final double successRate;
  final int userStars;

  const _StatCardsGrid({
    required this.stats,
    required this.position,
    required this.successRate,
    required this.userStars,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _StatCard(
          title: 'Quiz réussis',
          value: '${stats.quizzesPassed}',
          subtitle: 'sur ${stats.totalQuizzes} quiz',
          icon: Icons.check_circle_rounded,
          iconBgColor: AppColors.success,
          accentColor: AppColors.success,
        ),
        _StatCard(
          title: 'Étoiles',
          value: '$userStars',
          subtitle: 'accumulées',
          icon: Icons.star_rounded,
          iconBgColor: AppColors.primary,
          accentColor: AppColors.primary,
        ),
        _StatCard(
          title: 'Taux de réussite',
          value: '${successRate.round()}%',
          subtitle: '${stats.quizzesPassed} quiz réussis',
          icon: Icons.trending_up_rounded,
          iconBgColor: AppColors.primaryLight,
          accentColor: AppColors.primaryLight,
        ),
        _StatCard(
          title: 'Score moyen',
          value: '${stats.averageScore.round()}%',
          subtitle: 'sur ${stats.totalAttempts} tentatives',
          icon: Icons.military_tech_rounded,
          iconBgColor: AppColors.accent,
          accentColor: AppColors.accent,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconBgColor;
  final Color accentColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconBgColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBgColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconBgColor),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryLight,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PROGRESSION
// ═══════════════════════════════════════════════════════════════
class _ProgressionSection extends StatelessWidget {
  final Map<String, dynamic> progress;
  const _ProgressionSection({required this.progress});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = [
      _ProgressItem(
        label: 'Quiz réussis',
        value: (progress['quizSuccessRate'] as num?)?.toInt() ?? 0,
        color: const Color(0xFF333333), // Changed to dark neutral
      ),
      _ProgressItem(
        label: 'Quiz complétés',
        value: (progress['quizCompletionRate'] as num?)?.toInt() ?? 0,
        color: const Color(0xFFE5C158),
      ),
      _ProgressItem(
        label: 'Articles lus',
        value: (progress['blogReadRate'] as num?)?.toInt() ?? 0,
        color: AppColors.accent,
      ),
      _ProgressItem(
        label: 'Participation forum',
        value: (progress['forumParticipationRate'] as num?)?.toInt() ?? 0,
        color: const Color(0xFFC0C0C0),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart_rounded, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Ma progression',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Suivez votre avancement dans les quiz',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
            ),
            const SizedBox(height: 20),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: StaminaBar(
                value: item.value.toDouble(),
                label: item.label,
                segments: 12,
                height: 10,
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _ProgressItem {
  final String label;
  final int value;
  final Color color;
  const _ProgressItem({required this.label, required this.value, required this.color});
}

// ═══════════════════════════════════════════════════════════════
// RECENT ATTEMPTS
// ═══════════════════════════════════════════════════════════════
class _RecentAttemptsSection extends StatelessWidget {
  final List<QuizAttemptModel> attempts;
  const _RecentAttemptsSection({required this.attempts});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.history_rounded, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Activité récente',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Text(
              'Vos derniers quiz',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
            ),
          ),
          if (attempts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.quiz_outlined, size: 48, color: AppColors.textMutedLight),
                    const SizedBox(height: 12),
                    Text(
                      'Aucun quiz complété',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.quizzes),
                      child: const Text('Commencer un quiz'),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              itemCount: attempts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                return _AttemptTile(attempt: attempts[index]);
              },
            ),
        ],
      ),
    );
  }
}

class _AttemptTile extends StatelessWidget {
  final QuizAttemptModel attempt;
  const _AttemptTile({required this.attempt});

  String _relativeTime(String dateString) {
    final date = DateTime.tryParse(dateString);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final passed = attempt.score >= (attempt.quiz?.passingScore ?? 70);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.backgroundDark : AppColors.backgroundLight)
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: passed
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: passed ? AppColors.primary : AppColors.error,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Title + time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attempt.quiz?.title ?? 'Quiz',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _relativeTime(attempt.completedAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                ),
              ],
            ),
          ),

          // Score + stars
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${attempt.score}%',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: passed ? AppColors.primary : AppColors.error,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, size: 14, color: AppColors.accent),
                  const SizedBox(width: 2),
                  Text(
                    '+${attempt.starsEarned}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// QUICK ACTIONS
// ═══════════════════════════════════════════════════════════════
class _QuickActionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accès rapide',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _GradientActionCard(
                icon: Icons.fitness_center_rounded,
                label: 'Entrainement',
                desc: 'Jouez des quiz',
                gradient: const LinearGradient(
                  colors: [Color(0xFFC41E3A), Color(0xFF9B1B30)],
                ),
                onTap: (ctx) => ctx.go(AppRoutes.quizzes),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GradientActionCard(
                icon: Icons.emoji_events_rounded,
                label: 'Classement',
                desc: 'Ligue Footix',
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                ),
                onTap: (ctx) => ctx.push(AppRoutes.leaderboard),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GradientActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String desc;
  final LinearGradient gradient;
  final void Function(BuildContext) onTap;

  const _GradientActionCard({
    required this.icon,
    required this.label,
    required this.desc,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BounceTap(
      onTap: () => onTap(context),
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
