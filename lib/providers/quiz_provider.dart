import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/api/api_exception.dart';
import '../data/models/quiz_model.dart';
import '../data/services/quizzes_service.dart';
import 'service_providers.dart';

/// State for the quiz player
class QuizPlayerState {
  final QuizModel? quiz;
  final int currentQuestionIndex;
  final Map<String, List<String>> selectedAnswers; // questionId -> [optionIds]
  final int remainingSeconds;
  final bool isSubmitting;
  final bool isCountdown;
  final int countdownSeconds;
  final QuizSubmitResult? result;
  final String? error;

  const QuizPlayerState({
    this.quiz,
    this.currentQuestionIndex = 0,
    this.selectedAnswers = const {},
    this.remainingSeconds = 0,
    this.isSubmitting = false,
    this.isCountdown = false,
    this.countdownSeconds = 15,
    this.result,
    this.error,
  });

  int get totalQuestions => quiz?.questions?.length ?? 0;
  bool get isLastQuestion => currentQuestionIndex >= totalQuestions - 1;
  bool get isFirstQuestion => currentQuestionIndex == 0;
  QuestionModel? get currentQuestion =>
      quiz?.questions != null && currentQuestionIndex < totalQuestions
          ? quiz!.questions![currentQuestionIndex]
          : null;

  int get answeredCount => selectedAnswers.length;

  QuizPlayerState copyWith({
    QuizModel? quiz,
    int? currentQuestionIndex,
    Map<String, List<String>>? selectedAnswers,
    int? remainingSeconds,
    bool? isSubmitting,
    bool? isCountdown,
    int? countdownSeconds,
    QuizSubmitResult? result,
    String? error,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return QuizPlayerState(
      quiz: quiz ?? this.quiz,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isCountdown: isCountdown ?? this.isCountdown,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class QuizPlayerNotifier extends StateNotifier<QuizPlayerState> {
  final QuizzesService _quizzesService;
  Timer? _timer;

  QuizPlayerNotifier(this._quizzesService) : super(const QuizPlayerState());

  /// Load quiz and start countdown
  Future<void> loadQuiz(String quizId) async {
    state = const QuizPlayerState();
    try {
      final quiz = await _quizzesService.getQuiz(quizId);
      state = state.copyWith(
        quiz: quiz,
        remainingSeconds: quiz.timeLimit * 60,
        isCountdown: true,
        countdownSeconds: 15,
      );
      _startCountdown();
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.countdownSeconds > 1) {
        state = state.copyWith(countdownSeconds: state.countdownSeconds - 1);
      } else {
        timer.cancel();
        state = state.copyWith(isCountdown: false);
        _startQuizTimer();
      }
    });
  }

  void _startQuizTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 1) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        timer.cancel();
        submitQuiz();
      }
    });
  }

  /// Select/deselect an option
  void toggleOption(String questionId, String optionId, bool isQCM) {
    final current = Map<String, List<String>>.from(state.selectedAnswers);
    final selected = List<String>.from(current[questionId] ?? []);

    if (isQCM) {
      if (selected.contains(optionId)) {
        selected.remove(optionId);
      } else {
        selected.add(optionId);
      }
    } else {
      // QCU: single selection
      selected
        ..clear()
        ..add(optionId);
    }

    current[questionId] = selected;
    state = state.copyWith(selectedAnswers: current);
  }

  /// Navigate to next question
  void nextQuestion() {
    if (!state.isLastQuestion) {
      state = state.copyWith(currentQuestionIndex: state.currentQuestionIndex + 1);
    }
  }

  /// Navigate to previous question
  void previousQuestion() {
    if (!state.isFirstQuestion) {
      state = state.copyWith(currentQuestionIndex: state.currentQuestionIndex - 1);
    }
  }

  /// Go to specific question
  void goToQuestion(int index) {
    if (index >= 0 && index < state.totalQuestions) {
      state = state.copyWith(currentQuestionIndex: index);
    }
  }

  /// Submit quiz
  Future<void> submitQuiz() async {
    _timer?.cancel();
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final answers = state.selectedAnswers.entries.map((e) {
        return {
          'questionId': e.key,
          'selectedOptionIds': e.value,
        };
      }).toList();

      final result = await _quizzesService.submitQuiz(
        quizId: state.quiz!.id,
        answers: answers,
      );
      state = state.copyWith(result: result, isSubmitting: false);
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message, isSubmitting: false);
    }
  }

  /// Reset state
  void reset() {
    _timer?.cancel();
    state = const QuizPlayerState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final quizPlayerProvider =
    StateNotifierProvider.autoDispose<QuizPlayerNotifier, QuizPlayerState>((ref) {
  return QuizPlayerNotifier(ref.watch(quizzesServiceProvider));
});

/// Quizzes list with user status
final quizzesWithStatusProvider = FutureProvider.autoDispose<List<QuizModel>>((ref) async {
  final service = ref.watch(quizzesServiceProvider);
  return service.getQuizzesWithStatus();
});

/// User attempts
final userAttemptsProvider = FutureProvider.autoDispose<List<QuizAttemptModel>>((ref) async {
  final service = ref.watch(quizzesServiceProvider);
  return service.getUserAttempts();
});
