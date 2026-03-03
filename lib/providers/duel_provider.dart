import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/duel_model.dart';
import '../data/services/duel_service.dart';
import 'service_providers.dart';

/// State for the duel list
class DuelListState {
  final List<DuelListItem> duels;
  final bool isLoading;
  final String? error;

  const DuelListState({
    this.duels = const [],
    this.isLoading = false,
    this.error,
  });

  DuelListState copyWith({
    List<DuelListItem>? duels,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return DuelListState(
      duels: duels ?? this.duels,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class DuelListNotifier extends StateNotifier<DuelListState> {
  final DuelService _service;

  DuelListNotifier(this._service) : super(const DuelListState());

  Future<void> loadDuels() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final duels = await _service.getMyDuels();
      state = state.copyWith(duels: duels, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final duelListProvider =
    StateNotifierProvider<DuelListNotifier, DuelListState>((ref) {
  return DuelListNotifier(ref.watch(duelServiceProvider));
});

/// State for a single active duel (lobby / play / results)
class ActiveDuelState {
  final DuelModel? duel;
  final DuelQuestionsResponse? questionsResponse;
  final Map<String, List<String>> answers;
  final bool isLoading;
  final bool isSubmitting;
  final bool hasSubmitted;
  final String? error;
  final int? submitScore;
  final int? submitCorrect;

  const ActiveDuelState({
    this.duel,
    this.questionsResponse,
    this.answers = const {},
    this.isLoading = false,
    this.isSubmitting = false,
    this.hasSubmitted = false,
    this.error,
    this.submitScore,
    this.submitCorrect,
  });

  ActiveDuelState copyWith({
    DuelModel? duel,
    DuelQuestionsResponse? questionsResponse,
    Map<String, List<String>>? answers,
    bool? isLoading,
    bool? isSubmitting,
    bool? hasSubmitted,
    String? error,
    int? submitScore,
    int? submitCorrect,
    bool clearError = false,
    bool clearDuel = false,
  }) {
    return ActiveDuelState(
      duel: clearDuel ? null : (duel ?? this.duel),
      questionsResponse: questionsResponse ?? this.questionsResponse,
      answers: answers ?? this.answers,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      hasSubmitted: hasSubmitted ?? this.hasSubmitted,
      error: clearError ? null : (error ?? this.error),
      submitScore: submitScore ?? this.submitScore,
      submitCorrect: submitCorrect ?? this.submitCorrect,
    );
  }
}

class ActiveDuelNotifier extends StateNotifier<ActiveDuelState> {
  final DuelService _service;
  Timer? _pollTimer;

  ActiveDuelNotifier(this._service) : super(const ActiveDuelState());

  Future<DuelModel?> createDuel({
    required int maxParticipants,
    required String difficulty,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final duel = await _service.create(
        maxParticipants: maxParticipants,
        difficulty: difficulty,
      );
      state = state.copyWith(duel: duel, isLoading: false);
      return duel;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<DuelModel?> joinDuel(String code) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final duel = await _service.join(code);
      state = state.copyWith(duel: duel, isLoading: false);
      return duel;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<void> loadDuel(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final duel = await _service.getDuel(id);
      state = state.copyWith(duel: duel, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refreshDuel() async {
    if (state.duel == null) return;
    try {
      final duel = await _service.getDuel(state.duel!.id);
      state = state.copyWith(duel: duel);
    } catch (_) {}
  }

  void startPolling({
    required void Function(DuelModel duel) onUpdate,
  }) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (state.duel == null) return;
      try {
        final duel = await _service.getDuel(state.duel!.id);
        state = state.copyWith(duel: duel);
        onUpdate(duel);
      } catch (_) {}
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<bool> launchDuel() async {
    if (state.duel == null) return false;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.launch(state.duel!.id);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> leaveDuel() async {
    if (state.duel == null) return false;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.leave(state.duel!.id);
      stopPolling();
      state = const ActiveDuelState();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> loadQuestions() async {
    if (state.duel == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final qr = await _service.getQuestions(state.duel!.id);
      state = state.copyWith(questionsResponse: qr, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setAnswer(String questionId, String optionId, String type) {
    final current = Map<String, List<String>>.from(state.answers);
    if (type == 'QCU') {
      current[questionId] = [optionId];
    } else {
      final existing = List<String>.from(current[questionId] ?? []);
      if (existing.contains(optionId)) {
        existing.remove(optionId);
      } else {
        existing.add(optionId);
      }
      current[questionId] = existing;
    }
    state = state.copyWith(answers: current);
  }

  Future<void> submitAnswers() async {
    if (state.duel == null || state.isSubmitting || state.hasSubmitted) return;
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final result = await _service.submit(
        duelId: state.duel!.id,
        answers: state.answers,
      );
      state = state.copyWith(
        isSubmitting: false,
        hasSubmitted: true,
        submitScore: result['score'] as int?,
        submitCorrect: result['correctCount'] as int?,
      );
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
    }
  }

  void reset() {
    stopPolling();
    state = const ActiveDuelState();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}

final activeDuelProvider =
    StateNotifierProvider<ActiveDuelNotifier, ActiveDuelState>((ref) {
  return ActiveDuelNotifier(ref.watch(duelServiceProvider));
});
