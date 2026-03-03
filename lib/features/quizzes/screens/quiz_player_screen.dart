import 'dart:async';
import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design.dart';
import '../../../data/models/quiz_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/service_providers.dart';
import '../../../shared/widgets/scoreboard_header.dart';

class QuizPlayerScreen extends ConsumerStatefulWidget {
  final String quizId;
  const QuizPlayerScreen({super.key, required this.quizId});

  @override
  ConsumerState<QuizPlayerScreen> createState() => _QuizPlayerScreenState();
}

class _QuizPlayerScreenState extends ConsumerState<QuizPlayerScreen> with TickerProviderStateMixin {
  QuizModel? _quiz;
  Map<String, dynamic>? _attemptInfo;
  bool _isLoading = true;
  String? _error;

  // Countdown state
  bool _isCountdown = false;
  int _countdownTime = 15;
  Timer? _countdownTimer;

  // Playing state
  bool _isPlaying = false;
  int _currentIndex = 0;
  final Map<String, List<String>> _answers = {};
  int _timeLeft = 0;
  Timer? _timer;
  bool _isSubmitting = false;
  QuizSubmitResult? _result;
  bool _isPurchasing = false;

  // Result animations
  late AnimationController _resultIconController;
  late AnimationController _resultFadeController;
  late AnimationController _resultScoreController;
  late AnimationController _resultShakeController;

  // Confetti — multiple controllers for a rich, festive effect
  late ConfettiController _confettiCenter;
  late ConfettiController _confettiLeft;
  late ConfettiController _confettiRight;
  late ConfettiController _confettiTheme;

