import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/duel_model.dart';
import '../../../data/models/quiz_model.dart';
import '../../../providers/service_providers.dart';
import '../../../shared/widgets/scoreboard_header.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/staggered_fade_in.dart';

enum _HistoryType { quiz, duel }
enum _HistoryFilter { all, passed, failed, duels }

class _HistoryEntry {
  final _HistoryType type;
  final QuizAttemptModel? quizAttempt;
  final DuelListItem? duel;
  final DateTime date;

  _HistoryEntry.quiz(QuizAttemptModel a)
      : type = _HistoryType.quiz,
        quizAttempt = a,
        duel = null,
        date = DateTime.tryParse(a.completedAt) ?? DateTime.now();

  _HistoryEntry.duel(DuelListItem d)
      : type = _HistoryType.duel,
        quizAttempt = null,
        duel = d,
        date = DateTime.tryParse(d.finishedAt ?? d.createdAt) ?? DateTime.now();
}

const _difficultyConfig = {
  'FACILE': ('Facile', AppColors.success),
  'MOYEN': ('Moyen', AppColors.warning),
  'DIFFICILE': ('Difficile', AppColors.error),
  'ALEATOIRE': ('Aléatoire', Color(0xFF8B5CF6)),
};

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  List<_HistoryEntry> _entries = [];
  bool _isLoading = true;
  String? _error;
  _HistoryFilter _filter = _HistoryFilter.all;

  // Quiz stats
  int _totalAttempts = 0;
  int _passedAttempts = 0;
  int _failedAttempts = 0;
  int _totalStars = 0;
  int _averageScore = 0;
  int _bestScore = 0;

  // Duel stats
  int _duelsCount = 0;
  int _duelsWon = 0;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final quizService = ref.read(quizzesServiceProvider);
      final duelService = ref.read(duelServiceProvider);

      // Fetch both in parallel
      final results = await Future.wait([
        quizService.getUserAttempts(),
        duelService.getMyDuels(),
      ]);

      if (!mounted) return;

      final attempts = results[0] as List<QuizAttemptModel>;
      final duels = (results[1] as List<DuelListItem>)
          .where((d) => d.status == 'FINISHED')
          .toList();

      // Build unified list
      final entries = <_HistoryEntry>[
        ...attempts.map((a) => _HistoryEntry.quiz(a)),
        ...duels.map((d) => _HistoryEntry.duel(d)),
      ];
      entries.sort((a, b) => b.date.compareTo(a.date));

      // Quiz stats
      final passed = attempts.where((a) => a.quiz != null && a.score >= a.quiz!.passingScore).length;
      final failed = attempts.length - passed;
      final totalStars = attempts.fold<int>(0, (sum, a) => sum + a.starsEarned);
      final totalScore = attempts.fold<int>(0, (sum, a) => sum + a.score);
      final bestScore = attempts.isEmpty ? 0 : attempts.map((a) => a.score).reduce(max);

      // Duel stats
      final duelsWon = duels.where((d) => d.myRank == 1).length;

      setState(() {
        _entries = entries;
        _totalAttempts = attempts.length;
        _passedAttempts = passed;
        _failedAttempts = failed;
        _totalStars = totalStars;
        _averageScore = attempts.isNotEmpty ? (totalScore / attempts.length).round() : 0;
        _bestScore = bestScore;
        _duelsCount = duels.length;
        _duelsWon = duelsWon;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  List<_HistoryEntry> get _filteredEntries {
    switch (_filter) {
      case _HistoryFilter.all:
        return _entries;
      case _HistoryFilter.passed:
        return _entries.where((e) =>
            e.type == _HistoryType.quiz &&
            e.quizAttempt != null &&
            e.quizAttempt!.quiz != null &&
            e.quizAttempt!.score >= e.quizAttempt!.quiz!.passingScore).toList();
      case _HistoryFilter.failed:
        return _entries.where((e) =>
            e.type == _HistoryType.quiz &&
            (e.quizAttempt?.quiz == null ||
                e.quizAttempt!.score < e.quizAttempt!.quiz!.passingScore)).toList();
      case _HistoryFilter.duels:
        return _entries.where((e) => e.type == _HistoryType.duel).toList();
    }
  }

  String _relativeTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
      if (diff.inDays == 1) return 'Hier';
      if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return '';
    }
  }

  String _filterLabel(_HistoryFilter f) {
    switch (f) {
      case _HistoryFilter.all:
        return 'Toutes';
      case _HistoryFilter.passed:
        return 'Réussites';
      case _HistoryFilter.failed:
        return 'Échecs';
      case _HistoryFilter.duels:
        return 'Duels';
    }
  }

  String _emptyLabel() {
    switch (_filter) {
      case _HistoryFilter.all:
        return 'Aucune tentative';
      case _HistoryFilter.passed:
        return 'Aucune réussite';
      case _HistoryFilter.failed:
        return 'Aucun échec — Bravo !';
      case _HistoryFilter.duels:
        return 'Aucun duel terminé';
    }
  }

  String _emptySubLabel() {
    switch (_filter) {
      case _HistoryFilter.all:
        return 'Vous n\'avez pas encore joué.';
      default:
        return 'Aucun résultat pour ce filtre.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          Text('Impossible de charger l\'historique',
              style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _fetchHistory, child: const Text('Réessayer')),
        ])),
      );
    }

    final filtered = _filteredEntries;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchHistory,
          color: AppColors.primary,
          child: CustomScrollView(slivers: [
            // Scoreboard header
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: ScoreboardHeader(
                title: 'Palmarès',
                subtitle: 'Vos résultats de match',
                icon: Icons.emoji_events_rounded,
                live: false,
              ),
            )),

            // Stats grid
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 20, 12, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatCard(Icons.bar_chart_rounded, AppColors.primary, '$_totalAttempts', 'Tentatives', isDark),
                  _buildStatCard(Icons.check_circle_rounded, AppColors.success, '$_passedAttempts', 'Réussites', isDark),
                  _buildStatCard(Icons.cancel_rounded, const Color(0xFFE53E3E), '$_failedAttempts', 'Échecs', isDark),
                  _buildStatCard(Icons.star_rounded, const Color(0xFFD4AF37), '$_totalStars', 'Étoiles', isDark),
                  _buildStatCard(Icons.gps_fixed_rounded, AppColors.primary, '$_averageScore%', 'Moyenne', isDark),
                  _buildStatCard(Icons.trending_up_rounded, AppColors.primary, '$_bestScore%', 'Meilleur', isDark),
                  _buildStatCard(Icons.sports_mma_rounded, const Color(0xFF8B5CF6), '$_duelsCount', 'Duels', isDark),
                  _buildStatCard(Icons.emoji_events_rounded, AppColors.accent, '$_duelsWon', 'Duels gagnés', isDark),
                ],
              ),
            )),

            // Filter + title
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
              child: Row(children: [
                Expanded(child: Text('Toutes les tentatives',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ))),
                _buildFilterChip(isDark),
              ]),
            )),

            // Entries list
            if (filtered.isEmpty)
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(children: [
                  Icon(Icons.history_rounded, size: 56,
                      color: (isDark ? AppColors.textMutedDark : AppColors.textMutedLight).withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text(
                    _emptyLabel(),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _emptySubLabel(),
                    style: TextStyle(fontSize: 13, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                  ),
                ]),
              ))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                sliver: SliverList.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = filtered[index];
                    return StaggeredFadeIn(
                      index: index,
                      child: entry.type == _HistoryType.quiz
                          ? _buildAttemptCard(entry.quizAttempt!, isDark)
                          : _buildDuelCard(entry.duel!, isDark),
                    );
                  },
                ),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, Color color, String value, String label, bool isDark) {
    // 4 columns for the first 2 rows (8 items), need to fit nicely
    final width = (MediaQuery.of(context).size.width - 24 - 16) / 3;
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          )),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            fontWeight: FontWeight.w500,
          )),
        ]),
      ),
    );
  }

  Widget _buildFilterChip(bool isDark) {
    return PopupMenuButton<_HistoryFilter>(
      onSelected: (f) => setState(() => _filter = f),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 40),
      itemBuilder: (_) => [
        _filterMenuItem(_HistoryFilter.all, 'Toutes', Icons.list_rounded),
        _filterMenuItem(_HistoryFilter.passed, 'Réussites', Icons.check_circle_rounded),
        _filterMenuItem(_HistoryFilter.failed, 'Échecs', Icons.cancel_rounded),
        _filterMenuItem(_HistoryFilter.duels, 'Duels', Icons.sports_mma_rounded),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isDark ? AppColors.neutral800 : AppColors.neutral50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.filter_list_rounded, size: 16,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
          const SizedBox(width: 6),
          Text(
            _filterLabel(_filter),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down_rounded, size: 16,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
        ]),
      ),
    );
  }

  PopupMenuEntry<_HistoryFilter> _filterMenuItem(_HistoryFilter value, String label, IconData icon) {
    return PopupMenuItem(
      value: value,
      child: Row(children: [
        Icon(icon, size: 18, color: _filter == value ? AppColors.primary : AppColors.textMutedLight),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(
          fontWeight: _filter == value ? FontWeight.w600 : FontWeight.normal,
          color: _filter == value ? AppColors.primary : null,
        )),
      ]),
    );
  }

  Widget _buildShimmer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        const SizedBox(height: 16),
        // Stats shimmer
        Row(children: [
          Expanded(child: ShimmerLoading(height: 80, borderRadius: 12)),
          const SizedBox(width: 8),
          Expanded(child: ShimmerLoading(height: 80, borderRadius: 12)),
          const SizedBox(width: 8),
          Expanded(child: ShimmerLoading(height: 80, borderRadius: 12)),
        ]),
        const SizedBox(height: 20),
        ...List.generate(5, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ShimmerLoading(height: 80, borderRadius: 14),
        )),
      ]),
    );
  }

  Widget _buildAttemptCard(QuizAttemptModel attempt, bool isDark) {
    final quiz = attempt.quiz;
    final passed = quiz != null && attempt.score >= quiz.passingScore;
    final passColor = passed ? AppColors.success : AppColors.error;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: passColor.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: passColor.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Row(children: [
        // Left accent band
        Container(width: 4, height: 80, color: passColor),
        const SizedBox(width: 10),
        // Status icon
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: passColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            passed ? Icons.emoji_events_rounded : Icons.cancel_rounded,
            color: passColor, size: 22,
          ),
        ),
        const SizedBox(width: 12),

        // Quiz info
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(child: Text(
              quiz?.title ?? 'Quiz',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            )),
            if (quiz != null) ...[
              const SizedBox(width: 6),
              _buildDifficultyBadge(quiz.difficulty),
            ],
          ]),
          const SizedBox(height: 3),
          Row(children: [
            if (quiz?.theme != null) ...[
              Flexible(child: Text(
                quiz!.theme!.title,
                style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              )),
              const SizedBox(width: 8),
            ],
            Icon(Icons.calendar_today_rounded, size: 11,
                color: (isDark ? AppColors.textMutedDark : AppColors.textMutedLight).withValues(alpha: 0.7)),
            const SizedBox(width: 3),
            Text(_relativeTime(attempt.completedAt),
                style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
          ]),
        ])),
        const SizedBox(width: 8),

        // Score + stars
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${attempt.score}%', style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: passColor, fontFamily: 'monospace',
          )),
          const SizedBox(height: 2),
          _buildStarsBadge(attempt.starsEarned, isDark),
        ]),
      ]),
    );
  }

  Widget _buildDuelCard(DuelListItem duel, bool isDark) {
    final won = duel.myRank == 1;
    final podium = duel.myRank != null && duel.myRank! <= 3;
    final accentColor = won
        ? AppColors.accent
        : podium
            ? AppColors.neutral400
            : (isDark ? AppColors.neutral600 : AppColors.neutral300);

    final diffConfig = _difficultyConfig[duel.difficulty.toUpperCase()];
    final diffLabel = diffConfig?.$1 ?? duel.difficulty;
    final diffColor = diffConfig?.$2 ?? (isDark ? AppColors.textMutedDark : AppColors.textMutedLight);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Row(children: [
        // Left accent band
        Container(width: 4, height: 80, color: accentColor),
        const SizedBox(width: 10),
        // Status icon
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            won ? Icons.emoji_events_rounded : Icons.military_tech_rounded,
            color: accentColor, size: 22,
          ),
        ),
        const SizedBox(width: 12),

        // Duel info
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(child: Text(
              'Duel #${duel.code}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            )),
            const SizedBox(width: 6),
            _buildDifficultyBadge(diffLabel, color: diffColor),
          ]),
          const SizedBox(height: 3),
          Row(children: [
            Text(
              '${duel.participantCount} joueurs',
              style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
            ),
            const SizedBox(width: 8),
            Icon(Icons.calendar_today_rounded, size: 11,
                color: (isDark ? AppColors.textMutedDark : AppColors.textMutedLight).withValues(alpha: 0.7)),
            const SizedBox(width: 3),
            Text(_relativeTime(duel.finishedAt ?? duel.createdAt),
                style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
          ]),
        ])),
        const SizedBox(width: 8),

        // Rank + stars
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            duel.myRank != null ? '#${duel.myRank}' : '-',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: accentColor,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 2),
          _buildStarsBadge(duel.myStarsWon, isDark),
        ]),
      ]),
    );
  }

  Widget _buildStarsBadge(int stars, bool isDark) {
    final prefix = stars >= 0 ? '+' : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3D2E0A) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? const Color(0xFF6B5A1E)
              : const Color(0xFFFCD34D).withValues(alpha: 0.5),
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.star_rounded, size: 13, color: Color(0xFFD4AF37)),
        const SizedBox(width: 2),
        Text('$prefix$stars',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFD4AF37) : const Color(0xFFB45309),
            )),
      ]),
    );
  }

  Widget _buildDifficultyBadge(String difficulty, {Color? color}) {
    final Color resolvedColor;
    if (color != null) {
      resolvedColor = color;
    } else {
      switch (difficulty.toUpperCase()) {
        case 'FACILE':
          resolvedColor = AppColors.success;
        case 'MOYEN':
          resolvedColor = const Color(0xFFF5A623);
        case 'DIFFICILE':
          resolvedColor = const Color(0xFFE53E3E);
        default:
          resolvedColor = AppColors.textMutedLight;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: resolvedColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        difficulty,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: resolvedColor),
      ),
    );
  }
}
