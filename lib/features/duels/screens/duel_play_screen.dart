import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/duel_provider.dart';
import '../../../navigation/app_router.dart';

class DuelPlayScreen extends ConsumerStatefulWidget {
  const DuelPlayScreen({super.key});

  @override
  ConsumerState<DuelPlayScreen> createState() => _DuelPlayScreenState();
}

class _DuelPlayScreenState extends ConsumerState<DuelPlayScreen> {
  int _currentIndex = 0;
  int _timeLeft = 300;
  Timer? _timer;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final notifier = ref.read(activeDuelProvider.notifier);
      notifier.stopPolling();
      await notifier.loadQuestions();

      final qr = ref.read(activeDuelProvider).questionsResponse;
      if (qr != null) {
        final elapsed = DateTime.now().difference(DateTime.parse(qr.startedAt)).inSeconds;
        setState(() => _timeLeft = (qr.timeLimit - elapsed).clamp(0, qr.timeLimit));
        _startTimer();
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) {
          _timeLeft = 0;
          _timer?.cancel();
          _handleSubmit();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    _timer?.cancel();

    final notifier = ref.read(activeDuelProvider.notifier);
    await notifier.submitAnswers();

    // Start polling for results
    notifier.startPolling(onUpdate: (duel) {
      if (duel.status == 'FINISHED' && mounted) {
        notifier.stopPolling();
        context.go(AppRoutes.duelResults);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final duelState = ref.watch(activeDuelProvider);
    final questions = duelState.questionsResponse?.questions ?? [];
    final answers = duelState.answers;

    if (duelState.isLoading || questions.isEmpty) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text('Chargement des questions...'),
            ],
          ),
        ),
      );
    }

    if (duelState.hasSubmitted) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, size: 64, color: AppColors.success),
              const SizedBox(height: 16),
              Text(
                'Réponses soumises !',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'En attente des autres joueurs...',
                style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: AppColors.primary),
            ],
          ),
        ),
      );
    }

    final question = questions[_currentIndex];
    final minutes = _timeLeft ~/ 60;
    final seconds = _timeLeft % 60;
    final selectedAnswers = answers[question.id] ?? [];

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header: progress + timer
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentIndex + 1}/${questions.length}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: _timeLeft <= 30
                          ? AppColors.error.withValues(alpha: 0.1)
                          : const Color(0xFFD4AF37).withValues(alpha: 0.1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_rounded,
                          size: 16,
                          color: _timeLeft <= 30 ? AppColors.error : const Color(0xFFD4AF37),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'monospace',
                            color: _timeLeft <= 30 ? AppColors.error : const Color(0xFFD4AF37),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / questions.length,
                  minHeight: 5,
                  backgroundColor: isDark ? AppColors.neutral800 : AppColors.neutral200,
                  color: AppColors.primary,
                ),
              ),
            ),

            // Question
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: isDark ? AppColors.cardDark : AppColors.cardLight,
                        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: question.type == 'QCU'
                                  ? AppColors.info.withValues(alpha: 0.1)
                                  : const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                            ),
                            child: Text(
                              question.type == 'QCU' ? 'Choix unique' : 'Choix multiple',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: question.type == 'QCU' ? AppColors.info : const Color(0xFF8B5CF6),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            question.content,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Options
                    ...question.options.asMap().entries.map((entry) {
                      final optIndex = entry.key;
                      final opt = entry.value;
                      final isSelected = selectedAnswers.contains(opt.id);
                      const letters = ['A', 'B', 'C', 'D', 'E', 'F'];
                      final letter = optIndex < letters.length ? letters[optIndex] : '${optIndex + 1}';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onTap: () {
                            ref.read(activeDuelProvider.notifier).setAnswer(
                              question.id,
                              opt.id,
                              question.type,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.08)
                                  : (isDark ? AppColors.cardDark : AppColors.cardLight),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? AppColors.primary.withValues(alpha: 0.15)
                                        : (isDark ? AppColors.neutral800 : AppColors.neutral200),
                                  ),
                                  child: Center(
                                    child: Text(
                                      letter,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected ? AppColors.primary : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    opt.content,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected ? AppColors.primary : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Bottom nav
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                border: Border(top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    if (_currentIndex > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _currentIndex--),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                          ),
                          child: const Text('Précédent'),
                        ),
                      ),
                    if (_currentIndex > 0) const SizedBox(width: 12),
                    Expanded(
                      child: _currentIndex < questions.length - 1
                          ? ElevatedButton(
                              onPressed: () => setState(() => _currentIndex++),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: const Text('Suivant', style: TextStyle(fontWeight: FontWeight.w700)),
                            )
                          : ElevatedButton.icon(
                              onPressed: _submitting ? null : _handleSubmit,
                              icon: _submitting
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                  : const Icon(Icons.check_circle_rounded, size: 20),
                              label: const Text('Terminer', style: TextStyle(fontWeight: FontWeight.w700)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
