import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../services/category_service.dart';
import '../providers/hobby_list_provider.dart';

/// カテゴリー一覧を管理するProvider
final categoryListProvider = StateNotifierProvider<CategoryListNotifier, List<Category>>((ref) {
  return CategoryListNotifier();
});

class CategoryListNotifier extends StateNotifier<List<Category>> {
  CategoryListNotifier() : super([]) {
    _loadCategories();
  }

  /// カテゴリーを読み込み
  Future<void> _loadCategories() async {
    try {
      final categories = await CategoryService.getAllCategories();
      state = categories;
    } catch (e) {
      // エラーの場合はデフォルトカテゴリーのみ
      state = [Category.defaultCategory()];
    }
  }

  /// カテゴリーを追加
  Future<void> addCategory({
    required String name,
    String? backgroundImagePath,
  }) async {
    try {
      final newCategory = await CategoryService.addCategory(
        name: name,
        backgroundImagePath: backgroundImagePath,
      );
      state = [...state, newCategory];
    } catch (e) {
      rethrow;
    }
  }

  /// カテゴリーを更新
  Future<void> updateCategory(Category updatedCategory) async {
    try {
      await CategoryService.updateCategory(updatedCategory);
      state = state.map((category) {
        return category.id == updatedCategory.id ? updatedCategory : category;
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// カテゴリーを削除
  Future<void> deleteCategory(String categoryId) async {
    try {
      await CategoryService.deleteCategory(categoryId);
      state = state.where((category) => category.id != categoryId).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// カテゴリーの順序を変更
  Future<void> reorderCategories(List<Category> reorderedCategories) async {
    try {
      await CategoryService.reorderCategories(reorderedCategories);
      state = reorderedCategories;
    } catch (e) {
      rethrow;
    }
  }

  /// カテゴリーを手動でリロード
  Future<void> reload() async {
    await _loadCategories();
  }

  /// 特定のカテゴリーを取得
  Category? getCategoryById(String categoryId) {
    try {
      return state.firstWhere((category) => category.id == categoryId);
    } catch (e) {
      return null;
    }
  }
}

/// 現在選択されているカテゴリーのProvider
final selectedCategoryProvider = StateProvider<String>((ref) {
  return 'default_all'; // デフォルトは「すべて」カテゴリー
});

/// 特定カテゴリーの趣味のみを取得するProvider
final hobbiesByCategoryProvider = Provider.family<List<dynamic>, String>((ref, categoryId) {
  final allHobbies = ref.watch(hobbyListProvider);
  
  if (categoryId == 'default_all') {
    return allHobbies; // 「すべて」の場合は全趣味を返す
  }
  
  return allHobbies.where((hobby) => hobby.categoryId == categoryId).toList();
});