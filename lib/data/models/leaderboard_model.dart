class LeaderboardEntryModel {
  final int rank;
  final String userId;
  final String firstName;
  final String lastName;
  final String? avatar;
  final int stars;

  const LeaderboardEntryModel({
    required this.rank,
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.avatar,
    required this.stars,
  });

  String get fullName => '$firstName $lastName';

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntryModel(
      rank: json['rank'] as int? ?? 0,
      userId: json['userId'] as String? ?? json['id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      avatar: json['avatar'] as String?,
      stars: json['stars'] as int? ?? 0,
    );
  }
}

class UserPositionModel {
  final int rank;
  final int stars;
  final int totalUsers;

  const UserPositionModel({
    required this.rank,
    required this.stars,
    required this.totalUsers,
  });

  factory UserPositionModel.fromJson(Map<String, dynamic> json) {
    return UserPositionModel(
      rank: json['rank'] as int? ?? 0,
      stars: json['stars'] as int? ?? 0,
      totalUsers: json['totalUsers'] as int? ?? 0,
    );
  }
}
