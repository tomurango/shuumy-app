import 'package:uuid/uuid.dart';

class HabitLog {
  final String id;
  final String hobbyId;
  final DateTime date; // 日付のみ（00:00:00 に正規化）

  HabitLog({
    required this.id,
    required this.hobbyId,
    required this.date,
  });

  /// 日付を 00:00:00 に正規化
  static DateTime normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// 新しい HabitLog を作成（押下時刻をそのまま保存）
  factory HabitLog.create({required String hobbyId, DateTime? date}) {
    return HabitLog(
      id: const Uuid().v4(),
      hobbyId: hobbyId,
      date: date ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'hobbyId': hobbyId,
    'date': date.toIso8601String(),
  };

  factory HabitLog.fromJson(Map<String, dynamic> json) => HabitLog(
    id: json['id'] as String? ?? const Uuid().v4(),
    hobbyId: json['hobbyId'] as String,
    date: DateTime.parse(json['date'] as String),
  );
}
