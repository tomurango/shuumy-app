import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/hobby.dart';
import '../models/hobby_memo.dart';
import '../models/hobby_node.dart';
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
  int _memoCount = 0;
  List<HobbyMemo> _memos = [];
  Map<String, HobbyNode> _nodeMap = {}; // ノードIDからノード情報へのマップ

  @override
  void initState() {
    super.initState();
    _loadImage();
    _loadMemos();
  }

  Future<void> _loadImage() async {
    final dir = await getApplicationDocumentsDirectory();
    final imagePath = path.join(dir.path, 'images', widget.hobby.imageFileName);
    final file = File(imagePath);
    if (file.existsSync()) {
      setState(() {
        _imageFile = file;
      });
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
      body: Stack(
        children: [
          // メインコンテンツ
          CustomScrollView(
            slivers: [
              // シンプルなAppBar
              SliverAppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
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
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.black),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditHobbyScreen(hobby: widget.hobby),
                        ),
                      );
                    },
                  ),
                ],
              ),
              
              // プロフィール情報
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      
                      // プロフィール画像と基本情報
                      Row(
                        children: [
                          // 大きなプロフィール画像
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
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
                          ),
                          const Spacer(),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 趣味名とメタ情報
                      Text(
                        widget.hobby.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      
                      
                      const SizedBox(height: 16),
                      
                      // メモ内容
                      if (widget.hobby.memo != null && widget.hobby.memo!.isNotEmpty)
                        Text(
                          widget.hobby.memo!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        )
                      else
                        Text(
                          'この趣味についてのメモはまだありません。',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      
                      const SizedBox(height: 20),
                      
                      // 統計情報（Twitter風）
                      Row(
                        children: [
                          _buildStatItem('追加日', _getFormattedDate()),
                          const SizedBox(width: 20),
                          _buildStatItem('メモ', '$_memoCount'),
                        ],
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // 境界線
                      Container(
                        height: 1,
                        color: Colors.grey[200],
                      ),
                      
                      
                      const SizedBox(height: 30),
                      
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
                          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey[300]),
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
                            children: _memos.map((memo) => _buildMemoItem(memo)).toList(),
                          ),
                        ),
                      
                      const SizedBox(height: 100), // フローティングボタンのための余白
                    ],
                  ),
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
                  // メモが追加されたらUIを更新
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
          
          // メモ内容
          Text(
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