import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/hobby.dart';
import '../../../services/memo_service.dart';
import '../../../shared/widgets/hobby_options_sheet.dart';
import '../../detail_hobby_screen.dart';

class HobbyCardWidget extends ConsumerWidget {
  final Hobby hobby;
  final File? imageFile;
  final String dirPath;
  final List<dynamic> hobbiesInCategory;
  final bool isReorderMode;
  final Function(BuildContext, Hobby, WidgetRef)? onDelete;

  const HobbyCardWidget({
    super.key,
    required this.hobby,
    required this.imageFile,
    required this.dirPath,
    required this.hobbiesInCategory,
    required this.isReorderMode,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: isReorderMode ? 3.0 : 1.0, // MD3準拠のelevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // MD3推奨の12px
      ),
      color: Theme.of(context).colorScheme.surfaceContainerLow, // MD3 Surface container
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetailHobbyScreen(hobby: hobby),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 120, // カード全体の高さを固定
            child: Row(
              children: [
                // 左側：アイコン画像エリア
                Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.all(10),
                  child: Hero(
                    tag: isReorderMode 
                        ? 'hobby_image_reorder_${hobby.id}'  // リオーダーモード時は別のtagを使用
                        : 'hobby_image_${hobby.id}',
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[100],
                        image: imageFile != null
                            ? DecorationImage(
                                image: FileImage(imageFile!),
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 趣味名
                      Flexible(
                        child: Text(
                          hobby.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      const SizedBox(height: 6),
                      
                      // メモ数と更新情報
                      FutureBuilder<int>(
                        future: MemoService.getMemoCountForHobby(hobby.id),
                        builder: (context, snapshot) {
                          final memoCount = snapshot.data ?? 0;
                          return Row(
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '$memoCount件のメモ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      
                      const SizedBox(height: 2),
                      
                      // 簡単な説明文または最終更新
                      Flexible(
                        child: hobby.memo != null && hobby.memo!.isNotEmpty
                            ? Text(
                                hobby.memo!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )
                            : Text(
                                'タップして詳細を確認',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                ),
                
                // 右端：オプションボタン
                Container(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                  onPressed: () => HobbyOptionsSheet.show(context, hobby, ref, onDelete: onDelete),
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: const EdgeInsets.all(6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}