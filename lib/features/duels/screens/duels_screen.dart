import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design.dart';
import '../../../shared/widgets/scoreboard_header.dart';
import '../../../providers/duel_provider.dart';
import '../../../data/models/duel_model.dart';
import '../../../navigation/app_router.dart';

const _difficultyConfig = {
  'FACILE': _DiffConfig('Facile', 5, AppColors.success, Icons.sentiment_satisfied_alt_rounded),
  'MOYEN': _DiffConfig('Moyen', 10, AppColors.warning, Icons.sentiment_neutral_rounded),
  'DIFFICILE': _DiffConfig('Difficile', 20, AppColors.error, Icons.sentiment_very_dissatisfied_rounded),
  'ALEATOIRE': _DiffConfig('Aléatoire', 12, Color(0xFF8B5CF6), Icons.shuffle_rounded),
};

const _statusLabels = {
  'WAITING': 'En attente',
  'READY': 'Prêt',
  'PLAYING': 'En cours',
  'FINISHED': 'Terminé',
  'CANCELLED': 'Annulé',
};

class _DiffConfig {
  final String label;
  final int cost;
  final Color color;
  final IconData icon;
  const _DiffConfig(this.label, this.cost, this.color, this.icon);
}

class DuelsScreen extends ConsumerStatefulWidget {
  const DuelsScreen({super.key});

  @override
  ConsumerState<DuelsScreen> createState() => _DuelsScreenState();
}

class _DuelsScreenState extends ConsumerState<DuelsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(duelListProvider.notifier).loadDuels());
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(duelListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(duelListProvider.notifier).loadDuels(),
          color: AppColors.primary,
          child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: ScoreboardHeader(
                  title: 'Arène',
                  subtitle: 'Affrontez d\'autres joueurs',
                  icon: Icons.sports_mma_rounded,
                  live: true,
                ),
              ),
            ),
            // Action buttons
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.login_rounded,
                        label: 'Rejoindre',
                        onTap: () => context.push(AppRoutes.duelJoin),
                        isPrimary: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.add_rounded,
                        label: 'Créer un salon',
                        onTap: () => context.push(AppRoutes.duelCreate),
                        isPrimary: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // List
            if (listState.isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (listState.error != null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 56,
                          color: AppColors.error.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Impossible de charger les duels',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          listState.error!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => ref.read(duelListProvider.notifier).loadDuels(),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Réessayer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (listState.duels.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sports_mma_rounded,
                        size: 64,
                        color: (isDark ? AppColors.textMutedDark : AppColors.textMutedLight).withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun duel pour le moment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Créez un salon ou rejoignez-en un',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final duel = listState.duels[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _DuelCard(duel: duel),
                      );
                    },
                    childCount: listState.duels.length,
                  ),
                ),
              ),
          ],
        ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: isPrimary
                ? AppColors.primary
                : (isDark ? AppColors.cardDark : AppColors.cardLight),
            border: isPrimary
                ? null
                : Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            boxShadow: isPrimary ? AppDesign.glowShadow(AppColors.primary, blur: 12) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isPrimary ? Colors.black : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isPrimary ? Colors.black : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DuelCard extends ConsumerWidget {
  final DuelListItem duel;
  const _DuelCard({required this.duel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final diff = _difficultyConfig[duel.difficulty];

    return GestureDetector(
      onTap: () async {
        final notifier = ref.read(activeDuelProvider.notifier);
        await notifier.loadDuel(duel.id);
        if (!context.mounted) return;
        final loaded = ref.read(activeDuelProvider).duel;
        if (loaded == null) return;

        if (loaded.status == 'PLAYING') {
          context.push(AppRoutes.duelPlay);
        } else if (loaded.status == 'FINISHED') {
          context.push(AppRoutes.duelResults);
        } else {
          context.push(AppRoutes.duelLobby);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Row(
          children: [
            // Difficulty icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: (diff?.color ?? AppColors.neutral400).withValues(alpha: 0.1),
              ),
              child: Icon(diff?.icon ?? Icons.quiz_rounded, color: diff?.color ?? AppColors.neutral400, size: 24),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        duel.code,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _Tag(label: diff?.label ?? duel.difficulty, color: diff?.color ?? AppColors.neutral400),
                      const SizedBox(width: 6),
                      _Tag(label: _statusLabels[duel.status] ?? duel.status, color: AppColors.neutral400),
                      if (duel.isCreator) ...[
                        const SizedBox(width: 6),
                        _Tag(label: 'Créateur', color: AppColors.primary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.people_rounded, size: 13, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                      const SizedBox(width: 4),
                      Text(
                        '${duel.participantCount}/${duel.maxParticipants}',
                        style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.star_rounded, size: 13, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${duel.starsCost}',
                        style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                      ),
                      if (duel.status == 'FINISHED' && duel.myRank != null) ...[
                        const SizedBox(width: 12),
                        Icon(
                          duel.myRank == 1 ? Icons.emoji_events_rounded : Icons.military_tech_rounded,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '#${duel.myRank} · +${duel.myStarsWon}⭐',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: color.withValues(alpha: 0.1),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
