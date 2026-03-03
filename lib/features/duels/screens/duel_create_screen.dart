import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/duel_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../navigation/app_router.dart';

class DuelCreateScreen extends ConsumerStatefulWidget {
  const DuelCreateScreen({super.key});

  @override
  ConsumerState<DuelCreateScreen> createState() => _DuelCreateScreenState();
}

class _DuelCreateScreenState extends ConsumerState<DuelCreateScreen> {
  int _participants = 2;
  String _difficulty = 'FACILE';

  static const _difficulties = [
    _DiffOption('FACILE', 'Facile', 5, AppColors.success, Icons.sentiment_satisfied_alt_rounded),
    _DiffOption('MOYEN', 'Moyen', 10, AppColors.warning, Icons.sentiment_neutral_rounded),
    _DiffOption('DIFFICILE', 'Difficile', 20, AppColors.error, Icons.sentiment_very_dissatisfied_rounded),
    _DiffOption('ALEATOIRE', 'Aléatoire', 12, Color(0xFF8B5CF6), Icons.shuffle_rounded),
  ];

  int get _cost => _difficulties.firstWhere((d) => d.key == _difficulty).cost;
  int get _totalPot => _cost * _participants;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final userStars = user?.stars ?? 0;
    final canAfford = userStars >= _cost;
    final duelState = ref.watch(activeDuelProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Créer un salon'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Participants
            Text(
              'Nombre de participants',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [2, 3, 4].map((n) {
                final selected = _participants == n;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: n < 4 ? 10 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _participants = n),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : (isDark ? AppColors.cardDark : AppColors.cardLight),
                          border: Border.all(
                            color: selected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.people_rounded,
                              size: 28,
                              color: selected ? AppColors.primary : AppColors.textMutedLight,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$n',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: selected ? AppColors.primary : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                              ),
                            ),
                            Text(
                              'joueurs',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 28),

            // Difficulty
            Text(
              'Niveau de difficulté',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _difficulties.map((d) {
                final selected = _difficulty == d.key;
                return GestureDetector(
                  onTap: () => setState(() => _difficulty = d.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: (MediaQuery.of(context).size.width - 50) / 2,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: selected
                          ? d.color.withValues(alpha: 0.1)
                          : (isDark ? AppColors.cardDark : AppColors.cardLight),
                      border: Border.all(
                        color: selected ? d.color : (isDark ? AppColors.borderDark : AppColors.borderLight),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(d.icon, color: d.color, size: 24),
                        const SizedBox(height: 8),
                        Text(
                          d.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: d.color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 13, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              '${d.cost} étoiles',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 28),

            // Summary card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isDark ? AppColors.cardDark : AppColors.neutral100,
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: Column(
                children: [
                  _SummaryRow(label: 'Votre mise', value: '$_cost ⭐'),
                  const SizedBox(height: 10),
                  _SummaryRow(label: 'Pot total', value: '$_totalPot ⭐', highlight: true),
                  const SizedBox(height: 10),
                  _SummaryRow(
                    label: 'Vos étoiles',
                    value: '$userStars ⭐',
                    valueColor: canAfford ? null : AppColors.error,
                  ),
                ],
              ),
            ),

            if (duelState.error != null) ...[
              const SizedBox(height: 12),
              Text(
                duelState.error!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ],

            const SizedBox(height: 24),

            // Create button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (duelState.isLoading || !canAfford)
                    ? null
                    : () async {
                        final notifier = ref.read(activeDuelProvider.notifier);
                        final duel = await notifier.createDuel(
                          maxParticipants: _participants,
                          difficulty: _difficulty,
                        );
                        if (duel != null && context.mounted) {
                          context.go(AppRoutes.duelLobby);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: duelState.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : Text(
                        canAfford ? 'Créer le Salon' : 'Étoiles insuffisantes',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiffOption {
  final String key;
  final String label;
  final int cost;
  final Color color;
  final IconData icon;
  const _DiffOption(this.key, this.label, this.cost, this.color, this.icon);
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.highlight = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: highlight ? 16 : 14,
            fontWeight: highlight ? FontWeight.w900 : FontWeight.w700,
            fontFamily: highlight ? 'monospace' : null,
            color: valueColor ?? (highlight ? AppColors.primary : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
          ),
        ),
      ],
    );
  }
}
