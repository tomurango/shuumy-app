import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import '../providers/category_provider.dart';
import '../providers/hobby_list_provider.dart';
import '../services/category_service.dart';
import 'background_settings_screen.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends ConsumerState<CategoryManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryListProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'カテゴリー管理',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: () => _showAddCategoryDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 区切り線
          Container(
            height: 1,
            color: Colors.grey[200],
          ),
          
          if (categories.isEmpty)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: categories.length,
                onReorder: _onReorder,
                proxyDecorator: (child, index, animation) {
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (BuildContext context, Widget? child) {
                      final double animValue = Curves.easeInOut.transform(animation.value);
                      final double elevation = lerpDouble(2, 6, animValue)!;
                      final double scale = lerpDouble(1.0, 1.02, animValue)!;
                      return Transform.scale(
                        scale: scale,
                        child: Material(
                          elevation: elevation,
                          borderRadius: BorderRadius.circular(12),
                          child: child,
                        ),
                      );
                    },
                    child: child,
                  );
                },
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return _buildCategoryItem(category, index);
                },
              ),
            ),
        ],
      ),
    );
  }

  /// カテゴリー項目を構築
  Widget _buildCategoryItem(Category category, int index) {
    final isDefault = category.id == 'default_all';
    
    return Card(
      key: ValueKey(category.id),
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.drag_handle,
              color: Colors.grey[400],
              size: 20,
            ),
            const SizedBox(width: 8),
            _buildCategoryIcon(category),
          ],
        ),
        title: Text(
          category.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: isDefault 
            ? const Text(
                'デフォルトカテゴリー',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              )
            : Text(
                'order: ${category.order}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, category),
          itemBuilder: (context) => [
            if (!isDefault) ...[
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('編集'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            const PopupMenuItem(
              value: 'background',
              child: ListTile(
                leading: Icon(Icons.wallpaper),
                title: Text('背景画像'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (!isDefault) ...[
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('削除', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// カテゴリーアイコンを構築
  Widget _buildCategoryIcon(Category category) {
    if (category.backgroundImagePath != null) {
      return FutureBuilder<File?>(
        future: CategoryService.getCategoryBackgroundFile(category.backgroundImagePath!),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: FileImage(snapshot.data!),
                  fit: BoxFit.cover,
                ),
              ),
            );
          }
          return _buildDefaultIcon(category);
        },
      );
    }
    return _buildDefaultIcon(category);
  }

  /// デフォルトアイコンを構築
  Widget _buildDefaultIcon(Category category) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: category.id == 'default_all' 
            ? const Color(0xFF009977).withOpacity(0.1)
            : Colors.grey[100],
      ),
      child: Icon(
        category.id == 'default_all' 
            ? Icons.all_inclusive 
            : Icons.folder_outlined,
        color: category.id == 'default_all' 
            ? const Color(0xFF009977)
            : Colors.grey[600],
        size: 20,
      ),
    );
  }

  /// 並び替え処理
  void _onReorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final categories = List<Category>.from(ref.read(categoryListProvider));
    final item = categories.removeAt(oldIndex);
    categories.insert(newIndex, item);

    // 並び替え実行
    ref.read(categoryListProvider.notifier).reorderCategories(categories);
  }

  /// メニューアクション処理
  void _handleMenuAction(String action, Category category) {
    switch (action) {
      case 'edit':
        _showEditCategoryDialog(category);
        break;
      case 'background':
        _showBackgroundImagePicker(category);
        break;
      case 'delete':
        _showDeleteConfirmation(category);
        break;
    }
  }

  /// カテゴリー追加ダイアログ
  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('新しいカテゴリー'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'カテゴリー名を入力',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                try {
                  await ref.read(categoryListProvider.notifier).addCategory(name: name);
                  Navigator.pop(context);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('「$name」を追加しました'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('エラーが発生しました: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  /// カテゴリー編集ダイアログ
  void _showEditCategoryDialog(Category category) {
    final controller = TextEditingController(text: category.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('カテゴリー編集'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'カテゴリー名を入力',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty && name != category.name) {
                try {
                  final updatedCategory = category.copyWith(name: name);
                  await ref.read(categoryListProvider.notifier).updateCategory(updatedCategory);
                  Navigator.pop(context);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('「${category.name}」を「$name」に変更しました'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('エラーが発生しました: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 背景画像選択
  void _showBackgroundImagePicker(Category category) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BackgroundSettingsScreen(
          initialCategoryId: category.id,
        ),
      ),
    );
    
    // 背景設定画面から戻ってきた場合、カテゴリ一覧を更新
    if (result == true) {
      ref.read(categoryListProvider.notifier).reload();
    }
  }

  /// 削除確認ダイアログ
  void _showDeleteConfirmation(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange[600],
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text('カテゴリーを削除'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '「${category.name}」を削除しますか？',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.red[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'このカテゴリーの趣味は「すべて」カテゴリーに移動されます。',
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'キャンセル',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                // カテゴリーに属する趣味を「すべて」カテゴリーに移動
                await _moveHobbiesToDefaultCategory(category.id);
                
                // カテゴリーを削除
                await ref.read(categoryListProvider.notifier).deleteCategory(category.id);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('「${category.name}」を削除しました'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('エラーが発生しました: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '削除',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// カテゴリーに属する趣味をデフォルトカテゴリーに移動
  Future<void> _moveHobbiesToDefaultCategory(String categoryId) async {
    final hobbies = ref.read(hobbyListProvider);
    final hobbiesToMove = hobbies.where((hobby) => hobby.categoryId == categoryId).toList();
    
    for (final hobby in hobbiesToMove) {
      final updatedHobby = hobby.copyWith(categoryId: 'default_all');
      await ref.read(hobbyListProvider.notifier).update(updatedHobby);
    }
  }
}