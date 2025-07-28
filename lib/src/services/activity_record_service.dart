import 'dart:math';
import 'package:flutter/material.dart';
import '../models/hobby.dart';
import '../models/hobby_memo.dart';
import 'memo_service.dart';

/// 期間選択の種類
enum PeriodType {
  biweekly('2週間'),
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
    bool isPremium = false,
  }) async {
    try {
      // カテゴリに属する趣味を取得
      final categoryHobbies = _filterHobbiesByCategory(hobbies, categoryId);
      
      // 無料版の場合は期間制限を適用
      final effectivePeriodInfo = isPremium ? periodInfo : _applyFreeTierLimit(periodInfo);
      
      // 期間内の全メモを取得
      final allMemos = <HobbyMemo>[];
      for (final hobby in categoryHobbies) {
        final hobbyMemos = await MemoService.loadMemosForHobby(hobby.id);
        final periodMemos = _filterMemosByPeriod(hobbyMemos, effectivePeriodInfo);
        allMemos.addAll(periodMemos);
      }
      
      // 統計情報を計算
      final statistics = _calculateStatistics(allMemos, categoryHobbies);
      
      return statistics;
      
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
      // 期間開始日以降かつ期間終了日以前かをチェック（境界値を含む）
      final startCheck = !memoDate.isBefore(periodInfo.startDate);
      final endCheck = !memoDate.isAfter(periodInfo.endDate);
      return startCheck && endCheck;
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
      case PeriodType.biweekly:
        return _getBiweeklyPeriodInfo(now);
      case PeriodType.monthly:
        return _getMonthlyPeriodInfo(now);
      case PeriodType.yearly:
        return _getYearlyPeriodInfo(now);
    }
  }
  
  /// 2週間期間情報を取得
  static PeriodInfo _getBiweeklyPeriodInfo(DateTime baseDate) {
    // 2週間の開始を月曜日に設定
    final weekday = baseDate.weekday;
    final startOfWeek = baseDate.subtract(Duration(days: weekday - 1));
    final endOfBiweek = startOfWeek.add(const Duration(days: 13)); // 2週間 = 14日間
    
    return PeriodInfo(
      startDate: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
      endDate: DateTime(endOfBiweek.year, endOfBiweek.month, endOfBiweek.day, 23, 59, 59, 999),
      periodType: PeriodType.biweekly,
      displayTitle: '${startOfWeek.year} ${startOfWeek.month}/${startOfWeek.day}-${endOfBiweek.month}/${endOfBiweek.day}',
    );
  }
  
  /// 月間期間情報を取得
  static PeriodInfo _getMonthlyPeriodInfo(DateTime baseDate) {
    final startOfMonth = DateTime(baseDate.year, baseDate.month, 1);
    final endOfMonth = DateTime(baseDate.year, baseDate.month + 1, 0, 23, 59, 59, 999);
    
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
    final endOfYear = DateTime(baseDate.year, 12, 31, 23, 59, 59, 999);
    
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
      case PeriodType.biweekly:
        final previousBiweek = currentPeriod.startDate.subtract(const Duration(days: 14));
        return _getBiweeklyPeriodInfo(previousBiweek);
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
      case PeriodType.biweekly:
        final nextBiweek = currentPeriod.startDate.add(const Duration(days: 14));
        return _getBiweeklyPeriodInfo(nextBiweek);
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
  
  /// 無料版の期間制限を適用（過去2週間まで）
  static PeriodInfo _applyFreeTierLimit(PeriodInfo originalPeriod) {
    final now = DateTime.now();
    final twoWeeksAgo = now.subtract(const Duration(days: 14));
    
    // 期間の開始日が2週間より古い場合は制限を適用
    if (originalPeriod.startDate.isBefore(twoWeeksAgo)) {
      return PeriodInfo(
        startDate: twoWeeksAgo,
        endDate: originalPeriod.endDate,
        periodType: originalPeriod.periodType,
        displayTitle: originalPeriod.displayTitle,
      );
    }
    
    return originalPeriod;
  }
  
  /// 指定期間が無料版制限内かチェック
  static bool isPeriodAvailableInFreeTier(PeriodInfo period) {
    final now = DateTime.now();
    final twoWeeksAgo = now.subtract(const Duration(days: 14));
    
    return !period.startDate.isBefore(twoWeeksAgo);
  }
  
  /// 指定期間タイプが無料版で利用可能かチェック（一部でも表示可能期間が含まれているか）
  static bool isPeriodTypeAvailableInFreeTier(PeriodType periodType) {
    final now = DateTime.now();
    final twoWeeksAgo = now.subtract(const Duration(days: 14));
    
    // 今日を含む期間を作成
    final todayPeriod = getCurrentPeriodInfo(periodType, now);
    
    // 期間の終了日が2週間制限より新しければ、一部でも表示可能
    return !todayPeriod.endDate.isBefore(twoWeeksAgo);
  }
  
  /// 指定期間に表示可能な部分があるかチェック（無料版制限を考慮）
  static bool hasVisiblePortionInFreeTier(PeriodInfo period) {
    final now = DateTime.now();
    final twoWeeksAgo = now.subtract(const Duration(days: 14));
    
    // 期間の終了日が2週間制限より新しければ、一部でも表示可能
    return !period.endDate.isBefore(twoWeeksAgo);
  }
  
  /// 指定期間の制限状況を取得（年間カレンダー用）
  static FreeTierRestrictionStatus getFreeTierRestrictionStatus(PeriodInfo period) {
    final now = DateTime.now();
    final twoWeeksAgo = now.subtract(const Duration(days: 14));
    
    final startAvailable = !period.startDate.isBefore(twoWeeksAgo);
    final endAvailable = !period.endDate.isBefore(twoWeeksAgo);
    
    if (startAvailable && endAvailable) {
      return FreeTierRestrictionStatus.fullyAvailable;
    } else if (endAvailable) {
      return FreeTierRestrictionStatus.partiallyAvailable;
    } else {
      return FreeTierRestrictionStatus.fullyRestricted;
    }
  }
  
  /// 指定日付が無料版制限内かチェック
  static bool isDateAvailableInFreeTier(DateTime date) {
    final now = DateTime.now();
    final twoWeeksAgo = now.subtract(const Duration(days: 14));
    
    return !date.isBefore(twoWeeksAgo);
  }
  
  /// 指定日付が未来の日付かチェック
  static bool isDateInFuture(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    
    return targetDate.isAfter(today);
  }
}

/// 無料版制限の状況
enum FreeTierRestrictionStatus {
  fullyAvailable,     // 全期間利用可能
  partiallyAvailable, // 一部期間のみ利用可能
  fullyRestricted,    // 全期間制限
}