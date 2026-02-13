import 'package:uuid/uuid.dart';

/// 趣味の子ノード（階層構造用）
class HobbyNode {
  final String id;
  final String title;
  final String? description;
  final int order;
  final List<HobbyNode> children;
  final DateTime createdAt;
  final DateTime? updatedAt;

  HobbyNode({
    required this.id,
    required this.title,
    this.description,
    this.order = 0,
    this.children = const [],
    required this.createdAt,
    this.updatedAt,
  });

  /// 新しいノードを作成
  factory HobbyNode.create({
    required String title,
    String? description,
    int order = 0,
  }) {
    return HobbyNode(
      id: const Uuid().v4(),
      title: title,
      description: description,
      order: order,
      children: [],
      createdAt: DateTime.now(),
    );
  }

  /// JSONから生成
  factory HobbyNode.fromJson(Map<String, dynamic> json) {
    return HobbyNode(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      order: json['order'] as int? ?? 0,
      children: (json['children'] as List<dynamic>?)
              ?.map((e) => HobbyNode.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'order': order,
      'children': children.map((c) => c.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// コピーを作成
  HobbyNode copyWith({
    String? id,
    String? title,
    String? description,
    int? order,
    List<HobbyNode>? children,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HobbyNode(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      order: order ?? this.order,
      children: children ?? this.children,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HobbyNode && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
