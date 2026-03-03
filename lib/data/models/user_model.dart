class UserModel {
  static String _parseDateTime(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is DateTime) return value.toIso8601String();
    return value.toString();
  }

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? country;
  final String? city;
  final String? avatar;
  final String role;
  final bool isEmailVerified;
  final int stars;
  final bool showInLeaderboard;
  final bool emailNotifications;
  final bool pushNotifications;
  final bool marketingEmails;
  final String createdAt;
  final String updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.country,
    this.city,
    this.avatar,
    required this.role,
    required this.isEmailVerified,
    required this.stars,
    required this.showInLeaderboard,
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.marketingEmails = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAdmin => role == 'ADMIN';

  String get fullName => '$firstName $lastName';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      country: json['country'] as String?,
      city: json['city'] as String?,
      avatar: json['avatar'] as String?,
      role: json['role'] as String? ?? 'USER',
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      stars: json['stars'] as int? ?? 0,
      showInLeaderboard: json['showInLeaderboard'] as bool? ?? true,
      emailNotifications: json['emailNotifications'] as bool? ?? true,
      pushNotifications: json['pushNotifications'] as bool? ?? true,
      marketingEmails: json['marketingEmails'] as bool? ?? false,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'country': country,
      'city': city,
      'avatar': avatar,
      'role': role,
      'isEmailVerified': isEmailVerified,
      'stars': stars,
      'showInLeaderboard': showInLeaderboard,
      'emailNotifications': emailNotifications,
      'pushNotifications': pushNotifications,
      'marketingEmails': marketingEmails,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? country,
    String? city,
    String? avatar,
    int? stars,
    bool? showInLeaderboard,
    bool? emailNotifications,
    bool? pushNotifications,
    bool? marketingEmails,
  }) {
    return UserModel(
      id: id,
      email: email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      country: country ?? this.country,
      city: city ?? this.city,
      avatar: avatar ?? this.avatar,
      role: role,
      isEmailVerified: isEmailVerified,
      stars: stars ?? this.stars,
      showInLeaderboard: showInLeaderboard ?? this.showInLeaderboard,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      marketingEmails: marketingEmails ?? this.marketingEmails,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
