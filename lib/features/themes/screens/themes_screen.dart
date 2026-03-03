import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design.dart';
import '../../../data/models/theme_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/service_providers.dart';
import '../../../shared/widgets/match_card.dart';
import '../../../shared/widgets/scoreboard_header.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/staggered_fade_in.dart';

/// Provider that fetches all themes
final _themesProvider = FutureProvider.autoDispose<List<ThemeModel>>((ref) async {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  if (!isAuthenticated) return [];
  final service = ref.watch(themesServiceProvider);
  return service.getThemes();
});

class ThemesScreen extends ConsumerStatefulWidget {
  const ThemesScreen({super.key});

  @override
  ConsumerState<ThemesScreen> createState() => _ThemesScreenState();
}

class _ThemesScreenState extends ConsumerState<ThemesScreen> {
  String _searchQuery = '';
  final Set<String> _expandedThemes = {};

  @override
  Widget build(BuildContext context) {
    final themesAsync = ref.watch(_themesProvider);

    return Scaffold(
      body: themesAsync.when(
        loading: () => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              ShimmerLoading(height: 80, borderRadius: 20),
              const SizedBox(height: 16),
              ...List.generate(4, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ShimmerLoading(height: 90, borderRadius: 18),
              )),
            ]),
          ),
        ),
        error: (error, _) => _ErrorView(
          onRetry: () => ref.invalidate(_themesProvider),
        ),
        data: (themes) => _buildContent(context, themes),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<ThemeModel> themes) {
    final filtered = themes.where((t) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return t.title.toLowerCase().contains(q) ||
          t.description.toLowerCase().contains(q);
    }).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => ref.invalidate(_themesProvider),
      child: CustomScrollView(
        slivers: [
          // ── Scoreboard Header ──
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: ScoreboardHeader(
                  title: 'Championnat',
                  subtitle: 'Thèmes et catégories',
                  icon: Icons.emoji_events,
                ),
              ),
            ),
          ),

          // ── Search bar ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0D1525) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF1B2B40) : AppColors.borderLight,
                  ),
                  boxShadow: AppDesign.softShadow(blur: 8, y: 2),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Rechercher un thème...',
                    hintStyle: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.4)
                          : AppColors.textMutedLight,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.5)
                          : AppColors.textMutedLight,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
          ),

          // ── Stats bar (league table header) ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Row(
                children: [
                  Icon(Icons.format_list_numbered_rounded, size: 16, color: AppColors.accent),
                  const SizedBox(width: 6),
                  Text(
                    '${filtered.length} thème${filtered.length > 1 ? 's' : ''} au classement',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),

          // ── Theme cards (league table) ──
          if (filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sports_soccer_rounded, size: 56, color: AppColors.textMutedLight),
                    const SizedBox(height: 12),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'Aucun thème trouvé'
                          : 'Aucun thème disponible',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Essayez une autre recherche',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textMutedLight,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final theme = filtered[index];
                  final isExpanded = _expandedThemes.contains(theme.id);
                  return StaggeredFadeIn(
                    index: index,
                    child: _LeagueThemeCard(
                    theme: theme,
                    rank: index + 1,
                    isExpanded: isExpanded,
                    onToggleExpand: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedThemes.remove(theme.id);
                        } else {
                          _expandedThemes.add(theme.id);
                        }
                      });
                    },
                  ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// LEAGUE-STYLE THEME CARD
// ═══════════════════════════════════════════════════════════════
class _LeagueThemeCard extends StatelessWidget {
  final ThemeModel theme;
  final int rank;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  const _LeagueThemeCard({
    required this.theme,
    required this.rank,
    required this.isExpanded,
    required this.onToggleExpand,
  });

  /// Gold for 1st, silver for 2nd, bronze accent for 3rd, neutral for rest
  Color _rankColor() {
    switch (rank) {
      case 1:
        return const Color(0xFFD4AF37); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppColors.textMutedLight;
    }
  }

