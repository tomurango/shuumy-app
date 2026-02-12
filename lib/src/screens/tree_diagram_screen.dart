import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../models/tree_node.dart';
import '../models/hobby_memo.dart';
import '../providers/tree_node_provider.dart';
import '../services/tree_node_service.dart';
import '../services/memo_service.dart';
import 'add_memo_screen.dart';

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
    // 初期カテゴリーが指定されている場合、そのノードまで展開
    if (widget.initialCategoryId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _expandToCategory(widget.initialCategoryId!);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 指定カテゴリーまで展開
  void _expandToCategory(String categoryId) {
    final nodes = ref.read(treeNodeListProvider);
    if (nodes.isEmpty) return; // ノードがまだロードされていない場合は何もしない

    final expandedNodes = ref.read(expandedNodesProvider.notifier);

    // ルートノードを展開
    final rootNode = nodes.where((n) => n.type == NodeType.root).firstOrNull;
    if (rootNode != null) {
      expandedNodes.state = {...expandedNodes.state, rootNode.id};
    }

    // カテゴリーノードを選択状態に
    final categoryNodeId = 'category_$categoryId';
    ref.read(selectedNodeProvider.notifier).state = categoryNodeId;
  }

  @override
  Widget build(BuildContext context) {
    final nodes = ref.watch(treeNodeListProvider);
    final rootNode = nodes.firstWhere(
      (n) => n.type == NodeType.root,
      orElse: () => TreeNode.createRoot(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('樹形図'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      ),
      body: nodes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                _buildTreeNode(rootNode, 0),
              ],
            ),
    );
  }

  /// ツリーノードを再帰的に構築
  Widget _buildTreeNode(TreeNode node, int depth) {
    final expandedNodes = ref.watch(expandedNodesProvider);
    final selectedNode = ref.watch(selectedNodeProvider);
    final children = ref.read(treeNodeListProvider.notifier).getChildren(node.id);

    final isExpanded = expandedNodes.contains(node.id);
    final isSelected = selectedNode == node.id;
    final hasChildren = children.isNotEmpty;
    // 趣味ノードとカスタムノードは子がなくても展開可能（ノード追加のため）
    final canExpand = hasChildren || node.type == NodeType.hobby || node.type == NodeType.custom;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ノード本体
        Padding(
          padding: EdgeInsets.only(left: depth * 24.0),
          child: InkWell(
            onTap: () {
              // 選択状態を更新
              ref.read(selectedNodeProvider.notifier).state = node.id;

              // 展開可能な場合は展開/折りたたみ
              if (canExpand) {
                final newExpandedNodes = Set<String>.from(expandedNodes);
                if (isExpanded) {
                  newExpandedNodes.remove(node.id);
                } else {
                  newExpandedNodes.add(node.id);
                }
                ref.read(expandedNodesProvider.notifier).state = newExpandedNodes;
              }
            },
            onLongPress: node.isEditable
                ? () => _showNodeOptions(node)
                : null,
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
                  // 展開アイコン（趣味・カスタムノードは子がなくても表示）
                  if (canExpand)
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                      size: 24,
                      color: Colors.grey.shade600,
                    )
                  else
                    const SizedBox(width: 24),
                  const SizedBox(width: 8),

                  // ノードアイコン
                  _buildNodeIcon(node),
                  const SizedBox(width: 12),

                  // ノードタイトル
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          node.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: node.type == NodeType.root || node.type == NodeType.category
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        if (node.description != null && node.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              node.description!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // メモボタン（趣味ノードとカスタムノード）
                  if (node.type == NodeType.hobby || node.type == NodeType.custom)
                    IconButton(
                      onPressed: () => _showMemoSheet(node),
                      icon: Icon(
                        Icons.note_alt_outlined,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      tooltip: 'メモ',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // 子ノード
        if (isExpanded && hasChildren)
          ...children.map((child) => _buildTreeNode(child, depth + 1)),

        // カスタムノード追加ボタン（編集可能ノードまたは趣味ノード、かつ深さ制限内）
        if (isExpanded && (node.isEditable || node.type == NodeType.hobby)) ...[
          // 深さが制限内かチェック
          if (depth + 1 < TreeNodeService.maxDepth)
            Padding(
              padding: EdgeInsets.only(left: (depth + 1) * 24.0),
              child: TextButton.icon(
                onPressed: () => _showAddNodeDialog(node.id),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('ノードを追加'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            )
          else
            Padding(
              padding: EdgeInsets.only(left: (depth + 1) * 24.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '階層の上限に達しました',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }

  /// ノードアイコンを構築
  Widget _buildNodeIcon(TreeNode node) {
    switch (node.type) {
      case NodeType.root:
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
            ),
          ),
        );
      case NodeType.category:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.folder,
            color: Colors.blue.shade700,
          ),
        );
      case NodeType.hobby:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.star,
            color: Colors.green.shade700,
          ),
        );
      case NodeType.custom:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            node.isCompleted ? Icons.check_circle : Icons.circle_outlined,
            color: Colors.orange.shade700,
          ),
        );
    }
  }

  /// ノード追加ダイアログを表示
  void _showAddNodeDialog(String parentId) {
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

                final order = ref.read(treeNodeListProvider.notifier).getChildren(parentId).length;

                final newNode = TreeNode.createCustom(
                  parentId: parentId,
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                  order: order,
                );

                try {
                  await ref.read(treeNodeListProvider.notifier).addNode(newNode);

                  // 親ノードを展開
                  final expandedNodes = ref.read(expandedNodesProvider.notifier);
                  expandedNodes.state = {...expandedNodes.state, parentId};

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
  void _showNodeOptions(TreeNode node) {
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
                  _showEditNodeDialog(node);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('削除', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(node);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// ノード編集ダイアログを表示
  void _showEditNodeDialog(TreeNode node) {
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
                  decoration: const InputDecoration(
                    labelText: 'タイトル',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: '説明（任意）',
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

                final updatedNode = node.copyWith(
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                );

                try {
                  await ref.read(treeNodeListProvider.notifier).updateNode(updatedNode);

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

  /// 削除確認ダイアログを表示
  void _showDeleteConfirmation(TreeNode node) {
    final children = ref.read(treeNodeListProvider.notifier).getChildren(node.id);
    final hasChildren = children.isNotEmpty;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ノードを削除'),
          content: Text(
            hasChildren
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
                  await ref.read(treeNodeListProvider.notifier).deleteNode(node.id);

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
  void _showMemoSheet(TreeNode node) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MemoBottomSheet(
        node: node,
        onMemoAdded: () {
          // メモ追加後にシートを更新するため再表示
          Navigator.pop(context);
          _showMemoSheet(node);
        },
      ),
    );
  }
}

/// メモ一覧ボトムシート
class _MemoBottomSheet extends StatefulWidget {
  final TreeNode node;
  final VoidCallback onMemoAdded;

  const _MemoBottomSheet({
    required this.node,
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
    if (widget.node.type == NodeType.hobby && widget.node.hobbyId != null) {
      // 趣味ノードの場合はhobbyIdで取得
      memos = await MemoService.loadMemosForHobby(widget.node.hobbyId!);
    } else {
      // カスタムノードの場合はnodeIdで取得
      memos = await MemoService.loadMemosForNode(widget.node.id);
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
          // カスタムノードの場合はnodeIdを使用
          nodeId: widget.node.type == NodeType.custom ? widget.node.id : null,
          nodeTitle: widget.node.title,
          // 趣味ノードの場合はhobbyIdを使用
          hobbyId: widget.node.type == NodeType.hobby ? widget.node.hobbyId : null,
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
                        '${widget.node.title}のメモ',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
                                Icon(
                                  Icons.note_alt_outlined,
                                  size: 64,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'メモはまだありません',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
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
    final imageFile = hasImage
        ? File('$_basePath/images/${memo.imageFileName}')
        : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // メモ内容
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ピンマークと日付
                Row(
                  children: [
                    if (memo.isPinned)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.push_pin,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    Text(
                      _formatDate(memo.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(),
                    // メニューボタン
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
                              Icon(
                                memo.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                                size: 20,
                              ),
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
                      child: Icon(
                        Icons.more_horiz,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // コンテンツ
                Text(
                  memo.content,
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),

          // 画像
          if (hasImage && imageFile != null && imageFile.existsSync())
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Image.file(
                imageFile,
                width: double.infinity,
                height: 150,
                fit: BoxFit.cover,
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
