import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../models/hobby.dart';
import '../providers/hobby_list_provider.dart';
import 'add_hobby_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

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

                      return Column(
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
