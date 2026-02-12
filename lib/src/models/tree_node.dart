import 'package:uuid/uuid.dart';

/// ノードタイプ
enum NodeType {
  root,       // ルートノード（シューマイアイコン表示）
  category,   // カテゴリー（既存データ・読み取り専用）
  hobby,      // 趣味（既存データ・読み取り専用）
  custom,     // カスタムノード（編集可能）
}

/// 樹形図のノード
class TreeNode {
  final String id;              // UUID
  final String? parentId;       // 親ノードID（null = ルート）
  final String title;           // ノードタイトル
  final String? description;    // 説明文（オプション）
  final NodeType type;          // ノードタイプ
  final DateTime createdAt;     // 作成日時
  final DateTime? updatedAt;    // 更新日時
  final int order;              // 兄弟ノード間の順序
  final bool isCompleted;       // 完了状態（チェックボックス用）

  // 既存データとの紐付け（type = category/hobby の場合のみ）
  final String? categoryId;     // カテゴリーID
  final String? hobbyId;        // 趣味ID

  TreeNode({
    required this.id,
    this.parentId,
    required this.title,
    this.description,
    required this.type,
    required this.createdAt,
    this.updatedAt,
    this.order = 0,
    this.isCompleted = false,
    this.categoryId,
    this.hobbyId,
  });

  /// ルートノードを作成
  factory TreeNode.createRoot() {
    return TreeNode(
      id: 'root',
      parentId: null,
      title: 'シューマイ',
      type: NodeType.root,
      createdAt: DateTime.now(),
      order: 0,
    );
  }

  /// カテゴリーノードを作成
  factory TreeNode.fromCategory({
    required String categoryId,
    required String categoryName,
    required int order,
  }) {
    return TreeNode(
      id: 'category_$categoryId',
      parentId: 'root',
      title: categoryName,
      type: NodeType.category,
      categoryId: categoryId,
      createdAt: DateTime.now(),
      order: order,
    );
  }

  /// 趣味ノードを作成
  factory TreeNode.fromHobby({
    required String hobbyId,
    required String hobbyTitle,
    required String categoryId,
    required int order,
  }) {
    return TreeNode(
      id: 'hobby_$hobbyId',
      parentId: 'category_$categoryId',
      title: hobbyTitle,
      type: NodeType.hobby,
      categoryId: categoryId,
      hobbyId: hobbyId,
      createdAt: DateTime.now(),
      order: order,
    );
  }

  /// カスタムノードを作成
  factory TreeNode.createCustom({
    required String parentId,
    required String title,
    String? description,
    required int order,
  }) {
    return TreeNode(
      id: const Uuid().v4(),
      parentId: parentId,
      title: title,
      description: description,
      type: NodeType.custom,
      createdAt: DateTime.now(),
      order: order,
    );
  }

  /// JSON変換
  Map<String, dynamic> toJson() => {
    'id': id,
    'parentId': parentId,
    'title': title,
    'description': description,
    'type': type.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'order': order,
    'isCompleted': isCompleted,
    'categoryId': categoryId,
    'hobbyId': hobbyId,
  };

  /// JSONから生成
  factory TreeNode.fromJson(Map<String, dynamic> json) {
    return TreeNode(
      id: json['id'] as String,
      parentId: json['parentId'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      type: NodeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NodeType.custom,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      order: json['order'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      categoryId: json['categoryId'] as String?,
      hobbyId: json['hobbyId'] as String?,
    );
  }

  /// コピー
  TreeNode copyWith({
    String? id,
    String? parentId,
    String? title,
    String? description,
    NodeType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? order,
    bool? isCompleted,
    String? categoryId,
    String? hobbyId,
  }) {
    return TreeNode(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      order: order ?? this.order,
      isCompleted: isCompleted ?? this.isCompleted,
      categoryId: categoryId ?? this.categoryId,
      hobbyId: hobbyId ?? this.hobbyId,
    );
  }

  /// 読み取り専用かどうか
  bool get isReadOnly => type == NodeType.root || type == NodeType.category || type == NodeType.hobby;

  /// 編集可能かどうか
  bool get isEditable => type == NodeType.custom;
}
