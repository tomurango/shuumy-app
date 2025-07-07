import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
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
}
