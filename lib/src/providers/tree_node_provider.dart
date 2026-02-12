import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tree_node.dart';
import '../services/tree_node_service.dart';

/// ツリーノードリストプロバイダー
final treeNodeListProvider = StateNotifierProvider<TreeNodeListNotifier, List<TreeNode>>((ref) {
  return TreeNodeListNotifier();
});

class TreeNodeListNotifier extends StateNotifier<List<TreeNode>> {
  TreeNodeListNotifier() : super([]) {
    _loadNodes();
  }

  /// ノードを読み込み
  Future<void> _loadNodes() async {
    try {
      final nodes = await TreeNodeService.loadAllNodes();
      state = nodes;
    } catch (e) {
      // エラーの場合は空リスト
      state = [];
    }
  }

  /// ノードを追加
  Future<void> addNode(TreeNode node) async {
    try {
      await TreeNodeService.addNode(node);
      await _loadNodes();
    } catch (e) {
      rethrow;
    }
  }

  /// ノードを更新
  Future<void> updateNode(TreeNode updatedNode) async {
    try {
      await TreeNodeService.updateNode(updatedNode);
      await _loadNodes();
    } catch (e) {
      rethrow;
    }
  }

  /// ノードを削除
  Future<void> deleteNode(String nodeId) async {
    try {
      await TreeNodeService.deleteNode(nodeId);
      await _loadNodes();
    } catch (e) {
      rethrow;
    }
  }

  /// 既存データと同期
  Future<void> syncWithExistingData() async {
    try {
      await TreeNodeService.syncWithExistingData();
      await _loadNodes();
    } catch (e) {
      rethrow;
    }
  }

  /// 手動でリロード
  Future<void> reload() async {
    await _loadNodes();
  }

  /// 子ノードを取得
  List<TreeNode> getChildren(String parentId) {
    return TreeNodeService.getChildren(parentId, state);
  }

  /// ノードのパスを取得
  List<TreeNode> getNodePath(String nodeId) {
    return TreeNodeService.getNodePath(nodeId, state);
  }

  /// ルートノードを取得
  TreeNode? getRootNode() {
    return TreeNodeService.getRootNode(state);
  }
}

/// 展開状態プロバイダー（展開されているノードのIDセット）
final expandedNodesProvider = StateProvider<Set<String>>((ref) {
  return <String>{}; // デフォルトは全て閉じている
});

/// 選択中のノードプロバイダー
final selectedNodeProvider = StateProvider<String?>((ref) {
  return null;
});
