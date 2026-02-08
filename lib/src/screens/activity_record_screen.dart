import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/category_provider.dart';
import '../providers/activity_record_provider.dart';
import '../providers/premium_provider.dart';
import '../services/activity_record_service.dart';

/// 活動記録専用画面
/// 全カテゴリーの活動記録を表示
class ActivityRecordScreen extends ConsumerStatefulWidget {
  const ActivityRecordScreen({super.key});

  @override
  ConsumerState<ActivityRecordScreen> createState() => _ActivityRecordScreenState();
}

class _ActivityRecordScreenState extends ConsumerState<ActivityRecordScreen> {
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryListProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '活動記録',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // 区切り線
          Container(
            height: 1,
            color: Colors.grey[200],
          ),

          // カテゴリー選択ドロップダウン
          Container(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: InputDecoration(
                labelText: 'カテゴリーを選択',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('すべて'),
                ),
                ...categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category.id,
                    child: Text(category.name),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
                // カテゴリーIDを活動記録プロバイダーに設定
                if (value != null) {
                  ref.read(activityRecordProvider.notifier).changeCategoryId(value);
                }
              },
            ),
          ),

          // 期間セレクターヘッダー
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildPeriodSelectorHeader(),
          ),

          const SizedBox(height: 16),

          // 活動記録の内容エリア
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildActivityRecordContent(),
            ),
          ),
        ],
      ),
    );
  }

  /// 活動記録コンテンツを構築
  Widget _buildActivityRecordContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // カレンダー表示カード
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _buildActivityCalendarCard(),
        ),

        // 統計情報カード
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _buildActivityStatisticsCard(),
        ),

        // メモ一覧カード
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _buildRecentMemosCard(),
        ),
      ],
    );
  }

  /// ヘッダー用の簡潔な期間選択を構築
  Widget _buildPeriodSelectorHeader() {
    final periodType = ref.watch(activityPeriodTypeProvider);
    final periodInfo = ref.watch(activityPeriodInfoProvider);

    return GestureDetector(
      // 左右フリック操作で期間移動
      onPanEnd: (details) {
        const sensitivity = 50.0; // フリック感度

        // 横フリック: 期間移動
        if (details.velocity.pixelsPerSecond.dx.abs() > sensitivity) {
          final currentPeriod = ref.read(activityPeriodInfoProvider);
          final isPremium = ref.read(premiumProvider);

          if (details.velocity.pixelsPerSecond.dx > sensitivity) {
            // 右フリック: 前の期間
            final previousPeriod = ActivityRecordService.getPreviousPeriodInfo(currentPeriod);
            final canGoPrevious = isPremium || ActivityRecordService.hasVisiblePortionInFreeTier(previousPeriod);
            if (canGoPrevious) {
              _goToPreviousPeriod();
            }
          } else if (details.velocity.pixelsPerSecond.dx < -sensitivity) {
            // 左フリック: 次の期間
            final nextPeriod = ActivityRecordService.getNextPeriodInfo(currentPeriod);
            final isNotFuture = !nextPeriod.startDate.isAfter(DateTime.now());
            final isAccessible = isPremium || ActivityRecordService.hasVisiblePortionInFreeTier(nextPeriod);
            final canGoNext = isNotFuture && isAccessible;
            if (canGoNext) {
              _goToNextPeriod();
            }
          }
        }
      },
      child: Material(
        elevation: 2.0,
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 期間タイプ選択ボタン
              GestureDetector(
                onTap: () => _showPeriodTypeSelector(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getPeriodTypeIcon(periodType),
                      color: Theme.of(context).colorScheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      periodType.displayName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                  ],
                ),
              ),

              // 期間ナビゲーション
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 前の期間ボタン
                  Consumer(
                    builder: (context, ref, child) {
                      final currentPeriod = ref.watch(activityPeriodInfoProvider);
                      final previousPeriod = ActivityRecordService.getPreviousPeriodInfo(currentPeriod);
                      final isPremium = ref.watch(premiumProvider);
                      final canGoPrevious = isPremium || ActivityRecordService.hasVisiblePortionInFreeTier(previousPeriod);

                      return GestureDetector(
                        onTap: canGoPrevious ? () {
                          _goToPreviousPeriod();
                        } : null,
                        child: Icon(
                          Icons.chevron_left,
                          color: canGoPrevious ? Colors.grey[600] : Colors.grey[300],
                          size: 18,
                        ),
                      );
                    },
                  ),

                  const SizedBox(width: 8),

                  // 現在の期間
                  Flexible(
                    child: Text(
                      periodInfo.displayTitle,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 次の期間ボタン
                  Consumer(
                    builder: (context, ref, child) {
                      final currentPeriod = ref.watch(activityPeriodInfoProvider);
                      final nextPeriod = ActivityRecordService.getNextPeriodInfo(currentPeriod);
                      final isPremium = ref.watch(premiumProvider);
                      final isNotFuture = !nextPeriod.startDate.isAfter(DateTime.now());
                      final isAccessible = isPremium || ActivityRecordService.hasVisiblePortionInFreeTier(nextPeriod);
                      final canGoNext = isNotFuture && isAccessible;

                      return GestureDetector(
                        onTap: canGoNext ? () {
                          _goToNextPeriod();
                        } : null,
                        child: Icon(
                          Icons.chevron_right,
                          color: canGoNext ? Colors.grey[600] : Colors.grey[300],
                          size: 18,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 期間タイプ選択ボトムシートを表示
  void _showPeriodTypeSelector() {
    final currentPeriodType = ref.read(activityPeriodTypeProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ハンドルバー
              Container(
                margin: const EdgeInsets.only(top: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // タイトル
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '期間タイプを選択',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              // 期間タイプ選択肢
              ...PeriodType.values.map((type) {
                final isSelected = type == currentPeriodType;
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getPeriodTypeIcon(type),
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[600],
                      size: 20,
                    ),
                  ),
                  title: Text(
                    type.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    _getPeriodTypeDescription(type),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        )
                      : null,
                  onTap: () {
                    ref.read(activityRecordProvider.notifier).changePeriodType(type);
                    Navigator.pop(context);
                  },
                );
              }).toList(),

              // 下部の余白
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  /// 期間タイプのアイコンを取得
  IconData _getPeriodTypeIcon(PeriodType type) {
    switch (type) {
      case PeriodType.biweekly:
        return Icons.date_range;
      case PeriodType.monthly:
        return Icons.calendar_view_month;
      case PeriodType.yearly:
        return Icons.calendar_month;
    }
  }

  /// 期間タイプの説明文を取得
  String _getPeriodTypeDescription(PeriodType type) {
    switch (type) {
      case PeriodType.biweekly:
        return '2週間の活動を表示';
      case PeriodType.monthly:
        return '1ヶ月の活動を表示';
      case PeriodType.yearly:
        return '1年間の活動を表示';
    }
  }

  /// 活動統計カードを構築
  Widget _buildActivityStatisticsCard() {
    final categoryId = ref.watch(activityCategoryIdProvider);
    final statisticsAsync = ref.watch(activityStatisticsProvider(categoryId));

    return statisticsAsync.when(
      data: (statistics) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '統計情報',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 12),

          // サマリー統計
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.edit_note,
                  title: 'メモ数',
                  value: '${statistics.totalMemos}件',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.calendar_today,
                  title: '活動日数',
                  value: '${statistics.totalActiveDays}日',
                  color: Colors.green,
                ),
              ),
            ],
          ),

          if (statistics.hobbyActivityCount.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '趣味別活動',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            ...statistics.hobbyActivityCount.entries.take(5).map((entry) =>
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    // 趣味の色インジケーター
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: ActivityRecordService.getHobbyColor(entry.key),
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(
                          color: ActivityRecordService.getHobbyColor(entry.key).withOpacity(0.3),
                          width: 0.5,
                        ),
                      ),
                    ),
                    // 趣味名
                    Expanded(
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // 活動回数
                    Text(
                      '${entry.value}件',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Center(
        child: Text(
          'データの読み込みに失敗しました',
          style: TextStyle(
            color: Colors.red[600],
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  /// 統計カードを構築
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withOpacity(0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 活動カレンダーカードを構築
  Widget _buildActivityCalendarCard() {
    final periodType = ref.watch(activityPeriodTypeProvider);
    final categoryId = ref.watch(activityCategoryIdProvider);
    final statisticsAsync = ref.watch(activityStatisticsProvider(categoryId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              '活動記録',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 期間タイプに応じたカレンダー表示
        statisticsAsync.when(
          data: (statistics) {
            switch (periodType) {
              case PeriodType.biweekly:
                return _buildBiweeklyCalendar(statistics);
              case PeriodType.monthly:
                return _buildMonthlyCalendar(statistics);
              case PeriodType.yearly:
                return _buildYearlyCalendar(statistics);
            }
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => Center(
            child: Text(
              'カレンダーの読み込みに失敗しました',
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 2週間カレンダーを構築
  Widget _buildBiweeklyCalendar(ActivityStatistics statistics) {
    final periodInfo = ref.watch(activityPeriodInfoProvider);
    final isPremium = ref.watch(premiumProvider);
    final weekDays = ['月', '火', '水', '木', '金', '土', '日'];

    return Column(
      children: [
        // 曜日ヘッダー
        Row(
          children: weekDays.map((day) => Expanded(
            child: Text(
              day,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          )).toList(),
        ),

        const SizedBox(height: 8),

        // 1週目の日付（通常順序）
        Row(
          children: List.generate(7, (index) {
            final date = periodInfo.startDate.add(Duration(days: index)); // 1週目
            final hasActivity = ActivityRecordService.hasActivityOnDate(statistics.dailyCount, date);
            final hobbiesOnDate = ActivityRecordService.getHobbiesOnDate(statistics.dailyHobbies, date);
            final hobbyColor = hasActivity
                ? ActivityRecordService.getMixedHobbyColor(hobbiesOnDate)
                : Colors.grey[300]!;

            // 無料版制限チェック
            final isDateAvailable = isPremium || ActivityRecordService.isDateAvailableInFreeTier(date);
            final isFutureDate = ActivityRecordService.isDateInFuture(date);

            return Expanded(
              child: Container(
                height: 36,
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: isFutureDate
                      ? Colors.blue[50]
                      : !isDateAvailable
                          ? Colors.grey[100]
                          : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: isFutureDate
                      ? Border.all(color: Colors.blue[300]!, width: 2.0)
                      : !isDateAvailable
                          ? Border.all(color: Colors.grey[300]!, width: 1.0)
                          : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.normal,
                        fontStyle: isFutureDate ? FontStyle.italic : FontStyle.normal,
                        color: isFutureDate
                            ? Colors.blue[600]
                            : !isDateAvailable
                                ? Colors.grey[400]
                                : Colors.grey[600],
                      ),
                    ),
                    if (hasActivity && hobbiesOnDate.length > 1 && isDateAvailable && !isFutureDate)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: hobbiesOnDate.take(5).map((hobby) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: BoxDecoration(
                            color: ActivityRecordService.getHobbyColor(hobby),
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        )).toList(),
                      )
                    else if (hasActivity && isDateAvailable && !isFutureDate)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: hobbyColor,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 4),

        // 2週目の日付（通常順序）
        Row(
          children: List.generate(7, (index) {
            final date = periodInfo.startDate.add(Duration(days: index + 7)); // 2週目
            final hasActivity = ActivityRecordService.hasActivityOnDate(statistics.dailyCount, date);
            final hobbiesOnDate = ActivityRecordService.getHobbiesOnDate(statistics.dailyHobbies, date);
            final hobbyColor = hasActivity
                ? ActivityRecordService.getMixedHobbyColor(hobbiesOnDate)
                : Colors.grey[300]!;

            // 無料版制限チェック
            final isDateAvailable = isPremium || ActivityRecordService.isDateAvailableInFreeTier(date);
            final isFutureDate = ActivityRecordService.isDateInFuture(date);

            return Expanded(
              child: Container(
                height: 36,
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: isFutureDate
                      ? Colors.blue[50]
                      : !isDateAvailable
                          ? Colors.grey[100]
                          : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: isFutureDate
                      ? Border.all(color: Colors.blue[300]!, width: 2.0)
                      : !isDateAvailable
                          ? Border.all(color: Colors.grey[300]!, width: 1.0)
                          : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.normal,
                        fontStyle: isFutureDate ? FontStyle.italic : FontStyle.normal,
                        color: isFutureDate
                            ? Colors.blue[600]
                            : !isDateAvailable
                                ? Colors.grey[400]
                                : Colors.grey[600],
                      ),
                    ),
                    if (hasActivity && hobbiesOnDate.length > 1 && isDateAvailable && !isFutureDate)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: hobbiesOnDate.take(5).map((hobby) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: BoxDecoration(
                            color: ActivityRecordService.getHobbyColor(hobby),
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        )).toList(),
                      )
                    else if (hasActivity && isDateAvailable && !isFutureDate)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: hobbyColor,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ),

        // 色凡例を表示（趣味がある場合のみ）
        if (statistics.hobbyActivityCount.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildColorLegend(statistics),
        ],
      ],
    );
  }

  /// 月間カレンダーを構築
  Widget _buildMonthlyCalendar(ActivityStatistics statistics) {
    final periodInfo = ref.watch(activityPeriodInfoProvider);
    final firstDayOfMonth = DateTime(periodInfo.startDate.year, periodInfo.startDate.month, 1);
    final lastDayOfMonth = DateTime(periodInfo.startDate.year, periodInfo.startDate.month + 1, 0);
    final startOfCalendar = firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday - 1));
    final isPremium = ref.watch(premiumProvider);

    final weekDays = ['月', '火', '水', '木', '金', '土', '日'];

    return Column(
      children: [
        // 曜日ヘッダー
        Row(
          children: weekDays.map((day) => Expanded(
            child: Text(
              day,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          )).toList(),
        ),

        const SizedBox(height: 8),

        // カレンダーグリッド（最大6週間）
        ...List.generate(6, (weekIndex) {
          final weekStart = startOfCalendar.add(Duration(days: weekIndex * 7));

          // この週に当月の日付が含まれているかチェック
          if (weekStart.isAfter(lastDayOfMonth)) {
            return const SizedBox.shrink();
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: List.generate(7, (dayIndex) {
                final date = weekStart.add(Duration(days: dayIndex));
                final isCurrentMonth = date.month == firstDayOfMonth.month;
                final hasActivity = ActivityRecordService.hasActivityOnDate(statistics.dailyCount, date);
                final hobbiesOnDate = ActivityRecordService.getHobbiesOnDate(statistics.dailyHobbies, date);
                final hobbyColor = hasActivity
                    ? ActivityRecordService.getMixedHobbyColor(hobbiesOnDate)
                    : Colors.grey[300]!;

                // 無料版制限チェック
                final isDateAvailable = isPremium || ActivityRecordService.isDateAvailableInFreeTier(date);
                final isFutureDate = ActivityRecordService.isDateInFuture(date);

                return Expanded(
                  child: Container(
                    height: 28,
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: !isCurrentMonth
                          ? Colors.transparent
                          : isFutureDate
                              ? Colors.blue[50]
                              : !isDateAvailable
                                  ? Colors.grey[100]
                                  : Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: isCurrentMonth ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.normal,
                              fontStyle: isFutureDate ? FontStyle.italic : FontStyle.normal,
                              color: isFutureDate
                                  ? Colors.blue[600]
                                  : !isDateAvailable
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                            ),
                          ),
                          if (hasActivity && hobbiesOnDate.length > 1 && isDateAvailable && !isFutureDate)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: hobbiesOnDate.take(5).map((hobby) => Container(
                                width: 7,
                                height: 7,
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                decoration: BoxDecoration(
                                  color: ActivityRecordService.getHobbyColor(hobby),
                                  borderRadius: BorderRadius.circular(2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              )).toList(),
                            )
                          else if (hasActivity && isDateAvailable && !isFutureDate)
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: hobbyColor,
                                borderRadius: BorderRadius.circular(2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ) : null,
                  ),
                );
              }),
            ),
          );
        }),

        // 色凡例を表示（趣味がある場合のみ）
        if (statistics.hobbyActivityCount.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildColorLegend(statistics),
        ],
      ],
    );
  }

  /// 年間カレンダーを構築（簡易版）
  Widget _buildYearlyCalendar(ActivityStatistics statistics) {
    final periodInfo = ref.watch(activityPeriodInfoProvider);
    final year = periodInfo.startDate.year;
    final isPremium = ref.watch(premiumProvider);

    return Column(
      children: [
        // 無料版制限の注意書き
        if (!isPremium) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!, width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.orange[700],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '無料版では過去2週間のデータのみ表示されています',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        // 月別サマリー
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 1.2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: 12,
          itemBuilder: (context, index) {
            final month = index + 1; // 1月から12月の順に表示

            // その月のアクティビティ数と趣味を計算
            final monthActivityCount = statistics.dailyCount.entries
                .where((entry) =>
                    entry.key.year == year &&
                    entry.key.month == month)
                .fold(0, (sum, entry) => sum + entry.value);

            final monthHobbies = statistics.dailyHobbies.entries
                .where((entry) =>
                    entry.key.year == year &&
                    entry.key.month == month)
                .expand((entry) => entry.value)
                .toSet()
                .toList();

            final hasActivity = monthActivityCount > 0;
            final monthColor = hasActivity
                ? ActivityRecordService.getMixedHobbyColor(monthHobbies)
                : Colors.grey[300]!;

            // 月全体の制限状況をチェック
            final monthPeriod = ActivityRecordService.getCurrentPeriodInfo(PeriodType.monthly, DateTime(year, month, 1));
            final isMonthAvailable = isPremium || ActivityRecordService.hasVisiblePortionInFreeTier(monthPeriod);
            final isMonthFuture = monthPeriod.startDate.isAfter(DateTime.now());

            return Container(
              decoration: BoxDecoration(
                color: isMonthFuture
                    ? Colors.blue[50]
                    : !isMonthAvailable
                        ? Colors.grey[100]
                        : Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '${month}月',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.normal,
                          color: isMonthFuture
                              ? Colors.blue[700]
                              : !isMonthAvailable
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  if (hasActivity && monthHobbies.length > 1 && isMonthAvailable && !isMonthFuture)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: monthHobbies.take(5).map((hobby) => Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: ActivityRecordService.getHobbyColor(hobby),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 1.5,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      )).toList(),
                    )
                  else if (hasActivity && isMonthAvailable && !isMonthFuture)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: monthColor,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 1.5,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),

        // 色凡例を表示（趣味がある場合のみ）
        if (statistics.hobbyActivityCount.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildColorLegend(statistics),
        ],
      ],
    );
  }

  /// 色凡例を構築
  Widget _buildColorLegend(ActivityStatistics statistics) {
    final sortedHobbies = statistics.hobbyActivityCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '色の説明',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: sortedHobbies.map((entry) {
            final hobbyColor = ActivityRecordService.getHobbyColor(entry.key);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: hobbyColor,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 1,
                          offset: const Offset(0, 0.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 最近のメモカードを構築
  Widget _buildRecentMemosCard() {
    final categoryId = ref.watch(activityCategoryIdProvider);
    final statisticsAsync = ref.watch(activityStatisticsProvider(categoryId));
    final periodType = ref.watch(activityPeriodTypeProvider);

    // 期間タイプに応じたタイトル
    String getPeriodTitle() {
      switch (periodType) {
        case PeriodType.biweekly:
          return 'この2週間のメモ';
        case PeriodType.monthly:
          return 'この月のメモ';
        case PeriodType.yearly:
          return 'この年のメモ';
      }
    }

    return statisticsAsync.when(
      data: (statistics) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            getPeriodTitle(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 12),

          if (statistics.recentMemos.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'この期間にはメモがありません',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
            )
          else
            ...statistics.recentMemos.take(5).map((memo) =>
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memo.content,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${memo.createdAt.month}/${memo.createdAt.day} ${memo.createdAt.hour}:${memo.createdAt.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Center(
        child: Text(
          'メモの読み込みに失敗しました',
          style: TextStyle(
            color: Colors.red[600],
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  /// 前の期間に移動
  void _goToPreviousPeriod() {
    final currentPeriod = ref.read(activityPeriodInfoProvider);
    final previousPeriod = ActivityRecordService.getPreviousPeriodInfo(currentPeriod);

    // 基準日を更新（プロバイダーが自動的に再計算される）
    ref.read(activityBaseDateProvider.notifier).state = previousPeriod.startDate;
  }

  /// 次の期間に移動
  void _goToNextPeriod() {
    final currentPeriod = ref.read(activityPeriodInfoProvider);
    final nextPeriod = ActivityRecordService.getNextPeriodInfo(currentPeriod);
    final isPremium = ref.read(premiumProvider);

    // 未来の期間への移動を制限
    final today = DateTime.now();
    if (nextPeriod.startDate.isAfter(today)) {
      return; // 未来の期間には移動しない
    }

    // 無料版ユーザーの場合、閲覧不可能な期間への移動を制限
    if (!isPremium && !ActivityRecordService.hasVisiblePortionInFreeTier(nextPeriod)) {
      return; // 閲覧不可能な期間には移動しない
    }

    // 基準日を更新（プロバイダーが自動的に再計算される）
    ref.read(activityBaseDateProvider.notifier).state = nextPeriod.startDate;
  }
}
