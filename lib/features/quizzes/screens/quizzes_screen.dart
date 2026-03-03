import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/quiz_model.dart';
import '../../../data/models/theme_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/service_providers.dart';
import '../../../shared/widgets/match_card.dart';
import '../../../shared/widgets/scoreboard_header.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/staggered_fade_in.dart';

// ─── Data holder ───
class _QuizzesData {
  final List<QuizModel> quizzes;
  final List<ThemeModel> themes;
  const _QuizzesData({required this.quizzes, required this.themes});
}

final _quizzesDataProvider = FutureProvider.autoDispose<_QuizzesData>((ref) async {
  final isAuth = ref.watch(isAuthenticatedProvider);
  if (!isAuth) return const _QuizzesData(quizzes: [], themes: []);
  final quizzesService = ref.watch(quizzesServiceProvider);
  final themesService = ref.watch(themesServiceProvider);
  final results = await Future.wait([
    quizzesService.getQuizzesWithStatus(),
    themesService.getThemes(),
  ]);
  return _QuizzesData(
    quizzes: results[0] as List<QuizModel>,
    themes: results[1] as List<ThemeModel>,
  );
});

class QuizzesScreen extends ConsumerStatefulWidget {
  const QuizzesScreen({super.key});
  @override
  ConsumerState<QuizzesScreen> createState() => _QuizzesScreenState();
}

