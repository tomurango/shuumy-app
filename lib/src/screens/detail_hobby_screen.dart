import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/hobby.dart';
import '../models/hobby_memo.dart';
import '../models/hobby_node.dart';
import '../providers/hobby_list_provider.dart';
import '../providers/habit_log_provider.dart';
import '../services/memo_service.dart';
import '../shared/widgets/image_viewer.dart';
import 'edit_hobby_screen.dart';
import 'add_memo_screen.dart';
import 'edit_memo_screen.dart';

class DetailHobbyScreen extends ConsumerStatefulWidget {
  final Hobby hobby;
  
  const DetailHobbyScreen({super.key, required this.hobby});

  @override
  ConsumerState<DetailHobbyScreen> createState() => _DetailHobbyScreenState();
}

class _DetailHobbyScreenState extends ConsumerState<DetailHobbyScreen> {
  File? _imageFile;
  File? _headerImageFile;
  int _memoCount = 0;
  List<HobbyMemo> _memos = [];
  Map<String, HobbyNode> _nodeMap = {};
  final ScrollController _scrollController = ScrollController();
  bool _isScrolledPastHeader = false;

  // ヘッダー画像のうち AppBar より下に見える部分の高さ
  static const double _headerVisibleHeight = 60.0;

  @override
  void initState() {
    super.initState();
    _loadImages();
    _loadMemos();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final scrolled = _scrollController.offset > _headerVisibleHeight;
    if (scrolled != _isScrolledPastHeader) {
      setState(() => _isScrolledPastHeader = scrolled);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadImages() async {
    final dir = await getApplicationDocumentsDirectory();

    // アイコン画像
    final imagePath = path.join(dir.path, 'images', widget.hobby.imageFileName);
    final imageFile = File(imagePath);
    if (imageFile.existsSync()) {
      setState(() => _imageFile = imageFile);
    }

    // ヘッダー画像
    if (widget.hobby.headerImageFileName != null) {
      final headerPath =
          path.join(dir.path, 'headers', widget.hobby.headerImageFileName!);
      final headerFile = File(headerPath);
      if (headerFile.existsSync()) {
        setState(() => _headerImageFile = headerFile);
      }
    }
  }

  Future<void> _loadMemos() async {
    // 趣味とその子ノードすべてのメモを取得
    final memos = await MemoService.loadMemosForHobbyWithDescendants(widget.hobby);
    final count = memos.length;

    // ノード情報を取得（メモの出所を表示するため）
    final nodeMap = <String, HobbyNode>{};
    _buildNodeMap(widget.hobby.children, nodeMap);

    setState(() {
      _memos = memos;
      _memoCount = count;
      _nodeMap = nodeMap;
    });
  }

  /// 子ノードのマップを再帰的に構築
  void _buildNodeMap(List<HobbyNode> nodes, Map<String, HobbyNode> nodeMap) {
    for (final node in nodes) {
      nodeMap[node.id] = node;
      if (node.children.isNotEmpty) {
        _buildNodeMap(node.children, nodeMap);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: _buildNavButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.pop(context),
          showBackground: false,
        ),
        title: Text(
          widget.hobby.title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Builder(builder: (context) {
            final hobby = ref.watch(hobbyListProvider).firstWhere(
              (h) => h.id == widget.hobby.id,
              orElse: () => widget.hobby,
            );
            return PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.black),
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditHobbyScreen(hobby: widget.hobby),
                    ),
                  );
                } else if (value == 'toggle_habit') {
                  ref.read(hobbyListProvider.notifier).update(
                    hobby.copyWith(isHabitTracked: !hobby.isHabitTracked),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        hobby.isHabitTracked
                            ? '習慣の記録を解除しました'
                            : '習慣として記録するように設定しました',
                      ),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 10),
                      Text('編集'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'toggle_habit',
                  child: Row(
                    children: [
                      Icon(
                        hobby.isHabitTracked
                            ? Icons.repeat_on_outlined
                            : Icons.repeat,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(hobby.isHabitTracked
                          ? '習慣の記録を解除'
                          : '習慣として記録する'),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
      body: Stack(
        children: [
          // メインコンテンツ
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // YouTubeスタイル: 角丸カード型ヘッダー画像
                    if (_headerImageFile != null) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: GestureDetector(
                          onTap: () =>
                              ImageViewer.show(context, _headerImageFile!),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: AspectRatio(
                              aspectRatio: 2.5,
                              child: Image.file(
                                _headerImageFile!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // アイコン + タイトル・統計を横並びに
                    Padding(
                      padding: EdgeInsets.only(
                        top: _headerImageFile == null ? 20 : 0,
                        left: 16,
                        right: 16,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildProfileIcon(),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.hobby.title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Builder(builder: (context) {
                                  final habitLogs = ref.watch(habitLogListProvider);
                                  final habitCount = habitLogs
                                      .where((l) => l.hobbyId == widget.hobby.id)
                                      .length;
                                  return Row(
                                    children: [
                                      _buildStatItem('追加日', _getFormattedDate()),
                                      const SizedBox(width: 16),
                                      _buildStatItem('メモ', '$_memoCount'),
                                      if (habitCount > 0) ...[
                                        const SizedBox(width: 16),
                                        _buildStatItem('習慣', '$habitCount'),
                                      ],
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),

                          // 説明文（あれば表示）
                          if (widget.hobby.memo != null &&
                              widget.hobby.memo!.isNotEmpty) ...[
                            Text(
                              widget.hobby.memo!,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 30),
                          ],

                          // メモ一覧セクション
                          const Text(
                            'メモ',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // メモ一覧
                          if (_memos.isEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 40, horizontal: 20),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.chat_bubble_outline,
                                        size: 60, color: Colors.grey[300]),
                                    const SizedBox(height: 16),
                                    Text(
                                      'まだメモがありません',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '最初のメモを追加して、趣味の記録を始めましょう。',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 15,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Colors.grey[200]!),
                                ),
                              ),
                              child: Column(
                                children: _memos
                                    .map((memo) => _buildMemoItem(memo))
                                    .toList(),
                              ),
                            ),

                          const SizedBox(height: 100), // フローティングボタンのための余白
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // フローティングメモ追加ボタン
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddMemoScreen(hobby: widget.hobby),
                  ),
                );

                if (result == true) {
                  _loadMemos();
                }
              },
              backgroundColor: const Color(0xFF00B386),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool showBackground,
  }) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: showBackground
          ? BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              shape: BoxShape.circle,
            )
          : null,
      child: IconButton(
        icon: Icon(icon, color: Colors.black),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }

  Widget _buildProfileIcon() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Hero(
        tag: 'hobby_image_${widget.hobby.id}',
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.grey[200],
            image: _imageFile != null
                ? DecorationImage(
                    image: FileImage(_imageFile!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: _imageFile == null
              ? Icon(Icons.broken_image, size: 30, color: Colors.grey[600])
              : null,
        ),
      ),
    );
  }


  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildMemoItem(HobbyMemo memo) {
    return Container(
      padding: const EdgeInsets.only(left: 0, right: 0, top: 12, bottom: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー（時間とメニューボタン）
          Row(
            children: [
              if (memo.isPinned) ...[
                Icon(
                  Icons.push_pin,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
              ],
              // カスタムノードからのメモにはノード名を表示
              if (memo.nodeId != null && _nodeMap.containsKey(memo.nodeId)) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    _nodeMap[memo.nodeId]!.title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                _formatDateTime(memo.createdAt),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_horiz,
                  color: Colors.grey[600],
                  size: 20,
                ),
                onSelected: (value) {
                  if (value == 'pin') {
                    _togglePinMemo(memo);
                  } else if (value == 'edit') {
                    _editMemo(memo);
                  } else if (value == 'delete') {
                    _deleteMemo(memo);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'pin',
                    child: Row(
                      children: [
                        Icon(
                          memo.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(memo.isPinned ? 'ピン留め解除' : 'ピン留め'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('編集'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('削除', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // メモ内容（テキスト選択可能）
          SelectableText(
            memo.content,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black,
              height: 1.4,
            ),
          ),
          
          // 画像があれば表示
          if (memo.imageFileName != null) ...[
            const SizedBox(height: 12),
            FutureBuilder<File?>(
              future: _getMemoImageFile(memo),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return GestureDetector(
                    onTap: () => ImageViewer.show(context, snapshot.data!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        snapshot.data!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<File?> _getMemoImageFile(HobbyMemo memo) async {
    if (memo.imageFileName == null) return null;
    
    final dir = await getApplicationDocumentsDirectory();
    final imagePath = path.join(dir.path, 'images', memo.imageFileName!);
    final file = File(imagePath);
    
    return file.existsSync() ? file : null;
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'たった今';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}時間前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else {
      return '${dateTime.year}/${dateTime.month}/${dateTime.day}';
    }
  }
  
  String _getFormattedDate() {
    final now = DateTime.now();
    return '${now.year}/${now.month}/${now.day}';
  }

  /// メモのピン留めを切り替え
  Future<void> _togglePinMemo(HobbyMemo memo) async {
    await MemoService.togglePinMemo(memo.id);
    await _loadMemos(); // メモリストを再読み込み

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(memo.isPinned ? 'ピン留めを解除しました' : 'ピン留めしました'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// メモを削除
  Future<void> _deleteMemo(HobbyMemo memo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メモを削除'),
        content: const Text('このメモを削除しますか？\n削除したメモは元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await MemoService.deleteMemo(memo.id);
      await _loadMemos(); // メモリストを再読み込み
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('メモを削除しました'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// メモを編集
  Future<void> _editMemo(HobbyMemo memo) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditMemoScreen(memo: memo),
      ),
    );

    if (result == true) {
      await _loadMemos(); // メモリストを再読み込み
    }
  }
}