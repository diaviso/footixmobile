import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design.dart';
import '../../../data/models/quiz_model.dart';
import '../../../providers/service_providers.dart';
import '../../../shared/widgets/scoreboard_header.dart';

class QuizCorrectionScreen extends ConsumerStatefulWidget {
  final String quizId;
  const QuizCorrectionScreen({super.key, required this.quizId});

  @override
  ConsumerState<QuizCorrectionScreen> createState() => _QuizCorrectionScreenState();
}

class _QuizCorrectionScreenState extends ConsumerState<QuizCorrectionScreen> {
  QuizModel? _quiz;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCorrection();
  }

  Future<void> _loadCorrection() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final service = ref.read(quizzesServiceProvider);
      final quiz = await service.getQuizCorrection(widget.quizId);
      if (!mounted) return;
      setState(() { _quiz = quiz; _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }
    if (_error != null || _quiz == null) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            const Text('Impossible de charger la correction'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadCorrection, child: const Text('Reessayer')),
          ]),
        ),
      );
    }

    final quiz = _quiz!;
    final questions = quiz.questions ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Scoreboard header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Back button
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.cardDark : AppColors.neutral100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                            ),
                            child: Icon(Icons.arrow_back_rounded, size: 20,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ScoreboardHeader(
                      title: 'Correction',
                      subtitle: quiz.title,
                      icon: Icons.fact_check_rounded,
                      rightContent: quiz.theme != null
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                quiz.theme!.title,
                                style: const TextStyle(
                                  color: AppColors.accentLight,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),

            // ── Info banner ──
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0A1628) : AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF1B2B40) : AppColors.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.sports_soccer, color: AppColors.primaryLight, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Voici les reponses correctes pour chaque question. Etudiez-les attentivement.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white.withValues(alpha: 0.6) : AppColors.primary.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Questions ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              sliver: SliverList.separated(
                itemCount: questions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final question = questions[index];
                  return _CorrectionQuestionCard(question: question, index: index);
                },
              ),
            ),

            // ── Back button ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppDesign.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppDesign.glowShadow(AppColors.primary),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.go('/quizzes'),
                      borderRadius: BorderRadius.circular(14),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sports_soccer, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('Retour aux quiz',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CORRECTION QUESTION CARD — with left accent band
// ═══════════════════════════════════════════════════════════════
class _CorrectionQuestionCard extends StatelessWidget {
  final QuestionModel question;
  final int index;
  const _CorrectionQuestionCard({required this.question, required this.index});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final options = question.options ?? [];
    final letters = ['A', 'B', 'C', 'D', 'E', 'F'];
    final hasCorrectAnswer = options.any((o) => o.isCorrect);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        boxShadow: AppDesign.softShadow(blur: 8, y: 2),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent band — green for correct, red for incorrect
            Container(
              width: 5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: hasCorrectAnswer
                      ? [AppColors.success, AppColors.success.withValues(alpha: 0.6)]
                      : [AppColors.error, AppColors.error.withValues(alpha: 0.6)],
                ),
              ),
            ),

            // Card content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question number badge — dark scoreboard style
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0A1628), Color(0xFF0D1D35)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF1B2B40)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Type badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      question.isQCU ? Icons.radio_button_checked : Icons.check_box_outlined,
                                      size: 12, color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      question.isQCU ? 'Choix unique' : 'Choix multiple',
                                      style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(question.content,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Options
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Column(
                      children: List.generate(options.length, (idx) {
                        final option = options[idx];
                        final isCorrect = option.isCorrect;

                        return Container(
                          margin: EdgeInsets.only(top: idx > 0 ? 8 : 0),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? (isDark
                                    ? AppColors.success.withValues(alpha: 0.1)
                                    : const Color(0xFFDBEAFE).withValues(alpha: 0.6))
                                : (isDark
                                    ? AppColors.error.withValues(alpha: 0.08)
                                    : const Color(0xFFFEE2E2).withValues(alpha: 0.4)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCorrect
                                  ? AppColors.success.withValues(alpha: 0.4)
                                  : AppColors.error.withValues(alpha: 0.25),
                              width: isCorrect ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Letter badge
                                  Container(
                                    width: 30, height: 30,
                                    decoration: BoxDecoration(
                                      color: isCorrect ? AppColors.success : AppColors.error.withValues(alpha: 0.7),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      idx < letters.length ? letters[idx] : '${idx + 1}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(option.content,
                                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14,
                                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                                  ),
                                  // Status icon
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: isCorrect
                                          ? AppColors.success.withValues(alpha: 0.15)
                                          : AppColors.error.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isCorrect ? Icons.check_rounded : Icons.close_rounded,
                                      size: 16,
                                      color: isCorrect ? AppColors.success : AppColors.error.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                              // Explanation
                              if (option.explanation != null && option.explanation!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isCorrect
                                        ? AppColors.success.withValues(alpha: 0.06)
                                        : AppColors.error.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isCorrect
                                          ? AppColors.success.withValues(alpha: 0.15)
                                          : AppColors.error.withValues(alpha: 0.15),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.lightbulb_outline_rounded, size: 16,
                                          color: isCorrect ? AppColors.success : AppColors.error),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          option.explanation!,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isDark
                                                ? Colors.white.withValues(alpha: 0.7)
                                                : (isCorrect ? const Color(0xFF1E3A5F) : const Color(0xFF991B1B)),
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