  void _startResultAnimations() {
    _resultIconController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _resultFadeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _resultScoreController.forward();
    });
    if (_result != null && !_result!.passed) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _resultShakeController.forward();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _resultIconController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _resultFadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _resultScoreController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _resultShakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _confettiCenter = ConfettiController(duration: const Duration(seconds: 5));
    _confettiLeft = ConfettiController(duration: const Duration(seconds: 4));
    _confettiRight = ConfettiController(duration: const Duration(seconds: 4));
    _confettiTheme = ConfettiController(duration: const Duration(seconds: 7));
    _loadQuiz();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    _resultIconController.dispose();
    _resultFadeController.dispose();
    _resultScoreController.dispose();
    _resultShakeController.dispose();
    _confettiCenter.dispose();
    _confettiLeft.dispose();
    _confettiRight.dispose();
    _confettiTheme.dispose();
    super.dispose();
  }

  Future<void> _loadQuiz() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final service = ref.read(quizzesServiceProvider);
      final quiz = await service.getQuiz(widget.quizId);
      Map<String, dynamic>? attemptInfo;
      try {
        attemptInfo = await service.getQuizAttempts(widget.quizId);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _quiz = quiz;
        _attemptInfo = attemptInfo;
        _timeLeft = quiz.timeLimit * 60;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _startCountdown() {
    setState(() {
      _isCountdown = true;
      _countdownTime = 15;
      _currentIndex = 0;
      _answers.clear();
      _result = null;
      _timeLeft = _quiz!.timeLimit * 60;
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdownTime <= 1) {
        t.cancel();
        _beginPlaying();
      } else {
        setState(() => _countdownTime--);
      }
    });
  }

  void _beginPlaying() {
    _countdownTimer?.cancel();
    setState(() {
      _isCountdown = false;
      _isPlaying = true;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeLeft <= 1) {
        t.cancel();
        _submitQuiz();
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  void _selectOption(String questionId, String optionId, String type) {
    setState(() {
      if (type == 'QCU') {
        _answers[questionId] = [optionId];
      } else {
        final current = _answers[questionId] ?? [];
        if (current.contains(optionId)) {
          _answers[questionId] = current.where((id) => id != optionId).toList();
        } else {
          _answers[questionId] = [...current, optionId];
        }
      }
    });
  }

  Future<void> _submitQuiz() async {
    if (_quiz == null || _isSubmitting) return;
    _timer?.cancel();
    setState(() => _isSubmitting = true);
    try {
      final service = ref.read(quizzesServiceProvider);
      final result = await service.submitQuiz(
        quizId: _quiz!.id,
        answers: _answers.entries.map((e) => {'questionId': e.key, 'selectedOptionIds': e.value}).toList(),
      );
      if (!mounted) return;
      setState(() { _result = result; _isPlaying = false; _isSubmitting = false; });
      // Reset and start result animations
      _resultIconController.reset();
      _resultFadeController.reset();
      _resultScoreController.reset();
      _resultShakeController.reset();
      _startResultAnimations();
      // Fire confetti on success — staggered multi-point bursts
      if (result.passed) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (!mounted) return;
          _confettiCenter.play();
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          _confettiLeft.play();
        });
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          _confettiRight.play();
        });
        if (result.themeCompleted) {
          Future.delayed(const Duration(milliseconds: 400), () {
            if (!mounted) return;
            _confettiTheme.play();
          });
        }
      }
      // Refresh user data (stars) after submission
      ref.read(authProvider.notifier).refreshUser();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _purchaseAttempt() async {
    setState(() => _isPurchasing = true);
    try {
      final service = ref.read(quizzesServiceProvider);
      await service.purchaseExtraAttempt(widget.quizId);
      await _loadQuiz();
      if (!mounted) return;
      // After successful purchase, go directly to countdown
      _startCountdown();
      // Refresh user data (stars) after purchase
      ref.read(authProvider.notifier).refreshUser();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
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
            const Text('Impossible de charger le quiz'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadQuiz, child: const Text('Reessayer')),
          ]),
        ),
      );
    }

    // Show result (with confetti overlay)
    if (_result != null) return _buildResultView();
    // Countdown
    if (_isCountdown) return _buildCountdownView();
    // Playing
    if (_isPlaying) return _buildPlayingView();
    // Pre-start
    return _buildPreStartView();
  }

  // ═══════════════════════════════════════════════════════════════
  // PRE-START VIEW
  // ═══════════════════════════════════════════════════════════════
  Widget _buildPreStartView() {
    final quiz = _quiz!;
    final questions = quiz.questions ?? [];
    final remainingAttempts = _attemptInfo?['remainingAttempts'] as int? ?? 3;
    final hasPassed = _attemptInfo?['hasPassed'] as bool? ?? false;
    final canPurchase = _attemptInfo?['canPurchaseAttempt'] as bool? ?? false;
    final extraCost = _attemptInfo?['extraAttemptCost'] as int? ?? 10;
    final user = ref.watch(currentUserProvider);
    final isStarLocked = !quiz.isFree && quiz.requiredStars > (user?.stars ?? 0);
    final isLocked = isStarLocked;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              ),
              const SizedBox(height: 12),

              // Quiz info card — stadium ticket style
              Container(
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0A1628), Color(0xFF0D1D35), Color(0xFF0A1628)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Pitch lines decoration
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 2),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -30,
                      bottom: -30,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.03), width: 2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (quiz.theme != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                              ),
                              child: Text(quiz.theme!.title, style: const TextStyle(color: AppColors.accentLight, fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          const SizedBox(height: 12),
                          Text(quiz.title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          // Stats row — scoreboard style
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _ScoreboardStat(icon: Icons.timer_outlined, value: '${quiz.timeLimit}', label: 'MIN'),
                                Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.1)),
                                _ScoreboardStat(icon: Icons.help_outline_rounded, value: '${questions.length}', label: 'Q.'),
                                Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.1)),
                                _ScoreboardStat(icon: Icons.flag_outlined, value: '${quiz.passingScore}%', label: 'MIN'),
                                Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.1)),
                                _ScoreboardStat(icon: Icons.bar_chart_rounded, value: quiz.difficulty.substring(0, 3).toUpperCase(), label: 'NIV.'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Status info
              if (hasPassed)
                _StatusBanner(
                  icon: Icons.check_circle_rounded,
                  color: AppColors.success,
                  title: 'Quiz reussi !',
                  subtitle: 'Vous pouvez rejouer sans regagner d\'etoiles.',
                ),
              if (isStarLocked)
                _StatusBanner(
                  icon: Icons.lock_rounded,
                  color: AppColors.accent,
                  title: 'Quiz verrouille',
                  subtitle: 'Requiert ${quiz.requiredStars} etoiles (vous en avez ${user?.stars ?? 0}).',
                ),
              if (!isLocked && remainingAttempts <= 0 && !hasPassed)
                Column(
                  children: [
                    _StatusBanner(
                      icon: Icons.block_rounded,
                      color: AppColors.error,
                      title: 'Plus de tentatives',
                      subtitle: 'Vous avez utilise toutes vos tentatives.',
                    ),
                    if (canPurchase) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isPurchasing ? null : _purchaseAttempt,
                          icon: _isPurchasing
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.star_rounded),
                          label: Text('Acheter une tentative ($extraCost etoiles)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

              if (!isLocked && !hasPassed && remainingAttempts > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.sports_soccer, size: 16, color: AppColors.textSecondaryLight),
                    const SizedBox(width: 6),
                    Text('$remainingAttempts tentative${remainingAttempts > 1 ? 's' : ''} restante${remainingAttempts > 1 ? 's' : ''}',
                        style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 14)),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // Start button — show if not locked and (has attempts OR already passed for replay)
              if (!isLocked && (hasPassed || remainingAttempts > 0))
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppDesign.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppDesign.glowShadow(AppColors.primary),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _startCountdown,
                      borderRadius: BorderRadius.circular(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(hasPassed ? Icons.replay_rounded : Icons.sports_soccer, size: 24, color: Colors.white),
                          const SizedBox(width: 10),
                          Text(
                            hasPassed ? 'Rejouer (sans etoiles)' : 'Coup d\'envoi !',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // View correction
              if ((_attemptInfo?['canViewCorrection'] as bool? ?? false)) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/quizzes/${widget.quizId}/correction'),
                    icon: const Icon(Icons.visibility_rounded),
                    label: const Text('Voir la correction'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // COUNTDOWN VIEW (15 seconds before quiz starts)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildCountdownView() {
    final quiz = _quiz!;
    final questions = quiz.questions ?? [];
    final progress = _countdownTime / 15;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Scoreboard-style header
                ScoreboardHeader(
                  title: 'Coup d\'envoi',
                  subtitle: quiz.title,
                  icon: Icons.sports_soccer,
                  live: true,
                ),
                const SizedBox(height: 40),

                // Circular countdown — whistle countdown
                SizedBox(
                  width: 180,
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 180,
                        height: 180,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 8,
                          backgroundColor: const Color(0xFF1B2B40),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      // Inner dark circle
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0A1628),
                          border: Border.all(color: const Color(0xFF1B2B40)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$_countdownTime',
                              style: const TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              'SEC',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent.withValues(alpha: 0.8),
                                letterSpacing: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                Text('Preparez-vous !',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),

                // Quiz rules — match info card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1628),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1B2B40)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.sports_soccer, size: 16, color: AppColors.accent),
                          const SizedBox(width: 8),
                          Text('Regles du match :',
                              style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _CountdownRule(
                        number: '1',
                        color: AppColors.primary,
                        text: '${questions.length} questions a repondre en ${quiz.timeLimit} minutes',
                      ),
                      const SizedBox(height: 12),
                      _CountdownRule(
                        number: '2',
                        color: AppColors.accent,
                        text: 'Score minimum requis : ${quiz.passingScore}% pour la victoire',
                      ),
                      const SizedBox(height: 12),
                      _CountdownRule(
                        number: '3',
                        color: const Color(0xFFE5C158),
                        text: 'Gagnez des etoiles selon votre performance et la difficulte',
                      ),
                      if (_attemptInfo != null && (_attemptInfo!['remainingAttempts'] as int? ?? 3) < 3) ...[
                        const SizedBox(height: 12),
                        _CountdownRule(
                          number: '!',
                          color: AppColors.warning,
                          text: 'Tentative ${4 - (_attemptInfo!['remainingAttempts'] as int? ?? 3)} sur 3',
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _countdownTimer?.cancel();
                          setState(() { _isCountdown = false; _countdownTime = 15; });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppColors.borderLight),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Annuler', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppDesign.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: AppDesign.glowShadow(AppColors.primary),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _beginPlaying,
                            borderRadius: BorderRadius.circular(14),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.sports_soccer, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Jouer !',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PLAYING VIEW
  // ═══════════════════════════════════════════════════════════════
  Widget _buildPlayingView() {
    final quiz = _quiz!;
    final questions = quiz.questions ?? [];
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(child: Text('Ce quiz ne contient aucune question.')),
      );
    }
    final question = questions[_currentIndex];
    final selectedIds = _answers[question.id] ?? [];
    final answeredCount = _answers.length;
    final progress = ((_currentIndex + 1) / questions.length);
    final isLastQuestion = _currentIndex == questions.length - 1;
    final isTimeLow = _timeLeft <= 60;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final letters = ['A', 'B', 'C', 'D', 'E', 'F'];
    final options = question.options ?? [];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Scoreboard timer bar ──
            Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0A1628), Color(0xFF0D1D35), Color(0xFF0A1628)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                border: Border.all(color: const Color(0xFF1B2B40)),
              ),
              child: Row(
                children: [
                  // Close button
                  GestureDetector(
                    onTap: _showQuitDialog,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Quiz title + question count
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(quiz.title,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('Q.${_currentIndex + 1}/${questions.length} | $answeredCount repondue${answeredCount > 1 ? 's' : ''}',
                            style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5), fontFamily: 'monospace')),
                      ],
                    ),
                  ),
                  // Timer display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isTimeLow ? AppColors.error.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isTimeLow ? AppColors.error.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_rounded, size: 16,
                            color: isTimeLow ? const Color(0xFFFF6B6B) : AppColors.accent),
                        const SizedBox(width: 6),
                        Text(
                          _formatTime(_timeLeft),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            fontSize: 16,
                            color: isTimeLow ? const Color(0xFFFF6B6B) : Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Pitch-style progress bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: _PitchProgressBar(progress: progress, isDark: isDark),
            ),

            // ── Question area ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question type badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(question.isQCU ? Icons.radio_button_checked : Icons.check_box_outlined,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            question.isQCU ? 'Choix unique' : 'Choix multiple',
                            style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Question text
                    Text(question.content,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.4)),
                    if (question.isQCM)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('Selectionnez toutes les reponses correctes',
                            style: TextStyle(fontSize: 13, color: AppColors.textMutedLight)),
                      ),
                    const SizedBox(height: 20),

                    // ── 2-column option grid with A/B/C/D badges ──
                    if (options.length <= 4)
                      _buildOptionGrid(options, selectedIds, letters, question)
                    else
                      // Fallback to list for more than 4 options
                      ...List.generate(options.length, (idx) {
                        return _buildOptionTile(options[idx], idx, selectedIds, letters, question);
                      }),
                  ],
                ),
              ),
            ),

            // ── Navigation bar ──
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                border: Border(top: BorderSide(color: (isDark ? AppColors.borderDark : AppColors.borderLight).withValues(alpha: 0.5))),
              ),
              child: Column(
                children: [
                  // Question dot navigator
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(questions.length, (i) {
                        final isAnswered = _answers.containsKey(questions[i].id);
                        final isCurrent = i == _currentIndex;
                        return GestureDetector(
                          onTap: () => setState(() => _currentIndex = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: isCurrent ? 24 : 10,
                            height: 10,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? AppColors.primary
                                  : (isAnswered ? AppColors.success : (isDark ? const Color(0xFF1B2B40) : AppColors.neutral200)),
                              borderRadius: BorderRadius.circular(5),
                              border: isCurrent ? Border.all(color: AppColors.primaryLight, width: 1) : null,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  // Navigation buttons
                  Row(
                    children: [
                      // Previous
                      if (_currentIndex > 0)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => setState(() => _currentIndex--),
                            icon: const Icon(Icons.chevron_left_rounded),
                            label: const Text('Precedent'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      const SizedBox(width: 12),
                      // Next / Submit
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: isLastQuestion
                                ? const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)])
                                : AppDesign.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: AppDesign.glowShadow(isLastQuestion ? AppColors.success : AppColors.primary, blur: 10),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: isLastQuestion
                                  ? (_isSubmitting ? null : _submitQuiz)
                                  : () => setState(() => _currentIndex++),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (isLastQuestion && _isSubmitting)
                                      const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    else
                                      Icon(isLastQuestion ? Icons.sports_score : Icons.chevron_right_rounded, color: Colors.white, size: 20),
                                    const SizedBox(width: 6),
                                    Text(
                                      isLastQuestion ? 'Coup de sifflet !' : 'Suivant',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 2-column grid for answer options ──
  Widget _buildOptionGrid(List<OptionModel> options, List<String> selectedIds, List<String> letters, QuestionModel question) {
    final rows = <Widget>[];
    for (var i = 0; i < options.length; i += 2) {
      rows.add(
        Row(
          children: [
            Expanded(child: _buildOptionCard(options[i], i, selectedIds, letters, question)),
            const SizedBox(width: 10),
            if (i + 1 < options.length)
              Expanded(child: _buildOptionCard(options[i + 1], i + 1, selectedIds, letters, question))
            else
              const Expanded(child: SizedBox()),
          ],
        ),
      );
      if (i + 2 < options.length) rows.add(const SizedBox(height: 10));
    }
    return Column(children: rows);
  }

  Widget _buildOptionCard(OptionModel option, int idx, List<String> selectedIds, List<String> letters, QuestionModel question) {
    final isSelected = selectedIds.contains(option.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final letterColors = [
      const Color(0xFFC41E3A), // A - Red
      const Color(0xFF3B82F6), // B - Blue
      const Color(0xFFD4AF37), // C - Gold
      const Color(0xFF10B981), // D - Emerald
      const Color(0xFF8B5CF6), // E - Purple
      const Color(0xFFF97316), // F - Orange
    ];
    final letterColor = idx < letterColors.length ? letterColors[idx] : AppColors.primary;

    return BounceTap(
      onTap: () => _selectOption(question.id, option.id, question.type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? letterColor.withValues(alpha: 0.12)
              : (isDark ? AppColors.cardDark : AppColors.cardLight),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? letterColor : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: letterColor.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))]
              : AppDesign.softShadow(blur: 4, y: 1),
        ),
        child: Column(
          children: [
            // Letter badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected ? letterColor : letterColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                idx < letters.length ? letters[idx] : '${idx + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: isSelected ? Colors.white : letterColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              option.content,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            if (isSelected) ...[
              const SizedBox(height: 6),
              Icon(Icons.check_circle_rounded, color: letterColor, size: 18),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(OptionModel option, int idx, List<String> selectedIds, List<String> letters, QuestionModel question) {
    final isSelected = selectedIds.contains(option.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BounceTap(
        onTap: () => _selectOption(question.id, option.id, question.type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : (isDark ? AppColors.cardDark : AppColors.cardLight),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: AppDesign.softShadow(blur: 4, y: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.neutral100,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  idx < letters.length ? letters[idx] : '${idx + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.textSecondaryLight,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(option.content, style: TextStyle(fontSize: 15, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight))),
              if (isSelected)
                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter le match ?'),
        content: const Text('Votre progression sera perdue. Voulez-vous soumettre vos reponses actuelles ou quitter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () { Navigator.pop(ctx); _timer?.cancel(); context.pop(); },
            child: const Text('Quitter', style: TextStyle(color: AppColors.error)),
          ),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); _submitQuiz(); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Soumettre'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // RESULT VIEW — "RESULTAT DU MATCH" scoreboard
  // ═══════════════════════════════════════════════════════════════
  Widget _buildResultView() {
    final r = _result!;
    final passed = r.passed;

    // Animations
    final iconScale = CurvedAnimation(parent: _resultIconController, curve: Curves.elasticOut);
    final fadeIn = CurvedAnimation(parent: _resultFadeController, curve: Curves.easeOut);
    final scoreAnim = CurvedAnimation(parent: _resultScoreController, curve: Curves.easeOutCubic);
    final shake = CurvedAnimation(parent: _resultShakeController, curve: Curves.elasticIn);

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: passed
                    ? [const Color(0xFF0A1628), const Color(0xFF0D1D35), const Color(0xFF0A1628)]
                    : [const Color(0xFF1A0808), const Color(0xFF0F0F0F), const Color(0xFF1A0808)],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // ── RESULTAT DU MATCH header ──
                  ScoreboardHeader(
                    title: 'Resultat du match',
                    icon: passed ? Icons.emoji_events_rounded : Icons.sports_soccer,
                    live: false,
                    rightContent: FadeTransition(
                      opacity: fadeIn,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: passed ? AppColors.success.withValues(alpha: 0.2) : AppColors.error.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: passed ? AppColors.success.withValues(alpha: 0.4) : AppColors.error.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          passed ? 'VICTOIRE' : 'DEFAITE',
                          style: TextStyle(
                            color: passed ? AppColors.success : AppColors.error,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Large animated score display ──
                  ScaleTransition(
                    scale: iconScale,
                    child: AnimatedBuilder(
                      animation: shake,
                      builder: (context, child) {
                        if (!passed) {
                          final wobble = math.sin(shake.value * math.pi * 6) * 10 * (1 - shake.value);
                          return Transform.translate(offset: Offset(wobble, 0), child: child);
                        }
                        return child!;
                      },
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: passed
                                ? [AppColors.success.withValues(alpha: 0.2), Colors.transparent]
                                : [AppColors.error.withValues(alpha: 0.2), Colors.transparent],
                          ),
                          border: Border.all(
                            color: passed ? AppColors.success.withValues(alpha: 0.3) : AppColors.error.withValues(alpha: 0.3),
                            width: 3,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Soccer ball icon
                            Icon(
                              passed ? Icons.emoji_events_rounded : Icons.sports_soccer,
                              size: 32,
                              color: passed ? AppColors.accent : AppColors.error.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 4),
                            AnimatedBuilder(
                              animation: scoreAnim,
                              builder: (context, _) {
                                final displayScore = (r.score * scoreAnim.value).round();
                                return Text(
                                  '$displayScore%',
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'monospace',
                                    color: passed ? Colors.white : const Color(0xFFFF6B6B),
                                    letterSpacing: 2,
                                  ),
                                );
                              },
                            ),
                            Text(
                              'SCORE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.4),
                                letterSpacing: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── VICTOIRE / DEFAITE ──
                  FadeTransition(
                    opacity: fadeIn,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(fadeIn),
                      child: Column(
                        children: [
                          Text(
                            passed
                                ? (r.themeCompleted ? 'CHAMPION !' : 'VICTOIRE !')
                                : 'DEFAITE',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: passed ? AppColors.accent : const Color(0xFFFF6B6B),
                              letterSpacing: 3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            r.themeCompleted
                                ? 'Tous les quiz du theme "${r.themeName}" sont completes !'
                                : (passed ? 'Vous avez brillamment reussi ce quiz !' : 'Ne baisse pas les bras, tu peux y arriver !'),
                            style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.5)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Passing score line
                  FadeTransition(
                    opacity: fadeIn,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.flag_outlined, size: 14, color: Colors.white.withValues(alpha: 0.3)),
                        const SizedBox(width: 4),
                        Text('Score minimum: ${r.passingScore}%',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13, fontFamily: 'monospace')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Theme completion badge
                  if (r.themeCompleted) ...[
                    FadeTransition(
                      opacity: fadeIn,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: AppDesign.goldGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: AppDesign.glowShadow(AppColors.accent, blur: 20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.emoji_events_rounded, size: 18, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Theme Complete !', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            SizedBox(width: 8),
                            Icon(Icons.emoji_events_rounded, size: 18, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Stars earned — gold banner ──
                  FadeTransition(
                    opacity: scoreAnim,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(scoreAnim),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2A2000), Color(0xFF3D2E00), Color(0xFF2A2000)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.accent.withValues(alpha: 0.3), width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.star_rounded, size: 28, color: AppColors.accent),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('+${r.starsEarned} etoile${r.starsEarned > 1 ? 's' : ''}',
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.accent)),
                                Text('Total: ${r.totalStars} etoiles',
                                    style: TextStyle(fontSize: 13, color: AppColors.accent.withValues(alpha: 0.6))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Animated progress bar
                  AnimatedBuilder(
                    animation: scoreAnim,
                    builder: (context, child) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Performance', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4), fontWeight: FontWeight.w600)),
                                Text('${(r.score * scoreAnim.value).round()}%',
                                    style: TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w900,
                                        color: passed ? AppColors.success : AppColors.error)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: (r.score / 100) * scoreAnim.value,
                                minHeight: 8,
                                backgroundColor: Colors.white.withValues(alpha: 0.08),
                                valueColor: AlwaysStoppedAnimation<Color>(passed ? AppColors.success : AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Remaining attempts
                  if (!passed) ...[
                    const SizedBox(height: 16),
                    FadeTransition(
                      opacity: scoreAnim,
                      child: r.remainingAttempts > 0
                          ? Text('Il vous reste ${r.remainingAttempts} tentative${r.remainingAttempts > 1 ? 's' : ''}',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)))
                          : const Text('Vous avez utilise vos 3 tentatives',
                              style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // ── Action buttons ──
                  FadeTransition(
                    opacity: scoreAnim,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(scoreAnim),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => context.go('/quizzes'),
                                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                                  label: const Text('Retour'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                              if (r.remainingAttempts > 0 && !passed) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: AppDesign.primaryGradient,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: AppDesign.glowShadow(AppColors.primary),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _startCountdown,
                                        borderRadius: BorderRadius.circular(14),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.replay_rounded, size: 18, color: Colors.white),
                                              const SizedBox(width: 6),
                                              Text('Rejouer (${r.remainingAttempts})',
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (r.canViewCorrection) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () => context.push('/quizzes/${widget.quizId}/correction'),
                                icon: const Icon(Icons.visibility_rounded),
                                label: const Text('Voir la correction'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Confetti overlays — multi-point festive bursts
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiCenter,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Color(0xFF26ccff), Color(0xFFa25afd), Color(0xFFff5e7e), Color(0xFF88ff5a), Color(0xFFfcff42), Color(0xFFffa62d), Color(0xFFff6b6b)],
              numberOfParticles: 50,
              maxBlastForce: 40,
              minBlastForce: 15,
              emissionFrequency: 0.03,
              gravity: 0.12,
            ),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: ConfettiWidget(
              confettiController: _confettiLeft,
              blastDirection: -0.5,
              shouldLoop: false,
              colors: const [Color(0xFFff5e7e), Color(0xFFfcff42), Color(0xFF26ccff), Color(0xFF88ff5a), Color(0xFFa25afd)],
              numberOfParticles: 35,
              maxBlastForce: 50,
              minBlastForce: 20,
              emissionFrequency: 0.04,
              gravity: 0.15,
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: ConfettiWidget(
              confettiController: _confettiRight,
              blastDirection: -2.6,
              shouldLoop: false,
              colors: const [Color(0xFFffa62d), Color(0xFF88ff5a), Color(0xFFa25afd), Color(0xFF26ccff), Color(0xFFff5e7e)],
              numberOfParticles: 35,
              maxBlastForce: 50,
              minBlastForce: 20,
              emissionFrequency: 0.04,
              gravity: 0.15,
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiTheme,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Color(0xFFFFE400), Color(0xFFFFBD00), Color(0xFFE89400), Color(0xFFa786ff), Color(0xFFfd8bbc), Color(0xFF10b981), Color(0xFFFF6B6B)],
              numberOfParticles: 60,
              maxBlastForce: 55,
              minBlastForce: 20,
              emissionFrequency: 0.02,
              gravity: 0.08,
              createParticlePath: (size) {
                final path = Path();
                final w = size.width;
                final h = size.height;
                path.moveTo(w * 0.5, 0);
                path.lineTo(w * 0.62, h * 0.38);
                path.lineTo(w, h * 0.38);
                path.lineTo(w * 0.69, h * 0.62);
                path.lineTo(w * 0.81, h);
                path.lineTo(w * 0.5, h * 0.75);
                path.lineTo(w * 0.19, h);
                path.lineTo(w * 0.31, h * 0.62);
                path.lineTo(0, h * 0.38);
                path.lineTo(w * 0.38, h * 0.38);
                path.close();
                return path;
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PITCH-STYLE PROGRESS BAR (goal-to-goal)
// ═══════════════════════════════════════════════════════════════
class _PitchProgressBar extends StatelessWidget {
  final double progress; // 0.0 - 1.0
  final bool isDark;
  const _PitchProgressBar({required this.progress, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isDark ? const Color(0xFF0A1628) : const Color(0xFFE8F0E8),
        border: Border.all(
          color: isDark ? const Color(0xFF1B2B40) : const Color(0xFFC8D8C8),
        ),
      ),
      child: Stack(
        children: [
          // Center circle (pitch decoration)
          Center(
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
                  width: 1.5,
                ),
              ),
            ),
          ),
          // Center line
          Center(
            child: Container(
              width: 1.5,
              height: 36,
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          // Left goal
          Positioned(
            left: 6,
            top: 8,
            bottom: 8,
            child: Icon(Icons.sports_soccer, size: 16,
                color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.2)),
          ),
          // Right goal
          Positioned(
            right: 6,
            top: 8,
            bottom: 8,
            child: Icon(Icons.sports_score, size: 16,
                color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.2)),
          ),
          // Progress fill
          Padding(
            padding: const EdgeInsets.all(4),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: (constraints.maxWidth * progress).clamp(0, constraints.maxWidth),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2E7D32), Color(0xFF4CAF50), Color(0xFF66BB6A)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Ball indicator at progress point
          Padding(
            padding: const EdgeInsets.all(4),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final ballPos = (constraints.maxWidth * progress).clamp(0.0, constraints.maxWidth - 24);
                return Stack(
                  children: [
                    Positioned(
                      left: ballPos,
                      top: 1,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
                          ],
                        ),
                        child: const Icon(Icons.sports_soccer, size: 16, color: Color(0xFF333333)),
                      ),
                    ),
                  ],
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
// SCOREBOARD STAT (for pre-start view)
// ═══════════════════════════════════════════════════════════════
class _ScoreboardStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _ScoreboardStat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 14, color: AppColors.accent.withValues(alpha: 0.7)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, fontFamily: 'monospace')),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════
class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _StatusBanner({required this.icon, required this.color, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                Text(subtitle, style: TextStyle(fontSize: 13, color: color.withValues(alpha: 0.8))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownRule extends StatelessWidget {
  final String number;
  final Color color;
  final String text;
  const _CountdownRule({required this.number, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          alignment: Alignment.center,
          child: Text(number, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14)),
          ),
        ),
      ],
    );
  }
}
