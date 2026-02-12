import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/tree_node.dart';
import '../services/category_service.dart';
import '../services/hobby_json_service.dart';

class TreeNodeService {
  static const _fileName = 'tree_nodes.json';

  /// ローカルファイルを取得
  static Future<File> _getLocalFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// すべてのノードを読み込み
  static Future<List<TreeNode>> loadAllNodes() async {
    try {
      final file = await _getLocalFile();
      if (!(await file.exists())) {
        // ファイルが存在しない場合は初期化
        return await _initializeWithExistingData();
      }

      final contents = await file.readAsString();
      final List<dynamic> jsonData = jsonDecode(contents);
      return jsonData.map((e) => TreeNode.fromJson(e)).toList();
    } catch (e) {
      // エラーの場合は初期化
      return await _initializeWithExistingData();
    }
  }

  /// 既存データで初期化
  static Future<List<TreeNode>> _initializeWithExistingData() async {
    final nodes = <TreeNode>[];

    // ルートノード作成
    nodes.add(TreeNode.createRoot());

    // カテゴリーと趣味を同期
    await _syncCategoriesAndHobbies(nodes);

    // 保存
    await saveNodes(nodes);

    return nodes;
  }

  /// カテゴリーと趣味を同期
  static Future<void> _syncCategoriesAndHobbies(List<TreeNode> nodes) async {
    // 既存のカテゴリー・趣味ノードを削除
    nodes.removeWhere((node) => node.type == NodeType.category || node.type == NodeType.hobby);

    // カテゴリーを読み込み
    final categories = await CategoryService.getAllCategories();

    // 趣味を読み込み
    final hobbies = await HobbyJsonService.loadHobbies();

    // カテゴリーノードを追加
    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      nodes.add(TreeNode.fromCategory(
        categoryId: category.id,
        categoryName: category.name,
        order: i,
      ));

      // このカテゴリーの趣味を追加
      final categoryHobbies = hobbies.where((h) => h.categoryId == category.id).toList();
      categoryHobbies.sort((a, b) => a.order.compareTo(b.order));

      for (int j = 0; j < categoryHobbies.length; j++) {
        final hobby = categoryHobbies[j];
        nodes.add(TreeNode.fromHobby(
          hobbyId: hobby.id,
          hobbyTitle: hobby.title,
          categoryId: category.id,
          order: j,
        ));
      }
    }
  }

  /// すべてのノードを保存
  static Future<void> saveNodes(List<TreeNode> nodes) async {
    final file = await _getLocalFile();
    final jsonData = nodes.map((n) => n.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonData));
  }

  /// ノードを追加
  static Future<void> addNode(TreeNode node) async {
    final nodes = await loadAllNodes();
    nodes.add(node);
    await saveNodes(nodes);
  }

  /// ノードを更新
  static Future<void> updateNode(TreeNode updatedNode) async {
    final nodes = await loadAllNodes();
    final index = nodes.indexWhere((n) => n.id == updatedNode.id);
    if (index != -1) {
      nodes[index] = updatedNode.copyWith(updatedAt: DateTime.now());
      await saveNodes(nodes);
    }
  }

  /// ノードを削除（子ノードも再帰的に削除）
  static Future<void> deleteNode(String nodeId) async {
    final nodes = await loadAllNodes();

    // 削除対象のIDリストを収集
    final idsToDelete = <String>{nodeId};
    _collectChildIds(nodeId, nodes, idsToDelete);

    // 削除
    nodes.removeWhere((n) => idsToDelete.contains(n.id));
    await saveNodes(nodes);
  }

  /// 子ノードのIDを再帰的に収集
  static void _collectChildIds(String parentId, List<TreeNode> nodes, Set<String> idsToDelete) {
    final children = nodes.where((n) => n.parentId == parentId);
    for (final child in children) {
      idsToDelete.add(child.id);
      _collectChildIds(child.id, nodes, idsToDelete);
    }
  }

  /// 既存データと同期
  static Future<void> syncWithExistingData() async {
    final nodes = await loadAllNodes();
    await _syncCategoriesAndHobbies(nodes);
    await saveNodes(nodes);
  }

  /// 子ノードを取得
  static List<TreeNode> getChildren(String parentId, List<TreeNode> nodes) {
    return nodes
        .where((n) => n.parentId == parentId)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  /// ツリー構造を構築（デバッグ用）
  static Map<String, List<TreeNode>> buildTreeMap(List<TreeNode> nodes) {
    final treeMap = <String, List<TreeNode>>{};

    for (final node in nodes) {
      final parentId = node.parentId ?? 'null';
      if (!treeMap.containsKey(parentId)) {
        treeMap[parentId] = [];
      }
      treeMap[parentId]!.add(node);
    }

    // 各リストをorder順にソート
    for (final key in treeMap.keys) {
      treeMap[key]!.sort((a, b) => a.order.compareTo(b.order));
    }

    return treeMap;
  }

  /// ノードのパスを取得（ルートから指定ノードまで）
  static List<TreeNode> getNodePath(String nodeId, List<TreeNode> nodes) {
    final path = <TreeNode>[];
    TreeNode? current = nodes.firstWhere((n) => n.id == nodeId);

    while (current != null) {
      path.insert(0, current);
      if (current.parentId == null) break;
      current = nodes.cast<TreeNode?>().firstWhere(
        (n) => n?.id == current!.parentId,
        orElse: () => null,
      );
    }

    return path;
  }

  /// 次のorder値を取得
  static int getNextOrder(String parentId, List<TreeNode> nodes) {
    final siblings = getChildren(parentId, nodes);
    if (siblings.isEmpty) return 0;
    return siblings.map((n) => n.order).reduce((a, b) => a > b ? a : b) + 1;
  }

  /// ノードの深さを計算（ルート = 0）
  static int getNodeDepth(String nodeId, List<TreeNode> nodes) {
    int depth = 0;
    String? currentId = nodeId;

    while (currentId != null) {
      final node = nodes.where((n) => n.id == currentId).firstOrNull;
      if (node == null || node.parentId == null) break;
      currentId = node.parentId;
      depth++;
    }

    return depth;
  }

  /// 最大階層数
  static const int maxDepth = 10;

  /// 特定の趣味の下にあるすべてのカスタムノードIDを取得（再帰的）
  static Future<List<String>> getAllDescendantNodeIds(String hobbyId) async {
    final nodes = await loadAllNodes();
    final hobbyNodeId = 'hobby_$hobbyId';
    final descendantIds = <String>[];

    _collectDescendantIds(hobbyNodeId, nodes, descendantIds);

    return descendantIds;
  }

  /// 子孫ノードIDを再帰的に収集
  static void _collectDescendantIds(String parentId, List<TreeNode> nodes, List<String> ids) {
    final children = nodes.where((n) => n.parentId == parentId && n.type == NodeType.custom);
    for (final child in children) {
      ids.add(child.id);
      _collectDescendantIds(child.id, nodes, ids);
    }
  }

  /// ルートノードを取得
  static TreeNode? getRootNode(List<TreeNode> nodes) {
    try {
      return nodes.firstWhere((n) => n.type == NodeType.root);
    } catch (e) {
      return null;
    }
  }
}
