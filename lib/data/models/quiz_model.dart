class QuizModel {
  final String id;
  final String themeId;
  final String title;
  final String description;
  final String difficulty;
  final int timeLimit;
  final int passingScore;
  final int requiredStars;
  final int displayOrder;
  final bool isFree;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final QuizThemeInfo? theme;
  final List<QuestionModel>? questions;
  final QuizCount? count;
  final QuizUserStatus? userStatus;

  const QuizModel({
    required this.id,
    required this.themeId,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.timeLimit,
    required this.passingScore,
    this.requiredStars = 0,
    this.displayOrder = 0,
    this.isFree = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.theme,
    this.questions,
    this.count,
    this.userStatus,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      id: json['id'] as String,
      themeId: json['themeId'] as String? ?? '',
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? 'MOYEN',
      timeLimit: json['timeLimit'] as int? ?? 10,
      passingScore: json['passingScore'] as int? ?? 70,
      requiredStars: json['requiredStars'] as int? ?? 0,
      displayOrder: json['displayOrder'] as int? ?? 0,
      isFree: json['isFree'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      theme: json['theme'] != null
          ? QuizThemeInfo.fromJson(json['theme'] as Map<String, dynamic>)
          : null,
      questions: json['questions'] != null
          ? (json['questions'] as List)
              .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
              .toList()
          : null,
      count: json['_count'] != null
          ? QuizCount.fromJson(json['_count'] as Map<String, dynamic>)
          : null,
      userStatus: json['userStatus'] != null
          ? QuizUserStatus.fromJson(json['userStatus'] as Map<String, dynamic>)
          : null,
    );
  }
}

class QuizThemeInfo {
  final String? id;
  final String title;

  const QuizThemeInfo({this.id, required this.title});

  factory QuizThemeInfo.fromJson(Map<String, dynamic> json) {
    return QuizThemeInfo(
      id: json['id'] as String?,
      title: json['title'] as String? ?? '',
    );
  }
}

class QuizCount {
  final int questions;

  const QuizCount({required this.questions});

  factory QuizCount.fromJson(Map<String, dynamic> json) {
    return QuizCount(questions: json['questions'] as int? ?? 0);
  }
}

class QuizUserStatus {
  final bool isUnlocked;
  final int requiredStars;
  final bool hasPassed;
  final bool isCompleted;
  final int remainingAttempts;
  final int totalAttempts;
  final int? bestScore;
  final bool canPurchaseAttempt;
  final int extraAttemptCost;

  const QuizUserStatus({
    required this.isUnlocked,
    required this.requiredStars,
    required this.hasPassed,
    required this.isCompleted,
    required this.remainingAttempts,
    required this.totalAttempts,
    this.bestScore,
    required this.canPurchaseAttempt,
    required this.extraAttemptCost,
  });

  factory QuizUserStatus.fromJson(Map<String, dynamic> json) {
    return QuizUserStatus(
      isUnlocked: json['isUnlocked'] as bool? ?? true,
      requiredStars: json['requiredStars'] as int? ?? 0,
      hasPassed: json['hasPassed'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
      remainingAttempts: json['remainingAttempts'] as int? ?? 3,
      totalAttempts: json['totalAttempts'] as int? ?? 0,
      bestScore: json['bestScore'] as int?,
      canPurchaseAttempt: json['canPurchaseAttempt'] as bool? ?? false,
      extraAttemptCost: json['extraAttemptCost'] as int? ?? 10,
    );
  }
}

class QuestionModel {
  final String id;
  final String quizId;
  final String content;
  final String type;
  final String createdAt;
  final String updatedAt;
  final List<OptionModel>? options;
  final String? quizTitle;
  final String? themeTitle;

  const QuestionModel({
    required this.id,
    required this.quizId,
    required this.content,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.options,
    this.quizTitle,
    this.themeTitle,
  });

  bool get isQCM => type == 'QCM';
  bool get isQCU => type == 'QCU';

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as String,
      quizId: json['quizId'] as String? ?? '',
      content: json['content'] as String,
      type: json['type'] as String? ?? 'QCU',
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      options: json['options'] != null
          ? (json['options'] as List)
              .map((o) => OptionModel.fromJson(o as Map<String, dynamic>))
              .toList()
          : null,
      quizTitle: json['quizTitle'] as String?,
      themeTitle: json['themeTitle'] as String?,
    );
  }
}

