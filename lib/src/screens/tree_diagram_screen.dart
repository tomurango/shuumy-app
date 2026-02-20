import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../models/hobby.dart';
import '../models/hobby_node.dart';
import '../models/hobby_memo.dart';
import '../models/category.dart';
import '../providers/hobby_list_provider.dart';
import '../providers/category_provider.dart';
import '../services/memo_service.dart';
import '../shared/widgets/image_viewer.dart';
import 'add_memo_screen.dart';

/// 最大階層数
const int maxNodeDepth = 10;

/// 展開状態プロバイダー
final expandedNodesProvider = StateProvider<Set<String>>((ref) => <String>{});

/// 選択中のノード情報
class SelectedNodeInfo {
  final String nodeId;
  final String nodeType; // 'root' | 'category' | 'hobby' | 'custom'
  final String? hobbyId; // 趣味IDまたはカスタムノードが属する趣味ID
  final String? parentNodeId; // カスタムノードの親ノードID
  final int depth; // 現在の階層

  const SelectedNodeInfo({
    required this.nodeId,
    required this.nodeType,
    this.hobbyId,
    this.parentNodeId,
    required this.depth,
  });

  /// 子ノードを追加可能か
  bool get canAddChild =>
      (nodeType == 'hobby' || nodeType == 'custom') && depth < maxNodeDepth;
}

/// 選択中のノードプロバイダー
final selectedNodeProvider = StateProvider<SelectedNodeInfo?>((ref) => null);

/// 樹形図画面
class TreeDiagramScreen extends ConsumerStatefulWidget {
  final String? initialCategoryId;

  const TreeDiagramScreen({
    super.key,
    this.initialCategoryId,
  });

  @override
  ConsumerState<TreeDiagramScreen> createState() => _TreeDiagramScreenState();
}

