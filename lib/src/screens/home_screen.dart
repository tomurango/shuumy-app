import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../models/hobby.dart';
import '../providers/hobby_list_provider.dart';
import '../services/background_image_service.dart';
import '../services/memo_service.dart';
import 'add_hobby_screen.dart';
import 'edit_hobby_screen.dart';
import 'detail_hobby_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  ImageProvider? _backgroundImage;

  @override
  void initState() {
    super.initState();
    _loadBackgroundImage();
  }

  Future<void> _loadBackgroundImage() async {
    try {
      final config = await BackgroundImageService.getCurrentConfig();
      if (config.type == BackgroundType.custom) {
        final imageProvider = await config.getImageProvider();
        setState(() {
          _backgroundImage = imageProvider;
        });
      } else {
        // デフォルトは背景画像なし（白背景）
        setState(() {
          _backgroundImage = null;
        });
      }
    } catch (e) {
      // エラーの場合は白背景
      setState(() {
        _backgroundImage = null;
      });
    }
  }

  void _showContextMenu(BuildContext context, Hobby hobby, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white.withOpacity(0.9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hobby.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMenuButton(
                  context,
                  icon: Icons.edit,
                  label: '編集',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditHobbyScreen(hobby: hobby),
                      ),
                    );
                  },
                ),
                _buildMenuButton(
                  context,
                  icon: Icons.delete,
                  label: '削除',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(context, hobby, ref);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
        decoration: BoxDecoration(
          color: (color ?? Colors.blue).withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color ?? Colors.blue),
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: color ?? Colors.blue),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: color ?? Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Hobby hobby, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: Text('「${hobby.title}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(hobbyListProvider.notifier).remove(hobby);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('「${hobby.title}」を削除しました')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hobbies = ref.watch(hobbyListProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 背景（カスタム画像または白背景）
          Positioned.fill(
            child: _backgroundImage != null
                ? Image(
                    image: _backgroundImage!,
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: Colors.white,
                  ),
          ),
          // アイコン一覧
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: FutureBuilder<Directory>(
                future: getApplicationDocumentsDirectory(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final dirPath = snapshot.data!.path;

                  return ListView.builder(
                    itemCount: hobbies.length,
                    padding: const EdgeInsets.only(bottom: 100), // FABのための余白
                    itemBuilder: (context, index) {
                      final hobby = hobbies[index];
                      final imagePath = p.join(dirPath, 'images', hobby.imageFileName);
                      final file = File(imagePath);
                      final exists = file.existsSync();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildHobbyCard(
                          hobby: hobby,
                          imageFile: exists ? file : null,
                          dirPath: dirPath,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          // フローティングアクションボタン
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: "settings",
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    );
                    
                    if (result == true) {
                      _loadBackgroundImage();
                    }
                  },
                  backgroundColor: Colors.white.withOpacity(0.9),
                  child: const Icon(Icons.settings, color: Color(0xFF009977)),
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: "add",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddHobbyScreen(),
                      ),
                    );
                  },
                  backgroundColor: const Color(0xFF009977),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHobbyCard({
    required Hobby hobby,
    required File? imageFile,
    required String dirPath,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailHobbyScreen(hobby: hobby),
          ),
        );
      },
      onLongPress: () => _showContextMenu(context, hobby, ref),
      child: Container(
        height: 120, // カード全体の高さを固定
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 左側：アイコン画像エリア
            Container(
              width: 100,
              height: 100,
              margin: const EdgeInsets.all(10),
              child: Hero(
                tag: 'hobby_image_${hobby.id}',
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                    image: imageFile != null
                        ? DecorationImage(
                            image: FileImage(imageFile),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: imageFile == null
                      ? Icon(
                          Icons.broken_image,
                          color: Colors.grey[400],
                          size: 40,
                        )
                      : null,
                ),
              ),
            ),
            
            // 右側：情報エリア
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 趣味名
                    Text(
                      hobby.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // メモ数と更新情報
                    FutureBuilder<int>(
                      future: MemoService.getMemoCountForHobby(hobby.id),
                      builder: (context, snapshot) {
                        final memoCount = snapshot.data ?? 0;
                        return Row(
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$memoCount件のメモ',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // 簡単な説明文または最終更新
                    if (hobby.memo != null && hobby.memo!.isNotEmpty)
                      Text(
                        hobby.memo!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      Text(
                        'タップして詳細を確認',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // 右端：矢印アイコン
            Container(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
