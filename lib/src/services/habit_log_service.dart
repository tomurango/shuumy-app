import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/habit_log.dart';

class HabitLogService {
  static const _fileName = 'habit_logs.json';

  static Future<File> _getLocalFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  static Future<List<HabitLog>> loadHabitLogs() async {
    try {
      final file = await _getLocalFile();
      if (!(await file.exists())) return [];
      final contents = await file.readAsString();
      final List<dynamic> jsonData = jsonDecode(contents);
      return jsonData.map((e) => HabitLog.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveHabitLogs(List<HabitLog> logs) async {
    final file = await _getLocalFile();
    final jsonData = logs.map((l) => l.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonData));
  }

  /// 今日の習慣ログをトグル（あれば削除、なければ追加）
  static Future<bool> toggleHabitLog(String hobbyId, DateTime date) async {
    final normalized = HabitLog.normalizeDate(date);
    final logs = await loadHabitLogs();
    final index = logs.indexWhere(
      (l) => l.hobbyId == hobbyId && HabitLog.normalizeDate(l.date) == normalized,
    );
    if (index != -1) {
      logs.removeAt(index);
      await saveHabitLogs(logs);
      return false; // ログ削除 → false
    } else {
      logs.add(HabitLog.create(hobbyId: hobbyId)); // 押下時刻で保存
      await saveHabitLogs(logs);
      return true; // ログ追加 → true
    }
  }

  /// 指定日にログがあるか確認
  static Future<bool> hasLogForDate(String hobbyId, DateTime date) async {
    final normalized = HabitLog.normalizeDate(date);
    final logs = await loadHabitLogs();
    return logs.any(
      (l) => l.hobbyId == hobbyId && HabitLog.normalizeDate(l.date) == normalized,
    );
  }

  /// 趣味のすべてのログを取得
  static Future<List<HabitLog>> loadLogsForHobby(String hobbyId) async {
    final logs = await loadHabitLogs();
    return logs.where((l) => l.hobbyId == hobbyId).toList();
  }

  /// 期間内のログを取得（複数趣味対応）
  static Future<List<HabitLog>> loadLogsForPeriod({
    required List<String> hobbyIds,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final logs = await loadHabitLogs();
    return logs.where((l) {
      if (!hobbyIds.contains(l.hobbyId)) return false;
      final startCheck = !l.date.isBefore(startDate);
      final endCheck = !l.date.isAfter(endDate);
      return startCheck && endCheck;
    }).toList();
  }
}