  Gradient? _rankGradient() {
    switch (rank) {
      case 1:
        return const LinearGradient(
          colors: [Color(0xFFD4AF37), Color(0xFFE5C158), Color(0xFFF5D76E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 2:
        return const LinearGradient(
          colors: [Color(0xFFA8A8A8), Color(0xFFC0C0C0), Color(0xFFD8D8D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 3:
        return const LinearGradient(
          colors: [Color(0xFFCD7F32), Color(0xFFD4944A), Color(0xFFDEA862)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quizCount = theme.quizzes?.length ?? 0;
    final isTop3 = rank <= 3;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1525) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTop3
              ? _rankColor().withValues(alpha: 0.3)
              : isDark
                  ? const Color(0xFF1B2B40)
                  : const Color(0xFFDCE6F0),
        ),
        boxShadow: isTop3
            ? AppDesign.glowShadow(_rankColor(), blur: 12, spread: 0)
            : AppDesign.softShadow(),
      ),
      child: Column(
        children: [
          // Header row — league table style
          InkWell(
            onTap: onToggleExpand,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 12, 10),
              child: Row(
                children: [
                  // Rank number badge
                  SizedBox(
                    width: 52,
                    child: Center(
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: _rankGradient(),
                          color: _rankGradient() == null
                              ? (isDark ? const Color(0xFF1B2B40) : AppColors.neutral100)
                              : null,
                          shape: BoxShape.circle,
                          boxShadow: isTop3
                              ? [
                                  BoxShadow(
                                    color: _rankColor().withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$rank',
                          style: TextStyle(
                            color: isTop3
                                ? Colors.white
                                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            fontFamily: 'monospace',
                            shadows: isTop3
                                ? [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : [],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Vertical separator line
                  Container(
                    width: 1,
                    height: 36,
                    color: isDark ? const Color(0xFF1B2B40) : const Color(0xFFDCE6F0),
                  ),
                  const SizedBox(width: 12),

                  // Title + quiz count
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                theme.title,
                                style: TextStyle(
                                  color: isDark ? const Color(0xFFE2E8F5) : const Color(0xFF0A1628),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!theme.isActive) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Suspendu',
                                  style: TextStyle(
                                    color: AppColors.textMutedLight,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.sports_soccer, size: 12, color: AppColors.textMutedLight),
                            const SizedBox(width: 4),
                            Text(
                              '$quizCount match${quizCount > 1 ? 's' : ''} disponible${quizCount > 1 ? 's' : ''}',
                              style: TextStyle(
                                color: isDark ? const Color(0xFF5E7A9A) : AppColors.textSecondaryLight,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Expand chevron
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : AppColors.primary).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: isDark ? const Color(0xFF5E7A9A) : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Description (always visible if present)
          if (theme.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text(
                _stripHtml(theme.description),
                style: TextStyle(
                  color: isDark ? const Color(0xFF5E7A9A) : AppColors.textSecondaryLight,
                  fontSize: 12,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Expanded quizzes section
          if (isExpanded) _MatchQuizzesSection(quizzes: theme.quizzes ?? []),
        ],
      ),
    );
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }
}

// ═══════════════════════════════════════════════════════════════
// MATCH-STYLE QUIZZES SECTION (expanded)
// ═══════════════════════════════════════════════════════════════
class _MatchQuizzesSection extends StatelessWidget {
  final List<dynamic> quizzes;
  const _MatchQuizzesSection({required this.quizzes});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF080E1A)
            : const Color(0xFFF5F7FA),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1B2B40) : const Color(0xFFDCE6F0),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.stadium_rounded, size: 14, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
                Text(
                  'Matchs du thème',
                  style: TextStyle(
                    color: isDark ? const Color(0xFFE2E8F5) : const Color(0xFF0A1628),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                Text(
                  '${quizzes.length}',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),

          if (quizzes.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textMutedLight),
                  const SizedBox(width: 6),
                  Text(
                    'Aucun match dans ce thème',
                    style: TextStyle(
                      color: AppColors.textMutedLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              itemCount: quizzes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final quiz = quizzes[index] as Map<String, dynamic>;
                return _buildMatchCard(context, quiz);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context, Map<String, dynamic> quiz) {
    final title = quiz['title'] as String? ?? 'Quiz';
    final difficulty = quiz['difficulty'] as String? ?? 'MOYEN';
    final timeLimit = quiz['timeLimit'] as int? ?? 30;
    final passingScore = quiz['passingScore'] as int? ?? 70;
    final isFree = quiz['isFree'] as bool? ?? false;
    final isActive = quiz['isActive'] as bool? ?? true;
    final quizId = quiz['id'] as String? ?? '';

    return Opacity(
      opacity: isActive ? 1.0 : 0.5,
      child: MatchCard(
        title: title,
        difficulty: difficulty,
        timeLimit: timeLimit,
        passingScore: passingScore,
        isLocked: !isActive,
        ribbon: isFree ? 'GRATUIT' : null,
        onTap: isActive ? () => context.push('/quizzes/$quizId/play') : null,
        trailing: Icon(
          Icons.play_circle_fill_rounded,
          color: isActive ? AppColors.primary : AppColors.textMutedLight,
          size: 28,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ERROR VIEW
// ═══════════════════════════════════════════════════════════════
class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.textMutedLight),
            const SizedBox(height: 16),
            Text(
              'Impossible de charger les thèmes',
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
