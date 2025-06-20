import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../models/hobby.dart';
import '../providers/hobby_list_provider.dart';
import 'add_hobby_screen.dart';
import 'edit_hobby_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final hobbies = ref.watch(hobbyListProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 背景画像
          Positioned.fill(
            child: Image.asset(
              'assets/background.png',
              fit: BoxFit.cover,
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

                  return GridView.builder(
                    itemCount: hobbies.length,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 24,
                      crossAxisSpacing: 24,
                      childAspectRatio: 0.75,
                    ),
                    itemBuilder: (context, index) {
                      final hobby = hobbies[index];
                      final imagePath = p.join(dirPath, 'images', hobby.imageFileName);
                      final file = File(imagePath);
                      final exists = file.existsSync();

                      return GestureDetector(
                        onLongPress: () => _showContextMenu(context, hobby, ref),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              backgroundImage: exists ? FileImage(file) : null,
                              child: !exists
                                  ? const Icon(Icons.broken_image, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              hobby.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          // ドック風ボタン
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle, size: 36, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddHobbyScreen(),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, size: 36, color: Colors.white),
                    onPressed: () {
                      // 設定画面へ
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
