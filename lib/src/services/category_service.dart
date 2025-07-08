import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../models/category.dart';

class CategoryService {
  static const _fileName = 'categories.json';
  static const _backgroundDirName = 'category_backgrounds';

  /// すべてのカテゴリーを取得
  static Future<List<Category>> getAllCategories() async {
    try {
      final file = await _getCategoriesFile();
      if (!(await file.exists())) {
        // 初回起動時はデフォルトカテゴリーのみ作成
        final defaultCategory = Category.defaultCategory();
        await saveCategories([defaultCategory]);
        return [defaultCategory];
      }

      final contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);
      final categories = jsonList.map((json) => Category.fromJson(json)).toList();
      
      // orderでソート
      categories.sort((a, b) => a.order.compareTo(b.order));
      
      return categories;
    } catch (e) {
      // エラーの場合はデフォルトカテゴリーのみ返す
      return [Category.defaultCategory()];
    }
  }

  /// カテゴリーを保存
  static Future<void> saveCategories(List<Category> categories) async {
    final file = await _getCategoriesFile();
    final jsonList = categories.map((category) => category.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }

  /// カテゴリーを追加
  static Future<Category> addCategory({
    required String name,
    String? backgroundImagePath,
  }) async {
    final categories = await getAllCategories();
    final maxOrder = categories.isEmpty ? 0 : categories.map((c) => c.order).reduce((a, b) => a > b ? a : b);
    
    final newCategory = Category.create(
      name: name,
      order: maxOrder + 1,
      backgroundImagePath: backgroundImagePath,
    );

    categories.add(newCategory);
    await saveCategories(categories);
    
    return newCategory;
  }

  /// カテゴリーを更新
  static Future<void> updateCategory(Category updatedCategory) async {
    final categories = await getAllCategories();
    final index = categories.indexWhere((c) => c.id == updatedCategory.id);
    
    if (index != -1) {
      categories[index] = updatedCategory;
      await saveCategories(categories);
    }
  }

  /// カテゴリーを削除
  static Future<void> deleteCategory(String categoryId) async {
    // デフォルトカテゴリーは削除不可
    if (categoryId == 'default_all') {
      throw Exception('デフォルトカテゴリーは削除できません');
    }

    final categories = await getAllCategories();
    final categoryToDelete = categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => throw Exception('カテゴリーが見つかりません'),
    );

    // 背景画像も削除
    if (categoryToDelete.backgroundImagePath != null) {
      await _deleteBackgroundImage(categoryToDelete.backgroundImagePath!);
    }

    categories.removeWhere((c) => c.id == categoryId);
    await saveCategories(categories);
  }

  /// カテゴリーの順序を更新
  static Future<void> reorderCategories(List<Category> reorderedCategories) async {
    // 順序を再設定
    final orderedCategories = <Category>[];
    for (int i = 0; i < reorderedCategories.length; i++) {
      orderedCategories.add(reorderedCategories[i].copyWith(order: i));
    }

    await saveCategories(orderedCategories);
  }

  /// カテゴリー背景画像を保存
  static Future<String> saveCategoryBackground(File imageFile) async {
    final dir = await getApplicationDocumentsDirectory();
    final backgroundDir = Directory(path.join(dir.path, _backgroundDirName));
    
    if (!(await backgroundDir.exists())) {
      await backgroundDir.create(recursive: true);
    }

    final fileName = 'category_bg_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
    final savedFile = File(path.join(backgroundDir.path, fileName));
    await imageFile.copy(savedFile.path);
    
    return fileName;
  }

  /// カテゴリー背景画像のファイルを取得
  static Future<File?> getCategoryBackgroundFile(String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = path.join(dir.path, _backgroundDirName, fileName);
      final file = File(filePath);
      
      return await file.exists() ? file : null;
    } catch (e) {
      return null;
    }
  }

  /// 特定のカテゴリーを取得
  static Future<Category?> getCategoryById(String categoryId) async {
    final categories = await getAllCategories();
    try {
      return categories.firstWhere((c) => c.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  /// 使用されていない背景画像を削除
  static Future<void> cleanupUnusedBackgrounds() async {
    try {
      final categories = await getAllCategories();
      final usedFiles = categories
          .where((c) => c.backgroundImagePath != null)
          .map((c) => c.backgroundImagePath!)
          .toSet();

      final dir = await getApplicationDocumentsDirectory();
      final backgroundDir = Directory(path.join(dir.path, _backgroundDirName));
      
      if (!(await backgroundDir.exists())) return;

      final files = await backgroundDir.list().toList();
      for (final file in files) {
        if (file is File) {
          final fileName = path.basename(file.path);
          if (!usedFiles.contains(fileName)) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      // エラーは無視（クリーンアップは重要ではない）
    }
  }

  static Future<File> _getCategoriesFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(path.join(dir.path, _fileName));
  }

  static Future<void> _deleteBackgroundImage(String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = path.join(dir.path, _backgroundDirName, fileName);
      final file = File(filePath);
      
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // エラーは無視
    }
  }
}