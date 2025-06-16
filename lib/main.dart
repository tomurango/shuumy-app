import 'package:flutter/material.dart';

void main() {
  runApp(const ShuumyApp());
}

class ShuumyApp extends StatelessWidget {
  const ShuumyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'title': 'ミュージック', 'icon': Icons.music_note},
      // ここに仮の趣味を追加可能
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 背景画像
          Positioned.fill(
            child: Image.asset(
              'assets/background.png', // 画像パスは適宜変更
              fit: BoxFit.cover,
            ),
          ),
          // アイコン一覧
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              
              child: GridView.builder(
                itemCount: items.length,
                physics: const NeverScrollableScrollPhysics(),
                //shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 24,
                  childAspectRatio: 0.75,
                ),

                itemBuilder: (context, index) {
                  final item = items[index];
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Icon(
                          item['icon'] as IconData,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['title']! as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,                  // ← 1行に制限
                        overflow: TextOverflow.ellipsis, // ← はみ出たら「...」で省略
                        softWrap: false,              // ← 自動改行を防止
                      ),
                    ],
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
                      // 趣味追加
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
          )
        ],
      ),
    );
  }
}
