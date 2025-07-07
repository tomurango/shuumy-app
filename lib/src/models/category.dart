import 'package:uuid/uuid.dart';

class Category {
  final String id;
  final String name;
  final int order;
  final String? backgroundImagePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.id,
    required this.name,
    required this.order,
    this.backgroundImagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  /// デフォルト「すべて」カテゴリーを作成
  factory Category.defaultCategory() {
    final now = DateTime.now();
    return Category(
      id: 'default_all',
      name: 'すべて',
      order: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 新しいカテゴリーを作成
  factory Category.create({
    required String name,
    required int order,
    String? backgroundImagePath,
  }) {
    final now = DateTime.now();
    return Category(
      id: const Uuid().v4(),
      name: name,
      order: order,
      backgroundImagePath: backgroundImagePath,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// JSONからカテゴリーを作成
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      order: json['order'] as int,
      backgroundImagePath: json['backgroundImagePath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// カテゴリーをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'order': order,
      'backgroundImagePath': backgroundImagePath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// カテゴリーを更新したコピーを作成
  Category copyWith({
    String? name,
    int? order,
    String? backgroundImagePath,
    bool clearBackgroundImage = false,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      order: order ?? this.order,
      backgroundImagePath: clearBackgroundImage 
          ? null 
          : (backgroundImagePath ?? this.backgroundImagePath),
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Category{id: $id, name: $name, order: $order}';
  }
}