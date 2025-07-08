import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hobby.dart';
import '../services/hobby_json_service.dart';

final hobbyListProvider = StateNotifierProvider<HobbyListNotifier, List<Hobby>>(
  (ref) => HobbyListNotifier(),
);

class HobbyListNotifier extends StateNotifier<List<Hobby>> {
  HobbyListNotifier() : super([]) {
    load();
  }

  Future<void> load() async {
    final hobbies = await HobbyJsonService.loadHobbies();
    // fromJsonで既に互換性処理が完了しているため、そのまま設定
    state = hobbies;
  }


  Future<void> add(Hobby hobby) async {
    final newList = [...state, hobby];
    state = newList;
    await HobbyJsonService.saveHobbies(newList);
  }

  Future<void> remove(Hobby hobby) async {
    final newList = state.where((h) => h.id != hobby.id).toList();
    state = newList;
    await HobbyJsonService.saveHobbies(newList);
  }

  Future<void> update(Hobby updatedHobby) async {
    final newList = state.map((h) => h.id == updatedHobby.id ? updatedHobby : h).toList();
    state = newList;
    await HobbyJsonService.saveHobbies(newList);
  }

  /// 特定カテゴリーの趣味の順序を変更
  Future<void> reorderHobbiesInCategory(String categoryId, List<Hobby> reorderedHobbies) async {
    // 並び替え対象の趣味のIDリストを取得
    final reorderedIds = reorderedHobbies.map((h) => h.id).toSet();
    
    // order値を更新した趣味リストを作成
    final updatedHobbies = <Hobby>[];
    for (int i = 0; i < reorderedHobbies.length; i++) {
      updatedHobbies.add(reorderedHobbies[i].copyWith(order: i));
    }
    
    // 現在の状態から並び替え対象以外の趣味と、並び替え後の趣味を統合
    final newList = state.map((hobby) {
      if (reorderedIds.contains(hobby.id)) {
        // 並び替え後のリストから対応する趣味を見つけて返す
        return updatedHobbies.firstWhere((h) => h.id == hobby.id);
      }
      return hobby;
    }).toList();
    
    state = newList;
    await HobbyJsonService.saveHobbies(newList);
  }
}
