import 'dart:math';
import 'package:flutter/material.dart';
import '../models/hobby.dart';
import '../models/hobby_memo.dart';
import 'memo_service.dart';

/// 期間選択の種類
enum PeriodType {
  weekly('週間'),
  monthly('月間'),
  yearly('年間');
  
  const PeriodType(this.displayName);
  final String displayName;
}

/// 活動記録の統計情報
class ActivityStatistics {
  final int totalMemos;
  final int totalActiveDays;
  final Map<String, int> hobbyActivityCount;
  final Map<DateTime, int> dailyCount;
  final Map<DateTime, List<String>> dailyHobbies; // 日別の趣味リスト
  final List<HobbyMemo> recentMemos;
  
  ActivityStatistics({
    required this.totalMemos,
    required this.totalActiveDays,
    required this.hobbyActivityCount,
    required this.dailyCount,
    required this.dailyHobbies,
    required this.recentMemos,
  });
  
  /// JSON形式にシリアライズ
  Map<String, dynamic> toJson() {
    return {
      'totalMemos': totalMemos,
      'totalActiveDays': totalActiveDays,
      'hobbyActivityCount': hobbyActivityCount,
      'dailyCount': dailyCount.map((key, value) => MapEntry(key.toIso8601String(), value)),
      'dailyHobbies': dailyHobbies.map((key, value) => MapEntry(key.toIso8601String(), value)),
      'recentMemos': recentMemos.map((memo) => memo.toJson()).toList(),
    };
  }
  
