import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit_log.dart';
import '../services/habit_log_service.dart';

final habitLogListProvider =
    StateNotifierProvider<HabitLogNotifier, List<HabitLog>>(
  (ref) => HabitLogNotifier(),
);

class HabitLogNotifier extends StateNotifier<List<HabitLog>> {
  HabitLogNotifier() : super([]) {
    load();
  }

  Future<void> load() async {
    final logs = await HabitLogService.loadHabitLogs();
    state = logs;
  }

  /// 今日の習慣ログをトグル（あれば削除、なければ押下時刻で追加）
  Future<bool> toggleToday(String hobbyId) async {
    final today = HabitLog.normalizeDate(DateTime.now());
    final index = state.indexWhere(
      (l) => l.hobbyId == hobbyId && HabitLog.normalizeDate(l.date) == today,
    );
    if (index != -1) {
      final newList = [...state]..removeAt(index);
      state = newList;
      await HabitLogService.saveHabitLogs(newList);
      return false; // 削除
    } else {
      final log = HabitLog.create(hobbyId: hobbyId); // 押下時刻で保存
      final newList = [...state, log];
      state = newList;
      await HabitLogService.saveHabitLogs(newList);
      return true; // 追加
    }
  }

  /// 今日のログがあるか確認（同期）
  bool hasLogForToday(String hobbyId) {
    final today = HabitLog.normalizeDate(DateTime.now());
    return state.any(
      (l) => l.hobbyId == hobbyId && HabitLog.normalizeDate(l.date) == today,
    );
  }
}
