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
    final dir = await getApplicationDocumentsDirectory();

    final rebuilt = hobbies.map((hobby) {
      final fullPath = hobby.getImagePath(dir.path);
      return Hobby(
        title: hobby.title,
        memo: hobby.memo,
        imageFileName: hobby.imageFileName, // imagePath はUIで構築
      );
    }).toList();

    state = rebuilt;
  }


  Future<void> add(Hobby hobby) async {
    final newList = [...state, hobby];
    state = newList;
    await HobbyJsonService.saveHobbies(newList);
  }

  Future<void> remove(Hobby hobby) async {
    final newList = state.where((h) => h != hobby).toList();
    state = newList;
    await HobbyJsonService.saveHobbies(newList);
  }
}
