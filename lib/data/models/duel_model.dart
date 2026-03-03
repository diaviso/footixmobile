class DuelParticipant {
  final String id;
  final String firstName;
  final String lastName;
  final String? avatar;
  final int? rank;
  final int starsWon;
  final int correctCount;
  final int score;
  final String? finishedAt;

  const DuelParticipant({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.avatar,
    this.rank,
    this.starsWon = 0,
    this.correctCount = 0,
    this.score = 0,
    this.finishedAt,
  });

  factory DuelParticipant.fromJson(Map<String, dynamic> json) {
    return DuelParticipant(
      id: json['id'] as String,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      avatar: json['avatar'] as String?,
      rank: json['rank'] as int?,
      starsWon: json['starsWon'] as int? ?? 0,
      correctCount: json['correctCount'] as int? ?? 0,
      score: json['score'] as int? ?? 0,
      finishedAt: json['finishedAt'] as String?,
    );
  }
}

class DuelModel {
  final String id;
  final String code;
  final String creatorId;
  final int maxParticipants;
  final String difficulty;
  final int starsCost;
  final String status;
  final String? startedAt;
  final String? finishedAt;
  final String expiresAt;
  final bool isCreator;
  final List<DuelParticipant> participants;

  const DuelModel({
    required this.id,
    required this.code,
    required this.creatorId,
    required this.maxParticipants,
    required this.difficulty,
    required this.starsCost,
    required this.status,
    this.startedAt,
    this.finishedAt,
    required this.expiresAt,
    required this.isCreator,
    required this.participants,
  });

  factory DuelModel.fromJson(Map<String, dynamic> json) {
    return DuelModel(
      id: json['id'] as String,
      code: json['code'] as String,
      creatorId: json['creatorId'] as String? ?? '',
      maxParticipants: json['maxParticipants'] as int,
      difficulty: json['difficulty'] as String,
      starsCost: json['starsCost'] as int,
      status: json['status'] as String,
      startedAt: json['startedAt'] as String?,
      finishedAt: json['finishedAt'] as String?,
      expiresAt: json['expiresAt'] as String? ?? '',
      isCreator: json['isCreator'] as bool? ?? false,
      participants: (json['participants'] as List<dynamic>?)
              ?.map((e) => DuelParticipant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class DuelListItem {
  final String id;
  final String code;
  final String difficulty;
  final int starsCost;
  final String status;
  final int maxParticipants;
  final int participantCount;
  final bool isCreator;
  final int? myRank;
  final int myStarsWon;
  final int myCorrectCount;
  final String createdAt;
  final String? startedAt;
  final String? finishedAt;
  final List<DuelParticipant> participants;

  const DuelListItem({
    required this.id,
    required this.code,
    required this.difficulty,
    required this.starsCost,
    required this.status,
    required this.maxParticipants,
    required this.participantCount,
    required this.isCreator,
    this.myRank,
    this.myStarsWon = 0,
    this.myCorrectCount = 0,
    required this.createdAt,
    this.startedAt,
    this.finishedAt,
    required this.participants,
  });

  factory DuelListItem.fromJson(Map<String, dynamic> json) {
    return DuelListItem(
      id: json['id'] as String,
      code: json['code'] as String,
      difficulty: json['difficulty'] as String,
      starsCost: json['starsCost'] as int,
      status: json['status'] as String,
      maxParticipants: json['maxParticipants'] as int,
      participantCount: json['participantCount'] as int? ?? 0,
      isCreator: json['isCreator'] as bool? ?? false,
      myRank: json['myRank'] as int?,
      myStarsWon: json['myStarsWon'] as int? ?? 0,
      myCorrectCount: json['myCorrectCount'] as int? ?? 0,
      createdAt: json['createdAt'] as String,
      startedAt: json['startedAt'] as String?,
      finishedAt: json['finishedAt'] as String?,
      participants: (json['participants'] as List<dynamic>?)
              ?.map((e) => DuelParticipant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class DuelQuestion {
  final String id;
  final String content;
  final String type;
  final List<DuelOption> options;

  const DuelQuestion({
    required this.id,
    required this.content,
    required this.type,
    required this.options,
  });

  factory DuelQuestion.fromJson(Map<String, dynamic> json) {
    return DuelQuestion(
      id: json['id'] as String,
      content: json['content'] as String,
      type: json['type'] as String? ?? 'QCU',
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => DuelOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class DuelOption {
  final String id;
  final String content;
  final bool? isCorrect;
  final String? explanation;

  const DuelOption({
    required this.id,
    required this.content,
    this.isCorrect,
    this.explanation,
  });

  factory DuelOption.fromJson(Map<String, dynamic> json) {
    return DuelOption(
      id: json['id'] as String,
      content: json['content'] as String,
      isCorrect: json['isCorrect'] as bool?,
      explanation: json['explanation'] as String?,
    );
  }
}

class DuelQuestionsResponse {
  final List<DuelQuestion> questions;
  final int timeLimit;
  final String startedAt;

  const DuelQuestionsResponse({
    required this.questions,
    required this.timeLimit,
    required this.startedAt,
  });

  factory DuelQuestionsResponse.fromJson(Map<String, dynamic> json) {
    return DuelQuestionsResponse(
      questions: (json['questions'] as List<dynamic>)
          .map((e) => DuelQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      timeLimit: json['timeLimit'] as int,
      startedAt: json['startedAt'] as String,
    );
  }
}
