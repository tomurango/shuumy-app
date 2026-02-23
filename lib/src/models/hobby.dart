import 'package:uuid/uuid.dart';
import 'hobby_node.dart';

class Hobby {
  final String id;
  final String title;
  final String? memo;
  final String imageFileName;
  final String? headerImageFileName; // ヘッダーバナー画像
  final String categoryId;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<HobbyNode> children; // 階層構造用の子ノード
  final bool isHabitTracked; // デイリー習慣トラッカー

  Hobby({
    required this.id,
    required this.title,
    this.memo,
    required this.imageFileName,
    this.headerImageFileName,
    required this.categoryId,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
    this.children = const [],
    this.isHabitTracked = false,
  });

  String getImagePath(String basePath) {
    return '$basePath/images/$imageFileName';
  }

  String? getHeaderImagePath(String basePath) {
    if (headerImageFileName == null) return null;
    return '$basePath/headers/$headerImageFileName';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'memo': memo,
    'imageFileName': imageFileName,
    'headerImageFileName': headerImageFileName,
    'categoryId': categoryId,
    'order': order,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'children': children.map((c) => c.toJson()).toList(),
    'isHabitTracked': isHabitTracked,
  };

  factory Hobby.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return Hobby(
      id: json['id'] as String? ?? const Uuid().v4(),
      title: json['title'] as String,
      memo: json['memo'] as String?,
      imageFileName: json['imageFileName'] as String,
      headerImageFileName: json['headerImageFileName'] as String?,
      categoryId: json['categoryId'] as String? ?? 'default_all', // 既存データの互換性
      order: json['order'] as int? ?? 0, // 既存データの互換性
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : now,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : now,
      children: (json['children'] as List<dynamic>?)
              ?.map((e) => HobbyNode.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isHabitTracked: json['isHabitTracked'] as bool? ?? false,
    );
  }

  /// 更新されたコピーを作成
  Hobby copyWith({
    String? title,
    String? memo,
    String? imageFileName,
    String? headerImageFileName,
    bool clearHeaderImage = false,
    String? categoryId,
    int? order,
    List<HobbyNode>? children,
    bool? isHabitTracked,
  }) {
    return Hobby(
      id: id,
      title: title ?? this.title,
      memo: memo ?? this.memo,
      imageFileName: imageFileName ?? this.imageFileName,
      headerImageFileName:
          clearHeaderImage ? null : (headerImageFileName ?? this.headerImageFileName),
      categoryId: categoryId ?? this.categoryId,
      order: order ?? this.order,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      children: children ?? this.children,
      isHabitTracked: isHabitTracked ?? this.isHabitTracked,
    );
  }

  /// 子ノードを追加
  Hobby addChild(HobbyNode node) {
    return copyWith(children: [...children, node]);
  }

  /// 子ノードを更新（再帰的に検索して更新）
  Hobby updateChildNode(String nodeId, HobbyNode updatedNode) {
    return copyWith(
      children: _updateNodeInList(children, nodeId, updatedNode),
    );
  }

  /// 子ノードを削除（再帰的に検索して削除）
  Hobby removeChildNode(String nodeId) {
    return copyWith(
      children: _removeNodeFromList(children, nodeId),
    );
  }

  /// リスト内のノードを再帰的に更新
  static List<HobbyNode> _updateNodeInList(
    List<HobbyNode> nodes,
    String nodeId,
    HobbyNode updatedNode,
  ) {
    return nodes.map((node) {
      if (node.id == nodeId) {
        return updatedNode;
      }
      if (node.children.isNotEmpty) {
        return node.copyWith(
          children: _updateNodeInList(node.children, nodeId, updatedNode),
        );
      }
      return node;
    }).toList();
  }

  /// リスト内のノードを再帰的に削除
  static List<HobbyNode> _removeNodeFromList(
    List<HobbyNode> nodes,
    String nodeId,
  ) {
    return nodes
        .where((node) => node.id != nodeId)
        .map((node) {
          if (node.children.isNotEmpty) {
            return node.copyWith(
              children: _removeNodeFromList(node.children, nodeId),
            );
          }
          return node;
        })
        .toList();
  }

  /// 特定のノードを検索（再帰的）
  HobbyNode? findNode(String nodeId) {
    return _findNodeInList(children, nodeId);
  }

  static HobbyNode? _findNodeInList(List<HobbyNode> nodes, String nodeId) {
    for (final node in nodes) {
      if (node.id == nodeId) return node;
      if (node.children.isNotEmpty) {
        final found = _findNodeInList(node.children, nodeId);
        if (found != null) return found;
      }
    }
    return null;
  }

  /// すべての子孫ノードIDを取得
  List<String> getAllDescendantNodeIds() {
    final ids = <String>[];
    _collectNodeIds(children, ids);
    return ids;
  }

  static void _collectNodeIds(List<HobbyNode> nodes, List<String> ids) {
    for (final node in nodes) {
      ids.add(node.id);
      if (node.children.isNotEmpty) {
        _collectNodeIds(node.children, ids);
      }
    }
  }
}