  /// JSONからデシリアライズ
  static ActivityStatistics fromJson(Map<String, dynamic> json) {
    return ActivityStatistics(
      totalMemos: json['totalMemos'] ?? 0,
      totalActiveDays: json['totalActiveDays'] ?? 0,
      hobbyActivityCount: Map<String, int>.from(json['hobbyActivityCount'] ?? {}),
      dailyCount: (json['dailyCount'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(DateTime.parse(key), value as int)),
      dailyHobbies: (json['dailyHobbies'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(DateTime.parse(key), List<String>.from(value))),
      recentMemos: (json['recentMemos'] as List<dynamic>? ?? [])
          .map((memoJson) => HobbyMemo.fromJson(memoJson))
          .toList(),
    );
  }
}

/// 活動記録に関する期間情報
class PeriodInfo {
  final DateTime startDate;
  final DateTime endDate;
  final PeriodType periodType;
  final String displayTitle;
  
  PeriodInfo({
    required this.startDate,
    required this.endDate,
    required this.periodType,
    required this.displayTitle,
  });
}

/// 活動記録サービス
class ActivityRecordService {
  
  /// 指定した期間とカテゴリの活動統計を取得
  static Future<ActivityStatistics> getActivityStatistics({
    required String categoryId,
    required PeriodInfo periodInfo,
    required List<Hobby> hobbies,
  }) async {
    try {
      // カテゴリに属する趣味を取得
      final categoryHobbies = _filterHobbiesByCategory(hobbies, categoryId);
      
      // 期間内の全メモを取得
      final allMemos = <HobbyMemo>[];
      for (final hobby in categoryHobbies) {
        final hobbyMemos = await MemoService.loadMemosForHobby(hobby.id);
        final periodMemos = _filterMemosByPeriod(hobbyMemos, periodInfo);
        allMemos.addAll(periodMemos);
      }
      
      // 統計情報を計算
      return _calculateStatistics(allMemos, categoryHobbies);
      
    } catch (e) {
      debugPrint('活動統計取得エラー: $e');
      return ActivityStatistics(
        totalMemos: 0,
        totalActiveDays: 0,
        hobbyActivityCount: {},
        dailyCount: {},
        dailyHobbies: {},
        recentMemos: [],
      );
    }
  }
  
  /// カテゴリ別に趣味をフィルタリング
  static List<Hobby> _filterHobbiesByCategory(List<Hobby> hobbies, String categoryId) {
    if (categoryId == 'default_all') {
      return hobbies; // 「すべて」カテゴリの場合は全ての趣味を含む
    }
    return hobbies.where((hobby) => hobby.categoryId == categoryId).toList();
  }
  
  /// 期間内のメモをフィルタリング
  static List<HobbyMemo> _filterMemosByPeriod(List<HobbyMemo> memos, PeriodInfo periodInfo) {
    return memos.where((memo) {
      final memoDate = memo.createdAt;
      return memoDate.isAfter(periodInfo.startDate.subtract(const Duration(days: 1))) &&
             memoDate.isBefore(periodInfo.endDate.add(const Duration(days: 1)));
    }).toList();
  }
  
  /// 統計情報を計算
  static ActivityStatistics _calculateStatistics(List<HobbyMemo> memos, List<Hobby> hobbies) {
    // 趣味別活動カウント
    final hobbyActivityCount = <String, int>{};
    final dailyCount = <DateTime, int>{};
    final dailyHobbies = <DateTime, List<String>>{};
    final activeDays = <DateTime>{};
    
    // 趣味のマッピングを作成
    final hobbyMap = {for (final hobby in hobbies) hobby.id: hobby.title};
    
    for (final memo in memos) {
      // 趣味別カウント
      final hobbyTitle = hobbyMap[memo.hobbyId] ?? '不明な趣味';
      hobbyActivityCount[hobbyTitle] = (hobbyActivityCount[hobbyTitle] ?? 0) + 1;
      
      // 日別カウント
      final date = DateTime(memo.createdAt.year, memo.createdAt.month, memo.createdAt.day);
      dailyCount[date] = (dailyCount[date] ?? 0) + 1;
      
      // 日別趣味リスト
      if (!dailyHobbies.containsKey(date)) {
        dailyHobbies[date] = [];
      }
      if (!dailyHobbies[date]!.contains(hobbyTitle)) {
        dailyHobbies[date]!.add(hobbyTitle);
      }
      
      activeDays.add(date);
    }
    
    // 最新のメモを取得（最大10件）
    final sortedMemos = List<HobbyMemo>.from(memos);
    sortedMemos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recentMemos = sortedMemos.take(10).toList();
    
    return ActivityStatistics(
      totalMemos: memos.length,
      totalActiveDays: activeDays.length,
      hobbyActivityCount: hobbyActivityCount,
      dailyCount: dailyCount,
      dailyHobbies: dailyHobbies,
      recentMemos: recentMemos,
    );
  }
  
  /// 期間情報を生成
  static PeriodInfo getCurrentPeriodInfo(PeriodType periodType, [DateTime? baseDate]) {
    final now = baseDate ?? DateTime.now();
    
    switch (periodType) {
      case PeriodType.weekly:
        return _getWeeklyPeriodInfo(now);
      case PeriodType.monthly:
        return _getMonthlyPeriodInfo(now);
      case PeriodType.yearly:
        return _getYearlyPeriodInfo(now);
    }
  }
  
  /// 週間期間情報を取得
  static PeriodInfo _getWeeklyPeriodInfo(DateTime baseDate) {
    // 週の開始を月曜日に設定
    final weekday = baseDate.weekday;
    final startOfWeek = baseDate.subtract(Duration(days: weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return PeriodInfo(
      startDate: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
      endDate: DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59),
      periodType: PeriodType.weekly,
      displayTitle: '${startOfWeek.year} ${startOfWeek.month}/${startOfWeek.day}-${endOfWeek.month}/${endOfWeek.day}',
    );
  }
  
  /// 月間期間情報を取得
  static PeriodInfo _getMonthlyPeriodInfo(DateTime baseDate) {
    final startOfMonth = DateTime(baseDate.year, baseDate.month, 1);
    final endOfMonth = DateTime(baseDate.year, baseDate.month + 1, 0, 23, 59, 59);
    
    return PeriodInfo(
      startDate: startOfMonth,
      endDate: endOfMonth,
      periodType: PeriodType.monthly,
      displayTitle: '${baseDate.year}年${baseDate.month}月',
    );
  }
  
  /// 年間期間情報を取得
  static PeriodInfo _getYearlyPeriodInfo(DateTime baseDate) {
    final startOfYear = DateTime(baseDate.year, 1, 1);
    final endOfYear = DateTime(baseDate.year, 12, 31, 23, 59, 59);
    
    return PeriodInfo(
      startDate: startOfYear,
      endDate: endOfYear,
      periodType: PeriodType.yearly,
      displayTitle: '${baseDate.year}年',
    );
  }
  
  /// 前の期間情報を取得
  static PeriodInfo getPreviousPeriodInfo(PeriodInfo currentPeriod) {
    switch (currentPeriod.periodType) {
      case PeriodType.weekly:
        final previousWeek = currentPeriod.startDate.subtract(const Duration(days: 7));
        return _getWeeklyPeriodInfo(previousWeek);
      case PeriodType.monthly:
        final previousMonth = DateTime(currentPeriod.startDate.year, currentPeriod.startDate.month - 1, 1);
        return _getMonthlyPeriodInfo(previousMonth);
      case PeriodType.yearly:
        final previousYear = DateTime(currentPeriod.startDate.year - 1, 1, 1);
        return _getYearlyPeriodInfo(previousYear);
    }
  }
  
  /// 次の期間情報を取得
  static PeriodInfo getNextPeriodInfo(PeriodInfo currentPeriod) {
    switch (currentPeriod.periodType) {
      case PeriodType.weekly:
        final nextWeek = currentPeriod.startDate.add(const Duration(days: 7));
        return _getWeeklyPeriodInfo(nextWeek);
      case PeriodType.monthly:
        final nextMonth = DateTime(currentPeriod.startDate.year, currentPeriod.startDate.month + 1, 1);
        return _getMonthlyPeriodInfo(nextMonth);
      case PeriodType.yearly:
        final nextYear = DateTime(currentPeriod.startDate.year + 1, 1, 1);
        return _getYearlyPeriodInfo(nextYear);
    }
  }
  
  /// 指定した日にメモがあるかチェック
  static bool hasActivityOnDate(Map<DateTime, int> dailyCount, DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day);
    return dailyCount.containsKey(dateKey) && (dailyCount[dateKey] ?? 0) > 0;
  }
  
  /// 指定した日のメモ数を取得
  static int getActivityCountOnDate(Map<DateTime, int> dailyCount, DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day);
    return dailyCount[dateKey] ?? 0;
  }
  
  /// 指定した日の趣味リストを取得
  static List<String> getHobbiesOnDate(Map<DateTime, List<String>> dailyHobbies, DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day);
    return dailyHobbies[dateKey] ?? [];
  }
  
  /// 趣味名から一意の色を生成
  static Color getHobbyColor(String hobbyName) {
    // 趣味名のハッシュ値から色を生成
    final hash = hobbyName.hashCode;
    final random = Random(hash);
    
    // HSV色空間で鮮やかな色を生成
    final hue = random.nextDouble() * 360;
    const saturation = 0.7; // 彩度は一定
    const value = 0.8; // 明度は一定
    
    return HSVColor.fromAHSV(1.0, hue, saturation, value).toColor();
  }
  
  /// 複数の趣味から代表色を生成（グラデーション風）
  static Color getMixedHobbyColor(List<String> hobbyNames) {
    if (hobbyNames.isEmpty) return Colors.grey;
    if (hobbyNames.length == 1) return getHobbyColor(hobbyNames.first);
    
    // 複数の趣味がある場合は最初の趣味の色をベースにする
    return getHobbyColor(hobbyNames.first);
  }
}