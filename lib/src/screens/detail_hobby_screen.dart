import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/hobby.dart';
import '../models/hobby_memo.dart';
import '../services/memo_service.dart';
import 'edit_hobby_screen.dart';
import 'add_memo_screen.dart';

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
    final memos = await MemoService.loadMemosForHobby(widget.hobby.id);
    final count = memos.length;
    setState(() {
      _memos = memos;
      _memoCount = count;
    });
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
                              borderRadius: BorderRadius.circular(50),
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
                              child: CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          // ヘッダー（時間のみ）
          Row(
            children: [
              Text(
                _formatDateTime(memo.createdAt),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
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
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      snapshot.data!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
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
}