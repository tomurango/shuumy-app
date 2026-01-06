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
      // stateを更新（並び替え順序を保持）
      final updatedState = state.map((category) {
        return category.id == updatedCategory.id ? updatedCategory : category;
      }).toList();

      // 更新後のstate全体をファイルに保存（順序を保持）
      await CategoryService.saveCategories(updatedState);

      // stateを更新
      state = updatedState;
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
      // 新しいorder値を設定
      final orderedCategories = <Category>[];
      for (int i = 0; i < reorderedCategories.length; i++) {
        orderedCategories.add(reorderedCategories[i].copyWith(order: i));
      }

      // ファイルに保存
      await CategoryService.saveCategories(orderedCategories);

      // stateを更新（新しいorder値を持つリスト）
      state = orderedCategories;
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
  
  List<dynamic> filteredHobbies;
  if (categoryId == 'default_all') {
    filteredHobbies = allHobbies; // 「すべて」の場合は全趣味を返す
  } else {
    filteredHobbies = allHobbies.where((hobby) => hobby.categoryId == categoryId).toList();
  }
  
  // order順でソート
  filteredHobbies.sort((a, b) => a.order.compareTo(b.order));
  return filteredHobbies;
});