class _TreeDiagramScreenState extends ConsumerState<TreeDiagramScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.initialCategoryId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 初期カテゴリーを展開
        final expandedNodes = ref.read(expandedNodesProvider.notifier);
        expandedNodes.state = {...expandedNodes.state, 'root', 'category_${widget.initialCategoryId}'};
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryListProvider);
    final hobbies = ref.watch(hobbyListProvider);
    final selectedNode = ref.watch(selectedNodeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('樹形図'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        actions: [
          // ノード追加ボタン
          IconButton(
            onPressed: selectedNode != null && selectedNode.canAddChild
                ? () => _showAddNodeDialog(
                      selectedNode.hobbyId!,
                      selectedNode.nodeType == 'custom' ? selectedNode.nodeId : null,
                    )
                : null,
            icon: Icon(
              Icons.add_circle_outline,
              color: selectedNode != null && selectedNode.canAddChild
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade400,
            ),
            tooltip: selectedNode != null && selectedNode.canAddChild
                ? 'ノードを追加'
                : '趣味またはノードを選択してください',
          ),
        ],
      ),
      body: categories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                // ルートノード
                _buildRootNode(categories, hobbies),
              ],
            ),
    );
  }

  /// ルートノードを構築
  Widget _buildRootNode(List<Category> categories, List<Hobby> hobbies) {
    final expandedNodes = ref.watch(expandedNodesProvider);
    final isExpanded = expandedNodes.contains('root');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNodeTile(
          id: 'root',
          title: 'シューマイ',
          icon: _buildRootIcon(),
          depth: 0,
          isExpanded: isExpanded,
          canExpand: true,
          onTap: () => _toggleExpand('root'),
          nodeType: 'root',
        ),
        if (isExpanded)
          ...categories.map((category) => _buildCategoryNode(category, hobbies, 1)),
      ],
    );
  }

  /// カテゴリーノードを構築
  Widget _buildCategoryNode(Category category, List<Hobby> hobbies, int depth) {
    final expandedNodes = ref.watch(expandedNodesProvider);
    final nodeId = 'category_${category.id}';
    final isExpanded = expandedNodes.contains(nodeId);
    final categoryHobbies = hobbies.where((h) => h.categoryId == category.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNodeTile(
          id: nodeId,
          title: category.name,
          icon: _buildCategoryIcon(),
          depth: depth,
          isExpanded: isExpanded,
          canExpand: categoryHobbies.isNotEmpty,
          onTap: () => _toggleExpand(nodeId),
          nodeType: 'category',
        ),
        if (isExpanded)
          ...categoryHobbies.map((hobby) => _buildHobbyNode(hobby, depth + 1)),
      ],
    );
  }

  /// 趣味ノードを構築
  Widget _buildHobbyNode(Hobby hobby, int depth) {
    final expandedNodes = ref.watch(expandedNodesProvider);
    final nodeId = 'hobby_${hobby.id}';
    final isExpanded = expandedNodes.contains(nodeId);
    final hasChildren = hobby.children.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNodeTile(
          id: nodeId,
          title: hobby.title,
          icon: _buildHobbyIcon(),
          depth: depth,
          isExpanded: isExpanded,
          canExpand: hasChildren, // 子がある場合のみ展開可能
          onTap: () => _toggleExpand(nodeId),
          nodeType: 'hobby',
          hobbyId: hobby.id,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // メモボタン
              IconButton(
                onPressed: () => _showMemoSheet(hobby.id, hobby.title, null),
                icon: Icon(
                  Icons.note_alt_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                tooltip: 'メモ',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ),
        if (isExpanded)
          // 子ノード
          ...hobby.children.map((node) => _buildCustomNode(hobby.id, node, depth + 1, null)),
      ],
    );
  }

  /// カスタムノードを構築
  Widget _buildCustomNode(String hobbyId, HobbyNode node, int depth, String? parentNodeId) {
    final expandedNodes = ref.watch(expandedNodesProvider);
    final isExpanded = expandedNodes.contains(node.id);
    final hasChildren = node.children.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNodeTile(
          id: node.id,
          title: node.title,
          subtitle: node.description,
          icon: _buildCustomNodeIcon(),
          depth: depth,
          isExpanded: isExpanded,
          canExpand: hasChildren, // 子がある場合のみ展開可能
          onTap: () => _toggleExpand(node.id),
          nodeType: 'custom',
          hobbyId: hobbyId,
          parentNodeId: parentNodeId,
          onLongPress: () => _showNodeOptions(hobbyId, node),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // メモボタン
              IconButton(
                onPressed: () => _showMemoSheet(hobbyId, node.title, node.id),
                icon: Icon(
                  Icons.note_alt_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                tooltip: 'メモ',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ),
        if (isExpanded)
          // 子ノード（このノードを親として渡す）
          ...node.children.map((child) => _buildCustomNode(hobbyId, child, depth + 1, node.id)),
      ],
    );
  }

  /// ノードタイルを構築
  Widget _buildNodeTile({
    required String id,
    required String title,
    String? subtitle,
    required Widget icon,
    required int depth,
    required bool isExpanded,
    required bool canExpand,
    required VoidCallback onTap,
    required String nodeType,
    String? hobbyId,
    String? parentNodeId,
    VoidCallback? onLongPress,
    Widget? trailing,
  }) {
    final selectedNode = ref.watch(selectedNodeProvider);
    final isSelected = selectedNode?.nodeId == id;

    return Padding(
      padding: EdgeInsets.only(left: depth * 24.0),
      child: InkWell(
        onTap: () {
          ref.read(selectedNodeProvider.notifier).state = SelectedNodeInfo(
            nodeId: id,
            nodeType: nodeType,
            hobbyId: hobbyId,
            parentNodeId: parentNodeId,
            depth: depth,
          );
          if (canExpand) onTap();
        },
        onLongPress: onLongPress,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // 展開アイコン
              if (canExpand)
                Icon(
                  isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                  size: 24,
                  color: Colors.grey.shade600,
                )
              else
                const SizedBox(width: 24),
              const SizedBox(width: 8),
              // ノードアイコン
              icon,
              const SizedBox(width: 12),
              // タイトル
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 16),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          subtitle,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ),
                  ],
                ),
              ),
              // 末尾ウィジェット
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  // ========== アイコン ==========

  Widget _buildRootIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF009977),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          'assets/icons/app_icon.jpeg',
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // 画像読み込みエラー時はアイコンを表示
            return Container(
              width: 40,
              height: 40,
              color: const Color(0xFF009977),
              child: const Icon(
                Icons.account_tree,
                color: Colors.white,
                size: 24,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.folder, color: Colors.blue.shade700),
    );
  }

  Widget _buildHobbyIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.star, color: Colors.green.shade700),
    );
  }

  Widget _buildCustomNodeIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.circle_outlined, color: Colors.orange.shade700),
    );
  }

  // ========== 操作メソッド ==========

  void _toggleExpand(String nodeId) {
    final expandedNodes = ref.read(expandedNodesProvider.notifier);
    final current = expandedNodes.state;
    if (current.contains(nodeId)) {
      expandedNodes.state = current.difference({nodeId});
    } else {
      expandedNodes.state = {...current, nodeId};
    }
  }

  /// ノード追加ダイアログ
  void _showAddNodeDialog(String hobbyId, String? parentNodeId) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ノードを追加'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'タイトル',
                    hintText: '例: 基本練習',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: '説明（任意）',
                    hintText: '詳細な説明を入力',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('タイトルを入力してください')),
                  );
                  return;
                }

                final newNode = HobbyNode.create(
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                );

                try {
                  if (parentNodeId == null) {
                    // 趣味に直接追加
                    await ref.read(hobbyListProvider.notifier).addNodeToHobby(hobbyId, newNode);
                  } else {
                    // 親ノードに追加
                    await ref.read(hobbyListProvider.notifier).addNodeToNode(hobbyId, parentNodeId, newNode);
                  }

                  // 親ノードを展開
                  final expandedNodes = ref.read(expandedNodesProvider.notifier);
                  expandedNodes.state = {
                    ...expandedNodes.state,
                    parentNodeId ?? 'hobby_$hobbyId',
                  };

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ノードを追加しました')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('エラー: $e')),
                    );
                  }
                }
              },
              child: const Text('追加'),
            ),
          ],
        );
      },
    );
  }

  /// ノードオプションを表示
  void _showNodeOptions(String hobbyId, HobbyNode node) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('編集'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditNodeDialog(hobbyId, node);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('削除', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(hobbyId, node);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// ノード編集ダイアログ
  void _showEditNodeDialog(String hobbyId, HobbyNode node) {
    final titleController = TextEditingController(text: node.title);
    final descriptionController = TextEditingController(text: node.description ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ノードを編集'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'タイトル'),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: '説明（任意）'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('タイトルを入力してください')),
                  );
                  return;
                }

                final updatedNode = node.copyWith(
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                );

                try {
                  await ref.read(hobbyListProvider.notifier).updateNode(hobbyId, updatedNode);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ノードを更新しました')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('エラー: $e')),
                    );
                  }
                }
              },
              child: const Text('更新'),
            ),
          ],
        );
      },
    );
  }

  /// 削除確認ダイアログ
  void _showDeleteConfirmation(String hobbyId, HobbyNode node) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ノードを削除'),
          content: Text(
            node.children.isNotEmpty
                ? '「${node.title}」とその子ノードをすべて削除しますか？'
                : '「${node.title}」を削除しますか？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ref.read(hobbyListProvider.notifier).removeNode(hobbyId, node.id);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ノードを削除しました')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('エラー: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );
  }

  /// メモシートを表示
  void _showMemoSheet(String hobbyId, String title, String? nodeId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MemoBottomSheet(
        hobbyId: hobbyId,
        title: title,
        nodeId: nodeId,
        onMemoAdded: () {
          Navigator.pop(context);
          _showMemoSheet(hobbyId, title, nodeId);
        },
      ),
    );
  }
}