class OptionModel {
  final String id;
  final String questionId;
  final String content;
  final bool isCorrect;
  final String? explanation;

  const OptionModel({
    required this.id,
    required this.questionId,
    required this.content,
    required this.isCorrect,
    this.explanation,
  });

  factory OptionModel.fromJson(Map<String, dynamic> json) {
    return OptionModel(
      id: json['id'] as String,
      questionId: json['questionId'] as String? ?? '',
      content: json['content'] as String,
      isCorrect: json['isCorrect'] as bool? ?? false,
      explanation: json['explanation'] as String?,
    );
  }
}

class QuizAttemptModel {
  final String id;
  final String userId;
  final String quizId;
  final int score;
  final int starsEarned;
  final String completedAt;
  final QuizAttemptQuizInfo? quiz;

  const QuizAttemptModel({
    required this.id,
    required this.userId,
    required this.quizId,
    required this.score,
    required this.starsEarned,
    required this.completedAt,
    this.quiz,
  });

  factory QuizAttemptModel.fromJson(Map<String, dynamic> json) {
    return QuizAttemptModel(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      quizId: json['quizId'] as String? ?? '',
      score: json['score'] as int? ?? 0,
      starsEarned: json['starsEarned'] as int? ?? 0,
      completedAt: json['completedAt'] as String? ?? '',
      quiz: json['quiz'] != null
          ? QuizAttemptQuizInfo.fromJson(json['quiz'] as Map<String, dynamic>)
          : null,
    );
  }
}

class QuizAttemptQuizInfo {
  final String id;
  final String title;
  final int passingScore;
  final String difficulty;
  final QuizThemeInfo? theme;

  const QuizAttemptQuizInfo({
    required this.id,
    required this.title,
    required this.passingScore,
    required this.difficulty,
    this.theme,
  });

  factory QuizAttemptQuizInfo.fromJson(Map<String, dynamic> json) {
    return QuizAttemptQuizInfo(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      passingScore: json['passingScore'] as int? ?? 70,
      difficulty: json['difficulty'] as String? ?? 'MOYEN',
      theme: json['theme'] != null
          ? QuizThemeInfo.fromJson(json['theme'] as Map<String, dynamic>)
          : null,
    );
  }
}

class QuizSubmitResult {
  final int score;
  final bool passed;
  final int passingScore;
  final int starsEarned;
  final int totalStars;
  final int remainingAttempts;
  final bool canViewCorrection;
  final bool themeCompleted;
  final String themeName;

  const QuizSubmitResult({
    required this.score,
    required this.passed,
    required this.passingScore,
    required this.starsEarned,
    required this.totalStars,
    required this.remainingAttempts,
    required this.canViewCorrection,
    required this.themeCompleted,
    required this.themeName,
  });

  factory QuizSubmitResult.fromJson(Map<String, dynamic> json) {
    return QuizSubmitResult(
      score: json['score'] as int? ?? 0,
      passed: json['passed'] as bool? ?? false,
      passingScore: json['passingScore'] as int? ?? 70,
      starsEarned: json['starsEarned'] as int? ?? 0,
      totalStars: json['totalStars'] as int? ?? 0,
      remainingAttempts: json['remainingAttempts'] as int? ?? 0,
      canViewCorrection: json['canViewCorrection'] as bool? ?? false,
      themeCompleted: json['themeCompleted'] as bool? ?? false,
      themeName: json['themeName'] as String? ?? '',
    );
  }
}
