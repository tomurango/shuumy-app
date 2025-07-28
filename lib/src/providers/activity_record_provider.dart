import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/activity_record_service.dart';
import 'hobby_list_provider.dart';
import 'premium_provider.dart';

/// 活動記録の期間選択プロバイダー
final activityPeriodTypeProvider = StateProvider<PeriodType>((ref) => PeriodType.biweekly);

/// 活動記録の基準日プロバイダー
final activityBaseDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// 活動記録の期間情報プロバイダー
final activityPeriodInfoProvider = Provider<PeriodInfo>((ref) {
  final periodType = ref.watch(activityPeriodTypeProvider);
  final baseDate = ref.watch(activityBaseDateProvider);
  return ActivityRecordService.getCurrentPeriodInfo(periodType, baseDate);
});

/// 活動記録のカテゴリIDプロバイダー
final activityCategoryIdProvider = StateProvider<String>((ref) => 'default_all');

/// 活動統計データプロバイダー
final activityStatisticsProvider = FutureProvider.family<ActivityStatistics, String>((ref, categoryId) async {
  final periodInfo = ref.watch(activityPeriodInfoProvider);
  final hobbies = ref.watch(hobbyListProvider);
  final isPremium = ref.watch(premiumProvider);
  
  return await ActivityRecordService.getActivityStatistics(
    categoryId: categoryId,
    periodInfo: periodInfo,
    hobbies: hobbies,
    isPremium: isPremium,
  );
});

/// 活動記録の状態管理クラス
class ActivityRecordNotifier extends StateNotifier<AsyncValue<ActivityStatistics>> {
  final Ref ref;
  
  ActivityRecordNotifier(this.ref) : super(const AsyncValue.loading());
  
  /// 統計データを読み込み
  Future<void> loadStatistics(String categoryId) async {
    state = const AsyncValue.loading();
    
    try {
      final periodInfo = ref.read(activityPeriodInfoProvider);
      final hobbies = ref.read(hobbyListProvider);
      final isPremium = ref.read(premiumProvider);
      
      final statistics = await ActivityRecordService.getActivityStatistics(
        categoryId: categoryId,
        periodInfo: periodInfo,
        hobbies: hobbies,
        isPremium: isPremium,
      );
      
      state = AsyncValue.data(statistics);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
  
  /// 期間タイプを変更
  void changePeriodType(PeriodType newPeriodType) {
    ref.read(activityPeriodTypeProvider.notifier).state = newPeriodType;
    // 期間が変わったら統計データを再読み込み
    final categoryId = ref.read(activityCategoryIdProvider);
    loadStatistics(categoryId);
  }
  
  /// 前の期間に移動
  void goToPreviousPeriod() {
    final currentPeriod = ref.read(activityPeriodInfoProvider);
    final previousPeriod = ActivityRecordService.getPreviousPeriodInfo(currentPeriod);
    
    // 基準日を更新して期間情報を更新
    _updateBaseDateAndReload(previousPeriod.startDate);
  }
  
  /// 次の期間に移動
  void goToNextPeriod() {
    final currentPeriod = ref.read(activityPeriodInfoProvider);
    final nextPeriod = ActivityRecordService.getNextPeriodInfo(currentPeriod);
    
    // 未来の期間への移動を制限
    final today = DateTime.now();
    if (nextPeriod.startDate.isAfter(today)) {
      return; // 未来の期間には移動しない
    }
    
    // 基準日を更新して期間情報を更新
    _updateBaseDateAndReload(nextPeriod.startDate);
  }
  
  /// 基準日を更新して統計データを再読み込み
  void _updateBaseDateAndReload(DateTime newBaseDate) {
    // 基準日を更新（FutureProvider.familyが自動的に再計算される）
    ref.read(activityBaseDateProvider.notifier).state = newBaseDate;
    
    // 統計データを再読み込み
    final categoryId = ref.read(activityCategoryIdProvider);
    loadStatistics(categoryId);
  }
  
  /// カテゴリを変更
  void changeCategoryId(String newCategoryId) {
    ref.read(activityCategoryIdProvider.notifier).state = newCategoryId;
    loadStatistics(newCategoryId);
  }
  
  /// データを再読み込み
  void reload() {
    final categoryId = ref.read(activityCategoryIdProvider);
    loadStatistics(categoryId);
  }
}

/// 活動記録の状態管理プロバイダー
final activityRecordProvider = StateNotifierProvider<ActivityRecordNotifier, AsyncValue<ActivityStatistics>>((ref) {
  return ActivityRecordNotifier(ref);
});

/// 現在の期間情報の表示用プロバイダー
final currentPeriodDisplayProvider = Provider<String>((ref) {
  final periodInfo = ref.watch(activityPeriodInfoProvider);
  return periodInfo.displayTitle;
});

/// カレンダー表示用の日別活動データプロバイダー
final dailyActivityProvider = Provider.family<int, DateTime>((ref, date) {
  final statisticsAsync = ref.watch(activityRecordProvider);
  
  return statisticsAsync.when(
    data: (statistics) => ActivityRecordService.getActivityCountOnDate(statistics.dailyCount, date),
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// 指定日に活動があるかチェックするプロバイダー
final hasActivityProvider = Provider.family<bool, DateTime>((ref, date) {
  final statisticsAsync = ref.watch(activityRecordProvider);
  
  return statisticsAsync.when(
    data: (statistics) => ActivityRecordService.hasActivityOnDate(statistics.dailyCount, date),
    loading: () => false,
    error: (_, __) => false,
  );
});