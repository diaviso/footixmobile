class UserStatsModel {
  final int totalStars;
  final int uniqueQuizzesCompleted;
  final int quizzesPassed;
  final int totalQuizzes;
  final double averageScore;
  final int totalAttempts;

  const UserStatsModel({
    required this.totalStars,
    required this.uniqueQuizzesCompleted,
    required this.quizzesPassed,
    required this.totalQuizzes,
    required this.averageScore,
    required this.totalAttempts,
  });

  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    return UserStatsModel(
      totalStars: json['totalStars'] as int? ?? 0,
      uniqueQuizzesCompleted: json['uniqueQuizzesCompleted'] as int? ?? 0,
      quizzesPassed: json['quizzesPassed'] as int? ?? 0,
      totalQuizzes: json['totalQuizzes'] as int? ?? 0,
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0.0,
      totalAttempts: json['totalAttempts'] as int? ?? 0,
    );
  }
}
