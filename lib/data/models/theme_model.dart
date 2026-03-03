class ThemeModel {
  final String id;
  final String title;
  final String description;
  final int position;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final List<dynamic>? quizzes;

  const ThemeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.position,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.quizzes,
  });

  factory ThemeModel.fromJson(Map<String, dynamic> json) {
    return ThemeModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      position: json['position'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      quizzes: json['quizzes'] as List<dynamic>?,
    );
  }
}