class _QuizzesScreenState extends ConsumerState<QuizzesScreen> {
  String _search = '';
  String _difficultyFilter = '';
  String _themeFilter = '';

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(_quizzesDataProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: dataAsync.when(
        loading: () => _buildShimmer(),
        error: (e, _) => _buildError(),
        data: (data) => _buildContent(context, data, user),
      ),
    );
  }

  Widget _buildShimmer() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          ShimmerLoading(height: 80, borderRadius: 20),
          const SizedBox(height: 16),
          ShimmerLoading(height: 48, borderRadius: 16),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: ShimmerLoading(height: 34, borderRadius: 20)),
            const SizedBox(width: 8),
            Expanded(child: ShimmerLoading(height: 34, borderRadius: 20)),
            const SizedBox(width: 8),
            Expanded(child: ShimmerLoading(height: 34, borderRadius: 20)),
          ]),
          const SizedBox(height: 16),
          ...List.generate(4, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ShimmerLoading(height: 120, borderRadius: 16),
          )),
        ]),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.textMutedLight),
          const SizedBox(height: 16),
          const Text('Impossible de charger les quiz'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(_quizzesDataProvider),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, _QuizzesData data, dynamic user) {
    final userStars = user?.stars ?? 0;

    // Filter quizzes
    var filtered = data.quizzes.where((q) {
      if (_search.isNotEmpty) {
        final s = _search.toLowerCase();
        if (!q.title.toLowerCase().contains(s) && !(q.theme?.title.toLowerCase().contains(s) ?? false)) {
          return false;
        }
      }
      if (_difficultyFilter.isNotEmpty && q.difficulty != _difficultyFilter) return false;
      if (_themeFilter.isNotEmpty && q.themeId != _themeFilter) return false;
      return true;
    }).toList();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => ref.invalidate(_quizzesDataProvider),
      child: CustomScrollView(
        slivers: [
          // ── Scoreboard Header ──
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: ScoreboardHeader(
                  title: 'Entrainement',
                  subtitle: 'Centre de formation',
                  icon: Icons.sports_soccer,
                  rightContent: _buildStarsCounter(userStars),
                ),
              ),
            ),
          ),
          // ── Search bar ──
          SliverToBoxAdapter(child: _buildSearchBar(context)),
          // ── Filters ──
          SliverToBoxAdapter(child: _buildFilters(context, data.themes)),
          // ── Count ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${filtered.length} match${filtered.length > 1 ? 's' : ''} disponible${filtered.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: AppColors.textMutedLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Quiz list ──
          if (filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sports_soccer, size: 56, color: AppColors.textMutedLight.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    Text('Aucun match trouv\u00e9',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondaryLight)),
                    const SizedBox(height: 4),
                    Text('Modifiez vos filtres pour trouver un quiz',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMutedLight)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) => StaggeredFadeIn(
                  index: i,
                  child: _buildQuizMatchCard(context, filtered[i], userStars),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStarsCounter(int stars) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 16, color: AppColors.accent),
          const SizedBox(width: 4),
          Text(
            '$stars',
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111B2E) : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF1B2B40) : const Color(0xFFDCE6F0),
          ),
        ),
        child: TextField(
          onChanged: (v) => setState(() => _search = v),
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimaryLight,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: 'Rechercher un quiz...',
            hintStyle: TextStyle(
              color: AppColors.textMutedLight,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppColors.textMutedLight,
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context, List<ThemeModel> themes) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          // Difficulty badges
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _DifficultyBadge(
                  label: 'Tous',
                  isSelected: _difficultyFilter.isEmpty,
                  color: AppColors.primary,
                  onTap: () => setState(() => _difficultyFilter = ''),
                ),
                const SizedBox(width: 8),
                _DifficultyBadge(
                  label: 'Facile',
                  isSelected: _difficultyFilter == 'FACILE',
                  color: AppColors.easy,
                  onTap: () => setState(() => _difficultyFilter = _difficultyFilter == 'FACILE' ? '' : 'FACILE'),
                ),
                const SizedBox(width: 8),
                _DifficultyBadge(
                  label: 'Moyen',
                  isSelected: _difficultyFilter == 'MOYEN',
                  color: AppColors.medium,
                  onTap: () => setState(() => _difficultyFilter = _difficultyFilter == 'MOYEN' ? '' : 'MOYEN'),
                ),
                const SizedBox(width: 8),
                _DifficultyBadge(
                  label: 'Difficile',
                  isSelected: _difficultyFilter == 'DIFFICILE',
                  color: AppColors.hard,
                  onTap: () => setState(() => _difficultyFilter = _difficultyFilter == 'DIFFICILE' ? '' : 'DIFFICILE'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Theme badges
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _DifficultyBadge(
                  label: 'Tous les th\u00e8mes',
                  isSelected: _themeFilter.isEmpty,
                  color: AppColors.accent,
                  onTap: () => setState(() => _themeFilter = ''),
                ),
                ...themes.map((t) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _DifficultyBadge(
                    label: t.title,
                    isSelected: _themeFilter == t.id,
                    color: AppColors.accent,
                    onTap: () => setState(() => _themeFilter = _themeFilter == t.id ? '' : t.id),
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizMatchCard(BuildContext context, QuizModel quiz, int userStars) {
    final status = quiz.userStatus;
    final isStarLocked = !quiz.isFree && quiz.requiredStars > userStars;
    final isLocked = isStarLocked;
    final hasPassed = status?.hasPassed ?? false;
    final questionCount = quiz.count?.questions ?? 0;
    final bestScore = status?.bestScore;

    // Determine ribbon text
    String? ribbon;
    if (quiz.isFree) {
      ribbon = 'GRATUIT';
    } else if (isStarLocked) {
      ribbon = '${quiz.requiredStars} \u2605';
    }

    // Build trailing widget with attempt info
    Widget? trailing;
    if (status != null && status.totalAttempts > 0) {
      trailing = Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${status.totalAttempts} tent.',
            style: const TextStyle(fontSize: 10, color: Color(0xFF5E7A9A), fontWeight: FontWeight.w500),
          ),
          if (status.remainingAttempts > 0)
            Text(
              '${status.remainingAttempts} rest.',
              style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
        ],
      );
    }

    return MatchCard(
      title: quiz.title,
      subtitle: quiz.theme?.title,
      difficulty: quiz.difficulty,
      score: bestScore?.toDouble(),
      stars: null,
      timeLimit: quiz.timeLimit,
      passingScore: quiz.passingScore,
      questionCount: questionCount > 0 ? questionCount : null,
      isPremium: !quiz.isFree,
      isLocked: isLocked,
      isPassed: hasPassed,
      ribbon: ribbon,
      trailing: trailing,
      onTap: () => context.push('/quizzes/${quiz.id}/play'),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// DIFFICULTY BADGE (badge-style filter button)
// ═══════════════════════════════════════════════════════════════
class _DifficultyBadge extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _DifficultyBadge({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.borderLight.withValues(alpha: 0.5),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4)],
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : AppColors.textSecondaryLight,
                letterSpacing: isSelected ? 0.3 : 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
