import 'package:uuid/uuid.dart';

class Hobby {
  final String id;
  final String title;
  final String? memo;
  final String imageFileName;
  final String categoryId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Hobby({
    required this.id,
    required this.title,
    this.memo,
    required this.imageFileName,
    required this.categoryId,
    required this.createdAt,
    required this.updatedAt,
  });

  String getImagePath(String basePath) {
    return '$basePath/images/$imageFileName';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'memo': memo,
    'imageFileName': imageFileName,
    'categoryId': categoryId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Hobby.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return Hobby(
      id: json['id'] as String? ?? const Uuid().v4(),
      title: json['title'] as String,
      memo: json['memo'] as String?,
      imageFileName: json['imageFileName'] as String,
      categoryId: json['categoryId'] as String? ?? 'default_all', // 既存データの互換性
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : now,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : now,
    );
  }

  /// 更新されたコピーを作成
  Hobby copyWith({
    String? title,
    String? memo,
    String? imageFileName,
    String? categoryId,
  }) {
    return Hobby(
      id: id,
      title: title ?? this.title,
      memo: memo ?? this.memo,
      imageFileName: imageFileName ?? this.imageFileName,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