/// メモ一覧ボトムシート
class _MemoBottomSheet extends StatefulWidget {
  final String hobbyId;
  final String title;
  final String? nodeId;
  final VoidCallback onMemoAdded;

  const _MemoBottomSheet({
    required this.hobbyId,
    required this.title,
    this.nodeId,
    required this.onMemoAdded,
  });

  @override
  State<_MemoBottomSheet> createState() => _MemoBottomSheetState();
}

class _MemoBottomSheetState extends State<_MemoBottomSheet> {
  List<HobbyMemo> _memos = [];
  bool _isLoading = true;
  String? _basePath;

  @override
  void initState() {
    super.initState();
    _loadMemos();
  }

  Future<void> _loadMemos() async {
    final dir = await getApplicationDocumentsDirectory();
    _basePath = dir.path;

    List<HobbyMemo> memos;
    if (widget.nodeId != null) {
      // カスタムノードのメモ
      memos = await MemoService.loadMemosForNode(widget.nodeId!);
    } else {
      // 趣味のメモ
      memos = await MemoService.loadMemosForHobby(widget.hobbyId);
    }

    if (mounted) {
      setState(() {
        _memos = memos;
        _isLoading = false;
      });
    }
  }

  Future<void> _addMemo() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMemoScreen(
          nodeId: widget.nodeId,
          nodeTitle: widget.title,
          hobbyId: widget.nodeId == null ? widget.hobbyId : null,
        ),
      ),
    );

    if (result == true) {
      widget.onMemoAdded();
    }
  }

  Future<void> _deleteMemo(HobbyMemo memo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メモを削除'),
        content: const Text('このメモを削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await MemoService.deleteMemo(memo.id);
      widget.onMemoAdded();
    }
  }

  Future<void> _togglePin(HobbyMemo memo) async {
    await MemoService.togglePinMemo(memo.id);
    widget.onMemoAdded();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // ハンドル
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // ヘッダー
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${widget.title}のメモ',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: _addMemo,
                      icon: Icon(
                        Icons.add_circle,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                      tooltip: 'メモを追加',
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // メモ一覧
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _memos.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text('メモはまだありません', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: _addMemo,
                                  icon: const Icon(Icons.add),
                                  label: const Text('メモを追加'),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _memos.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final memo = _memos[index];
                              return _buildMemoCard(memo);
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMemoCard(HobbyMemo memo) {
    final hasImage = memo.imageFileName != null && _basePath != null;
    final imageFile = hasImage ? File('$_basePath/images/${memo.imageFileName}') : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (memo.isPinned)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(Icons.push_pin, size: 16, color: Theme.of(context).colorScheme.primary),
                      ),
                    Text(
                      _formatDate(memo.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'pin') {
                          _togglePin(memo);
                        } else if (value == 'delete') {
                          _deleteMemo(memo);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'pin',
                          child: Row(
                            children: [
                              Icon(memo.isPinned ? Icons.push_pin_outlined : Icons.push_pin, size: 20),
                              const SizedBox(width: 8),
                              Text(memo.isPinned ? 'ピン解除' : 'ピン留め'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('削除', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      child: Icon(Icons.more_horiz, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(memo.content, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
          if (hasImage && imageFile != null && imageFile.existsSync())
            GestureDetector(
              onTap: () => ImageViewer.show(context, imageFile),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: Image.file(imageFile, width: double.infinity, height: 150, fit: BoxFit.cover),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
