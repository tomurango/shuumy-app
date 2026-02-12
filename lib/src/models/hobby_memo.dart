import 'package:uuid/uuid.dart';

class HobbyMemo {
  final String id;
  final String hobbyId;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? imageFileName;
  final bool isPinned;
  final String? nodeId; // 樹形図ノードID（カスタムノード用）

  HobbyMemo({
    required this.id,
    required this.hobbyId,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.imageFileName,
    this.isPinned = false,
    this.nodeId,
  });

  String? getImagePath(String basePath) {
    if (imageFileName == null) return null;
    return '$basePath/images/$imageFileName';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'hobbyId': hobbyId,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'imageFileName': imageFileName,
    'isPinned': isPinned,
    'nodeId': nodeId,
  };

  factory HobbyMemo.fromJson(Map<String, dynamic> json) => HobbyMemo(
    id: json['id'] as String? ?? const Uuid().v4(),
    hobbyId: json['hobbyId'] as String,
    content: json['content'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : null,
    imageFileName: json['imageFileName'] as String?,
    isPinned: json['isPinned'] as bool? ?? false,
    nodeId: json['nodeId'] as String?,
  );

  HobbyMemo copyWith({
    String? id,
    String? hobbyId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? imageFileName,
    bool? isPinned,
    String? nodeId,
  }) {
    return HobbyMemo(
      id: id ?? this.id,
      hobbyId: hobbyId ?? this.hobbyId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageFileName: imageFileName ?? this.imageFileName,
      isPinned: isPinned ?? this.isPinned,
      nodeId: nodeId ?? this.nodeId,
    );
  }
}