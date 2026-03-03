import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/duel_provider.dart';
import '../../../navigation/app_router.dart';

class DuelResultsScreen extends ConsumerStatefulWidget {
  const DuelResultsScreen({super.key});

  @override
  ConsumerState<DuelResultsScreen> createState() => _DuelResultsScreenState();
}

class _DuelResultsScreenState extends ConsumerState<DuelResultsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final duel = ref.read(activeDuelProvider).duel;
      if (duel != null && duel.status != 'FINISHED') {
        // Still waiting for results — poll
        ref.read(activeDuelProvider.notifier).startPolling(onUpdate: (d) {
          if (d.status == 'FINISHED') {
            ref.read(activeDuelProvider.notifier).stopPolling();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final duelState = ref.watch(activeDuelProvider);
    final duel = duelState.duel;

    if (duel == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (duel.status != 'FINISHED') {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 20),
              Text(
                'Calcul des résultats...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Veuillez patienter',
                style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
              ),
            ],
          ),
        ),
      );
    }

    final sorted = List.of(duel.participants)
      ..sort((a, b) => (a.rank ?? 99).compareTo(b.rank ?? 99));
    final totalPot = duel.starsCost * duel.participants.length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // Trophy
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFFE5C158)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.emoji_events_rounded, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 20),

              Text(
                'RÉSULTAT DU MATCH',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                  letterSpacing: 2,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pot total : $totalPot ⭐',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ),

              const SizedBox(height: 28),

              // Rankings
              ...sorted.asMap().entries.map((entry) {
                final i = entry.key;
                final p = entry.value;
                final isWinner = i == 0;
                final isSecond = i == 1;
                final isBronze = i == 2;

                Color rankBadgeColor() {
                  if (isWinner) return const Color(0xFFD4AF37);
                  if (isSecond) return const Color(0xFFC0C0C0);
                  if (isBronze) return const Color(0xFFCD7F32);
                  return isDark ? AppColors.neutral800 : AppColors.neutral100;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isWinner
                        ? (isDark ? const Color(0xFF2D2200) : const Color(0xFFFFF8E1))
                        : (isDark ? AppColors.cardDark : AppColors.cardLight),
                    border: Border.all(
                      color: isWinner
                          ? const Color(0xFFD4AF37).withValues(alpha: 0.4)
                          : (isDark ? AppColors.borderDark : AppColors.borderLight),
                      width: isWinner ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Rank badge
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: rankBadgeColor(),
                        ),
                        child: Center(
                          child: isWinner
                              ? const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 24)
                              : Text(
                                  '#${i + 1}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: (isSecond || isBronze)
                                        ? Colors.white
                                        : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Name + stats
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${p.firstName} ${p.lastName}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isWinner
                                    ? AppColors.primary
                                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${p.correctCount}/10 bonnes réponses · Score : ${p.score}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Stars
                      if (p.starsWon > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: AppColors.primary.withValues(alpha: 0.1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '+${p.starsWon}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.star_rounded, size: 16, color: AppColors.primary),
                            ],
                          ),
                        )
                      else
                        Text(
                          '-${duel.starsCost} ⭐',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 24),

              // Back button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(activeDuelProvider.notifier).reset();
                    ref.read(duelListProvider.notifier).loadDuels();
                    context.go(AppRoutes.duels);
                  },
                  icon: const Icon(Icons.sports_mma_rounded, size: 20),
                  label: const Text('Retour aux duels', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
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
