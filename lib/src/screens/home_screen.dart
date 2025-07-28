import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../models/hobby.dart';
import '../models/category.dart';
import '../providers/hobby_list_provider.dart';
import '../providers/category_provider.dart';
import '../providers/activity_record_provider.dart';
import '../providers/premium_provider.dart';
import '../services/background_image_service.dart';
import '../services/category_service.dart';
import '../services/memo_service.dart';
import '../services/activity_record_service.dart';
import 'premium_plan_selection_screen.dart';
import 'add_hobby_screen.dart';
import 'edit_hobby_screen.dart';
import 'detail_hobby_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  late PageController _pageController;
  TabController? _tabController;
  int _currentPageIndex = 0;
  bool _isBackgroundViewMode = false;
  bool _isReorderMode = false;
  bool _isActivityRecordMode = false;
  bool _showCalendarContent = false; // カレンダーコンテンツの表示制御
  bool _hideHobbyCards = false; // 趣味カードの非表示制御
 // ツールバーの表示制御
  late AnimationController _shakeController;
  late AnimationController _transitionController;
  late AnimationController _toolbarController;
  Map<String, ScrollController> _scrollControllers = {};
  Map<String, bool> _showTopShadow = {};
  bool _isSnackBarShowing = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _toolbarController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // ツールバーの初期状態を設定（値を1.0に設定して画面に表示）
    _toolbarController.value = 1.0;
  }

  ScrollController _getScrollController(String categoryId) {
    if (!_scrollControllers.containsKey(categoryId)) {
      final controller = ScrollController();
      controller.addListener(() => _onScroll(categoryId));
      _scrollControllers[categoryId] = controller;
      _showTopShadow[categoryId] = false;
    }
    return _scrollControllers[categoryId]!;
  }

  void _onScroll(String categoryId) {
    final controller = _scrollControllers[categoryId];
    if (controller == null) return;
    
    final bool shouldShowShadow = controller.hasClients && controller.offset > 10;
    if (shouldShowShadow != (_showTopShadow[categoryId] ?? false)) {
      setState(() {
        _showTopShadow[categoryId] = shouldShowShadow;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController?.dispose();
    _shakeController.dispose();
    _transitionController.dispose();
    _toolbarController.dispose();
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// 並び替えモードの切り替え
  void _toggleReorderMode() {
    setState(() {
      _isReorderMode = !_isReorderMode;
    });
    
    if (_isReorderMode) {
      // 震えアニメーションを開始
      _shakeController.repeat();
    } else {
      // アニメーションを停止
      _shakeController.stop();
      _shakeController.reset();
    }
  }

  /// 並び替えモードを終了
  void _exitReorderMode() {
    setState(() {
      _isReorderMode = false;
    });
    _shakeController.stop();
    _shakeController.reset();
  }

  /// 活動記録モードの切り替え
  void _toggleActivityRecordMode() async {
    if (_isActivityRecordMode) {
      await _exitActivityRecordMode();
    } else {
      await _enterActivityRecordMode();
    }
  }

  /// 動的なスクロール量を計算（画面全体の高さ基準）
  double _calculateScrollAmount() {
    final screenHeight = MediaQuery.of(context).size.height;
    
    // 画面全体の高さ + 余裕分を空白の高さとして使用
    // これにより、趣味カードが確実に画面外に押し出される
    return screenHeight + 200.0; // 画面全体 + 余裕分
  }

  /// カレンダーコンテンツの高さを計算
  double _calculateCalendarContentHeight() {
    // カレンダーカード: height(150) + margin bottom(16)
    const calendarCardHeight = 150.0 + 16.0;
    
    // 活動一覧カード: height(150) + margin bottom(16)
    const activityCardHeight = 150.0 + 16.0;
    
    return calendarCardHeight + activityCardHeight;
  }

  /// ツールバーアニメーション（退場→登場）
  Future<void> _animateToolbarTransition() async {
    // 1. 現在のツールバーを下にスライドアウト
    await _toolbarController.reverse();
    
    // 2. 少し待機
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 3. モード切り替え
    setState(() {
      _isActivityRecordMode = !_isActivityRecordMode;
    });
    
    // 4. 新しいツールバーを下から上にスライドイン
    await _toolbarController.forward();
  }

  /// 活動記録モード開始（段階的アニメーション）
  Future<void> _enterActivityRecordMode() async {
    final categories = ref.read(categoryListProvider);
    if (categories.isEmpty || _currentPageIndex >= categories.length) {
      return;
    }
    
    final currentCategoryId = categories[_currentPageIndex].id;
    final scrollController = _getScrollController(currentCategoryId);
    final scrollAmount = _calculateScrollAmount();
    
    // ツールバーアニメーションとコンテンツアニメーションを並行実行
    final toolbarFuture = _animateToolbarTransition();
    final contentFuture = _executeContentAnimation(scrollController, scrollAmount);
    
    await Future.wait([toolbarFuture, contentFuture]);
  }

  /// コンテンツアニメーションを実行
  Future<void> _executeContentAnimation(ScrollController scrollController, double scrollAmount) async {
    // 段階1: 空白追加アニメーション (200ms)
    await _transitionController.animateTo(
      1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
    
    // 段階2: 自動スクロール (300ms)
    await scrollController.animateTo(
      scrollAmount,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    
    // 段階3: カレンダー領域を画面外に追加（事前にスクロール位置調整）
    final calendarHeight = _calculateCalendarContentHeight();
    final currentScrollPosition = scrollController.offset;
    
    // 先にスクロール位置をカレンダー分だけ下にずらして、画面外に追加されるように調整
    if (scrollController.hasClients) {
      scrollController.jumpTo(currentScrollPosition + calendarHeight);
    }
    
    // スクロール位置調整後にカレンダーを追加（これで画面外に追加される）
    setState(() {
      _showCalendarContent = true;
    });
    
    // 少し待機
    await Future.delayed(const Duration(milliseconds: 50));
    
    // 段階4: 趣味カード非表示 (200ms)
    setState(() {
      _hideHobbyCards = true;
    });
    // 段階5a: カレンダーを下まで自動スクロール (300ms)
    await Future.delayed(const Duration(milliseconds: 500));
    await scrollController.animateTo(
      0.0, // 最上部に戻る
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    
    // 段階5b: 空白領域を削除 (200ms)
    await _transitionController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  /// 活動記録モード終了
  Future<void> _exitActivityRecordMode() async {
    final categories = ref.read(categoryListProvider);
    
    // ツールバーアニメーションとコンテンツアニメーションを並行実行
    final toolbarFuture = _animateToolbarTransition();
    
    Future<void> contentFuture;
    if (categories.isNotEmpty && _currentPageIndex < categories.length) {
      final currentCategoryId = categories[_currentPageIndex].id;
      final scrollController = _getScrollController(currentCategoryId);
      contentFuture = _executeExitContentAnimation(scrollController);
    } else {
      contentFuture = _transitionController.reverse();
    }
    
    await Future.wait([toolbarFuture, contentFuture]);
    
    setState(() {
      _showCalendarContent = false;
      _hideHobbyCards = false;
    });
  }

  /// 終了時のコンテンツアニメーションを実行
  Future<void> _executeExitContentAnimation(ScrollController scrollController) async {
    // 1. 空白要素を追加（上向きに移動させる準備）
    await _transitionController.animateTo(1.0, duration: const Duration(milliseconds: 200));
    
    // 2. スクロールで上に移動（カレンダーを画面外に）
    final scrollAmount = _calculateScrollAmount();
    await scrollController.animateTo(
      scrollAmount,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    // 3. 趣味カードを表示
    setState(() {
      _hideHobbyCards = false;
    });
    
    await Future.delayed(const Duration(milliseconds: 200));
    
    // 4. カレンダーを削除（画面外なので見えない）
    setState(() {
      _showCalendarContent = false;
    });
    
    // 5. 最上部にスクロール戻し
    await scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    
    // 6. 空白要素を削除
    await _transitionController.animateTo(0.0, duration: const Duration(milliseconds: 200));
  }

  /// カテゴリー追加の誘導SnackBarを表示
  void _showCategoryAdditionGuidance() {
    if (_isSnackBarShowing) return;
    
    setState(() {
      _isSnackBarShowing = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('カテゴリーを追加するには設定画面をご利用ください'),
        backgroundColor: Colors.blue[600],
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: '設定画面へ',
          textColor: Colors.white,
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SettingsScreen(),
              ),
            );
            
            if (result == true) {
              ref.read(categoryListProvider.notifier).reload();
            }
          },
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ).closed.then((_) {
      // SnackBarが閉じられた時にフラグをリセット
      if (mounted) {
        setState(() {
          _isSnackBarShowing = false;
        });
      }
    });
  }

  /// カテゴリー別の背景画像を取得
  Future<ImageProvider?> _getCategoryBackgroundImage(Category category) async {
    try {
      if (category.backgroundImagePath != null) {
        final file = await CategoryService.getCategoryBackgroundFile(category.backgroundImagePath!);
        if (file != null) {
          return FileImage(file);
        }
      }
      
      // カテゴリー専用背景がない場合は、グローバル背景を使用
      final config = await BackgroundImageService.getCurrentConfig();
      if (config.type == BackgroundType.custom) {
        return await config.getImageProvider();
      }
      
      return null; // 白背景
    } catch (e) {
      return null; // エラーの場合は白背景
    }
  }


  void _showOptionsMenu(BuildContext context, Hobby hobby, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => FutureBuilder<Directory>(
        future: getApplicationDocumentsDirectory(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          final dirPath = snapshot.data!.path;
          final imagePath = p.join(dirPath, 'images', hobby.imageFileName);
          final file = File(imagePath);
          final exists = file.existsSync();

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ハンドル
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // タイトル
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[100],
                          image: exists
                              ? DecorationImage(
                                  image: FileImage(file),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: !exists
                            ? Icon(
                                Icons.photo,
                                color: Colors.grey[400],
                                size: 24,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          hobby.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // 編集オプション
                _buildOptionTile(
                  icon: Icons.edit_outlined,
                  title: '編集',
                  subtitle: '趣味の情報を変更',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditHobbyScreen(hobby: hobby),
                      ),
                    );
                  },
                ),
                
                // 削除オプション
                _buildOptionTile(
                  icon: Icons.delete_outline,
                  title: '削除',
                  subtitle: '趣味とメモをすべて削除',
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(context, hobby, ref);
                  },
                  isDestructive: true,
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDestructive 
                    ? Colors.red[50] 
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDestructive 
                    ? Colors.red[600] 
                    : Colors.grey[700],
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDestructive 
                          ? Colors.red[600] 
                          : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Hobby hobby, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange[600],
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text('趣味を削除'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '「${hobby.title}」を削除しますか？',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.red[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'この趣味に関連するメモもすべて削除されます。この操作は取り消せません。',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'キャンセル',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // 関連するメモも削除
              await _deleteHobbyWithMemos(hobby, ref);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('「${hobby.title}」を削除しました'),
                    backgroundColor: Colors.green[600],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '削除',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteHobbyWithMemos(Hobby hobby, WidgetRef ref) async {
    try {
      // 関連するメモを削除
      final memos = await MemoService.loadMemosForHobby(hobby.id);
      for (final memo in memos) {
        await MemoService.deleteMemo(memo.id);
      }
      
      // 趣味を削除
      ref.read(hobbyListProvider.notifier).remove(hobby);
    } catch (e) {
      // エラーハンドリング
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('削除中にエラーが発生しました: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryListProvider);
    
    // カテゴリ数が変わった時にインデックスを調整
    if (categories.isNotEmpty && _currentPageIndex >= categories.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _currentPageIndex = categories.length - 1;
        });
        _pageController.animateToPage(
          _currentPageIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
    
    if (categories.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // TabControllerを動的に初期化
    if (_tabController == null || _tabController!.length != categories.length) {
      _tabController?.dispose();
      _tabController = TabController(length: categories.length, vsync: this);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 背景表示用のPageView（常に表示）
          PageView.builder(
            controller: _pageController,
            itemCount: categories.length,
            pageSnapping: true,
            onPageChanged: (index) {
              setState(() {
                _currentPageIndex = index;
              });
              _tabController!.animateTo(index);
            },
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryPage(category);
            },
          ),
          
          // 活動記録モードのコンテンツオーバーレイ（インライン版に変更）
          // if (_isActivityRecordMode)
          //   _buildActivityRecordContentOverlay(),
          
          // カテゴリ名表示（左上）
          if (!_isBackgroundViewMode)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, top: 16, right: 20),
                  child: Row(
                    children: [
                      // カテゴリ名表示 - Material Design 3準拠
                      GestureDetector(
                        onTap: () => _showCategoryDropdown(context),
                        child: Material(
                          elevation: 2.0, // MD3準拠のelevation
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(20),
                          clipBehavior: Clip.antiAlias,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.folder_outlined,
                                color: Colors.grey[600],
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                categories.isNotEmpty && _currentPageIndex < categories.length
                                    ? categories[_currentPageIndex].name
                                    : 'カテゴリなし',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          ),
                        ),
                      ),
                      
                      // スペーサー（期間選択コントローラーを右寄せするため）
                      if (_isActivityRecordMode)
                        Expanded(
                          child: Container(), // 空のスペーサー
                        ),
                      
                      // 活動記録モード時の期間選択コントローラー
                      if (_isActivityRecordMode) ...[
                        _buildPeriodSelectorHeader(),
                      ],
                      
                      // 隠し操作エリア（ダブルタップで背景表示モード）
                      if (!_isActivityRecordMode)
                        Expanded(
                          child: GestureDetector(
                            onDoubleTap: () async {
                              // 背景が設定されている場合のみ動作
                              final backgroundImage = await _getCurrentBackgroundImage();
                              if (backgroundImage != null) {
                                _toggleBackgroundViewMode();
                              }
                            },
                            child: Container(
                              height: 44, // カテゴリ名コンテナと同じ高さ
                              color: Colors.transparent,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          
          // 並び替えモード時の完了ボタン（右上）
          if (_isReorderMode && !_isBackgroundViewMode)
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(right: 20, top: 16),
                  child: FilledButton(
                    onPressed: _exitReorderMode,
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                      foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                      elevation: 1.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // MD3準拠の12px
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: const Text(
                      '完了',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
          // Floating ToolBar（下部）- Material Design 3準拠
          if (!_isBackgroundViewMode)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 2.0), // 完全に画面外（下）
                      end: Offset.zero, // 正常位置
                    ).animate(CurvedAnimation(
                      parent: _toolbarController,
                      curve: Curves.easeInOut,
                    )),
                    child: Material(
                      elevation: 3.0, // MD3準拠のelevation
                      color: Theme.of(context).colorScheme.surfaceContainer, // MD3 Surface container
                      borderRadius: BorderRadius.circular(50),
                      clipBehavior: Clip.antiAlias,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _isActivityRecordMode 
                              ? _buildActivityRecordToolbar(categories)
                              : _buildNormalToolbar(categories),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
          // 背景表示モード時の終了エリア
          if (_isBackgroundViewMode)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleBackgroundViewMode,
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
        ],
      ),
      
    );
  }

  /// 現在の背景画像を取得
  Future<ImageProvider?> _getCurrentBackgroundImage() async {
    final categories = ref.read(categoryListProvider);
    if (categories.isEmpty || _currentPageIndex >= categories.length) {
      return null;
    }
    
    final category = categories[_currentPageIndex];
    return await _getCategoryBackgroundImage(category);
  }

  /// 背景表示モードの切り替え
  void _toggleBackgroundViewMode() {
    setState(() {
      _isBackgroundViewMode = !_isBackgroundViewMode;
    });
  }

  /// 趣味の並べ替え処理
  void _onReorderHobbies(Category category, int oldIndex, int newIndex, List<dynamic> hobbiesInCategory) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    // 並べ替え後のリストを作成
    final reorderedHobbies = List<dynamic>.from(hobbiesInCategory);
    final item = reorderedHobbies.removeAt(oldIndex);
    reorderedHobbies.insert(newIndex, item);

    // 並べ替えを実行
    ref.read(hobbyListProvider.notifier).reorderHobbiesInCategory(category.id, reorderedHobbies.cast<Hobby>());
  }

  /// カテゴリー選択ドロップダウンを表示
  void _showCategoryDropdown(BuildContext context) {
    final categories = ref.read(categoryListProvider);
    
    // カテゴリーが「すべて」のみの場合は設定画面への誘導を表示
    if (categories.length == 1 && categories.first.id == 'default_all') {
      _showCategoryAdditionGuidance();
      return;
    }
    
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
              Container(
                padding: const EdgeInsets.all(20),
                child: const Text(
                  'カテゴリを選択',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              // カテゴリリスト
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = index == _currentPageIndex;
                    
                    return ListTile(
                      leading: Icon(
                        Icons.folder_outlined,
                        color: isSelected ? const Color(0xFF009977) : Colors.grey[600],
                      ),
                      title: Text(
                        category.name,
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF009977) : Colors.black87,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Color(0xFF009977),
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    );
                  },
                ),
              ),
              // 下部の余白
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  /// カテゴリーに移動
  void _navigateToCategory(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// ツールバーボタンを構築
  Widget _buildToolbarButton({
    required IconData icon,
    required VoidCallback? onPressed,
    bool isAccent = false,
    bool isPill = false,
  }) {
    return Container(
      width: isPill ? 56 : 44,
      height: 44,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: isAccent 
              ? Colors.white
              : onPressed != null 
                  ? Colors.grey[700]
                  : Colors.grey[400],
          size: 20,
        ),
        style: IconButton.styleFrom(
          backgroundColor: isAccent 
              ? const Color(0xFF009977)
              : onPressed != null 
                  ? Colors.grey[100]
                  : Colors.grey[50],
          shape: isPill 
              ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                )
              : const CircleBorder(),
          elevation: 0,
        ),
      ),
    );
  }

  /// カテゴリーページを構築
  Widget _buildCategoryPage(Category category) {
    final hobbiesInCategory = ref.watch(hobbiesByCategoryProvider(category.id));
    
    return FutureBuilder<ImageProvider?>(
      future: _getCategoryBackgroundImage(category),
      builder: (context, backgroundSnapshot) {
        return Stack(
          children: [
            // 背景画像
            Positioned.fill(
              child: (_isBackgroundViewMode && backgroundSnapshot.data != null) ||
                     (hobbiesInCategory.isNotEmpty && backgroundSnapshot.data != null)
                  ? Image(
                      image: backgroundSnapshot.data!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.white,
                    ),
            ),
            
            // コンテンツ（背景表示モード時は非表示）
            if (!_isBackgroundViewMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 130, 20, 0),
              child: FutureBuilder<Directory>(
                  future: getApplicationDocumentsDirectory(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final dirPath = snapshot.data!.path;

                    if (hobbiesInCategory.isEmpty) {
                      return _buildEmptyState(category);
                    }
                    
                    return ReorderableListView.builder(
                      scrollController: _getScrollController(category.id),
                      itemCount: hobbiesInCategory.length + 2, // カレンダー要素と空白要素用に+2
                      padding: const EdgeInsets.only(top: 15, bottom: 120), // ツールバー分の余白を確保
                      onReorder: (oldIndex, newIndex) => _onReorderHobbies(category, oldIndex, newIndex, hobbiesInCategory),
                      buildDefaultDragHandles: false, // デフォルトのドラッグハンドルを無効化
                      scrollDirection: Axis.vertical,
                      proxyDecorator: (child, index, animation) {
                        return MediaQuery.removePadding(
                          context: context,
                          removeTop: true,
                          removeBottom: true,
                          child: Material(
                            elevation: 4.0,
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            child: child,
                          ),
                        );
                      },
                      itemBuilder: (context, index) {
                        // カレンダー要素（最後から2番目）
                        if (index == hobbiesInCategory.length) {
                          return Container(
                            key: const ValueKey('calendar_content'),
                            child: _showCalendarContent 
                                ? _buildActivityRecordContentInline() // 制御変数による表示
                                : const SizedBox.shrink(), // 非表示
                          );
                        }
                        
                        // 空白要素（最後）
                        if (index == hobbiesInCategory.length + 1) {
                          return AnimatedBuilder(
                            key: const ValueKey('spacer'),
                            animation: _transitionController,
                            builder: (context, child) {
                              // 動的に計算された空白要素の高さ
                              final baseSpacerHeight = _calculateScrollAmount();
                              final spacerHeight = _transitionController.value * baseSpacerHeight;
                              return Container(
                                height: spacerHeight,
                                color: Colors.transparent, // 透明に変更
                              );
                            },
                          );
                        }
                        
                        // 通常の趣味カード
                        final hobby = hobbiesInCategory[index];
                        final imagePath = p.join(dirPath, 'images', hobby.imageFileName);
                        final file = File(imagePath);
                        final exists = file.existsSync();

                        // 趣味カード非表示制御
                        if (_hideHobbyCards) {
                          return Container(
                            key: ValueKey(hobby.id),
                            height: 0, // 高さ0で非表示
                          );
                        }

                        return Padding(
                          key: ValueKey(hobby.id),
                          padding: const EdgeInsets.only(bottom: 16),
                          child: GestureDetector(
                            onLongPress: () {
                              if (!_isReorderMode) {
                                _toggleReorderMode();
                              }
                            },
                            child: _isReorderMode
                              ? ReorderableDragStartListener(
                                  index: index,
                                  child: AnimatedBuilder(
                                      animation: _shakeController,
                                      builder: (context, child) {
                                        // より自然な揺れのためのオフセット計算
                                        final shakeOffset = (index % 2 == 0 ? 1 : -1) * 
                                            1.5 * math.sin(_shakeController.value * 2 * math.pi);
                                        final rotationAngle = (index % 2 == 0 ? 1 : -1) * 
                                            0.015 * math.sin(_shakeController.value * 2 * math.pi);
                                        
                                        return Transform.translate(
                                          offset: Offset(shakeOffset, 0),
                                          child: Transform.rotate(
                                            angle: rotationAngle,
                                            child: _buildHobbyCard(
                                              hobby: hobby,
                                              imageFile: exists ? file : null,
                                              dirPath: dirPath,
                                              hobbiesInCategory: hobbiesInCategory,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : _buildHobbyCard(
                                    hobby: hobby,
                                    imageFile: exists ? file : null,
                                    dirPath: dirPath,
                                    hobbiesInCategory: hobbiesInCategory,
                                  ),
                            ),
                          );
                        },
                      );
                  },
                ),
              ),
            
            // 上部スクロール境界の影（スクロール時のみ）
            if (!_isBackgroundViewMode && 
                (_showTopShadow[category.id] ?? false))
            Positioned(
              top: 130,
              left: 0,
              right: 0,
              height: 30,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.15),
                      Colors.black.withOpacity(0.08),
                      Colors.black.withOpacity(0.03),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.4, 0.8, 1.0],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHobbyCard({
    required Hobby hobby,
    required File? imageFile,
    required String dirPath,
    required List<dynamic> hobbiesInCategory,
  }) {
    return Card(
      elevation: _isReorderMode ? 3.0 : 1.0, // MD3準拠のelevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // MD3推奨の12px
      ),
      color: Theme.of(context).colorScheme.surfaceContainerLow, // MD3 Surface container
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetailHobbyScreen(hobby: hobby),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 120, // カード全体の高さを固定
            child: Row(
              children: [
              // 左側：アイコン画像エリア
              Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.all(10),
                child: _isReorderMode 
                ? Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[100],
                      image: imageFile != null
                          ? DecorationImage(
                              image: FileImage(imageFile),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: imageFile == null
                        ? Icon(
                            Icons.broken_image,
                            color: Colors.grey[400],
                            size: 40,
                          )
                        : null,
                  )
                : Hero(
                    tag: 'hobby_image_${hobby.id}',
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[100],
                        image: imageFile != null
                            ? DecorationImage(
                                image: FileImage(imageFile),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: imageFile == null
                          ? Icon(
                              Icons.broken_image,
                              color: Colors.grey[400],
                              size: 40,
                            )
                          : null,
                    ),
                  ),
              ),
              
              // 右側：情報エリア
              Expanded(
                child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 趣味名
                    Flexible(
                      child: Text(
                        hobby.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // メモ数と更新情報
                    FutureBuilder<int>(
                      future: MemoService.getMemoCountForHobby(hobby.id),
                      builder: (context, snapshot) {
                        final memoCount = snapshot.data ?? 0;
                        return Row(
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '$memoCount件のメモ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    
                    const SizedBox(height: 2),
                    
                    // 簡単な説明文または最終更新
                    Flexible(
                      child: hobby.memo != null && hobby.memo!.isNotEmpty
                          ? Text(
                              hobby.memo!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            )
                          : Text(
                              'タップして詳細を確認',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              ),
              
              // 右端：オプションボタン
              Container(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                onPressed: () => _showOptionsMenu(context, hobby, ref),
                icon: Icon(
                  Icons.more_vert,
                  color: Colors.grey[600],
                  size: 20,
                ),
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                padding: const EdgeInsets.all(6),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildEmptyState([Category? category]) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(40, 0, 40, 140), // ツールバー分の下部余白
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 140, // ツールバー分を除く
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // メインメッセージ
                  Text(
                    category?.id == 'default_all' 
                        ? 'あなたの趣味を\n記録してみませんか？'
                        : '「${category?.name}」に\n趣味を追加しましょう',
                    style: const TextStyle(
                      fontSize: 18, // さらに小さく
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8), // 間隔をさらに短く
                  
                  // サブメッセージ
                  Text(
                    category?.id == 'default_all'
                        ? '趣味を追加して、活動記録を\n写真やメモで残しましょう'
                        : 'このカテゴリーにはまだ\n趣味が登録されていません',
                    style: TextStyle(
                      fontSize: 13, // サイズをさらに小さく
                      color: Colors.grey[600],
                      height: 1.3, // 行間をさらに狭く
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 20), // 間隔をさらに短く
                  
                  // 行動誘導ボタン
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddHobbyScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: Text(
                      category?.id == 'default_all' 
                          ? '最初の趣味を追加'
                          : '趣味を追加',
                      style: const TextStyle(
                        fontSize: 15, // ボタンのフォントサイズも小さく
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF009977),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14), // パディングを小さく
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 2,
                    ),
                  ),
                  
                  const SizedBox(height: 16), // 間隔を短く
                  
                  // 機能紹介
                  Container(
                    padding: const EdgeInsets.all(16), // パディングを小さく
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12), // 角丸を小さく
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        _buildFeatureItem(
                          icon: Icons.photo_camera,
                          title: '写真で記録',
                          description: 'アイコンやメモに写真を添付',
                        ),
                        const SizedBox(height: 12), // 間隔を短く
                        _buildFeatureItem(
                          icon: Icons.edit_note,
                          title: 'メモを残す',
                          description: '活動の記録や感想を保存',
                        ),
                        const SizedBox(height: 12), // 間隔を短く
                        _buildFeatureItem(
                          icon: Icons.palette,
                          title: 'カスタマイズ',
                          description: '背景画像で自分らしく',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF009977).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF009977),
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 活動記録コンテンツオーバーレイを構築
  Widget _buildActivityRecordContentOverlay() {
    final categories = ref.read(categoryListProvider);
    final currentCategory = categories.isNotEmpty && _currentPageIndex < categories.length 
        ? categories[_currentPageIndex] 
        : null;
    
    return AnimatedBuilder(
      animation: _transitionController,
      builder: (context, child) {
        final topPadding = 400 * (1 - _transitionController.value); // 下からスライドイン用のパディング
        return Positioned(
          top: 130, // カテゴリ名表示の下から開始
          left: 0,
          right: 0,
          bottom: 120, // ツールバー分の余白
          child: Container(
            color: Colors.white, // 背景色を追加して趣味カードを隠す
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 30 + topPadding, 20, 0), // 上部パディングをアニメーション
        child: Column(
          children: [
            // 上部タイトルエリア
            Container(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    currentCategory != null ? '${currentCategory.name}の活動記録' : '活動記録',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            
            // カレンダーカード（プロトタイプ）
            Container(
              height: 200,
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(20),
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
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_month,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'カレンダー表示\n（プロトタイプ）',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // 活動一覧カード（プロトタイプ）
            Container(
              height: 200,
              padding: const EdgeInsets.all(20),
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
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.list_alt,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 12),
                    Text(
                      '活動一覧\n（プロトタイプ）',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
        );
      },
    );
  }

  /// 活動記録コンテンツ（インライン版）を構築
  Widget _buildActivityRecordContentInline() {
    final categories = ref.read(categoryListProvider);
    final currentCategory = categories.isNotEmpty && _currentPageIndex < categories.length 
        ? categories[_currentPageIndex] 
        : null;
    
    // 活動記録のカテゴリIDを設定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (currentCategory != null) {
        ref.read(activityRecordProvider.notifier).changeCategoryId(currentCategory.id);
      }
    });
    
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
        elevation: 2.0, // カテゴリカードと同じelevation
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20), // カテゴリカードと同じ角丸
        clipBehavior: Clip.antiAlias,
        child: Container(
          // カテゴリカードと同じサイズに調整
          height: 44, // カテゴリカードと同じ高さ
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end, // 右寄せに変更
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
              
              // 期間タイプアイコン + 期間表示
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 期間タイプアイコン
                    Icon(
                      _getPeriodTypeIcon(periodType),
                      color: Theme.of(context).colorScheme.primary,
                      size: 16,
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
                  ],
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
        ),
      ),
    );
  }
  
  /// 期間表示を短縮形式で取得
  String _getShortPeriodDisplay(String fullDisplay) {
    // 「2025年1月」→「1月」
    if (fullDisplay.contains('年') && fullDisplay.contains('月')) {
      final match = RegExp(r'(\d+)月').firstMatch(fullDisplay);
      if (match != null) {
        return '${match.group(1)}月';
      }
    }
    // 「1/20 - 1/26」→「1/20-26」
    if (fullDisplay.contains(' - ')) {
      return fullDisplay.replaceAll(' - ', '-').replaceAll('/', '/');
    }
    // 「2025年」→「2025」
    if (fullDisplay.contains('年')) {
      return fullDisplay.replaceAll('年', '');
    }
    return fullDisplay;
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
                    Text(
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
          Text(
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
            Text(
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
          final weekEnd = weekStart.add(const Duration(days: 6));
          
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
            style: TextStyle(
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
                width: double.infinity, // 横幅を最大に設定
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
                      style: TextStyle(
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

  /// 通常モードのツールバーを構築
  List<Widget> _buildNormalToolbar(List<Category> categories) {
    return [
      // 左矢印（前のカテゴリ）
      _buildToolbarButton(
        icon: Icons.arrow_back_ios_new,
        onPressed: _currentPageIndex > 0 
            ? () => _navigateToCategory(_currentPageIndex - 1)
            : (categories.length == 1 && categories.first.id == 'default_all')
                ? () => _showCategoryAdditionGuidance()
                : null,
      ),
      
      // 右矢印（次のカテゴリ）
      _buildToolbarButton(
        icon: Icons.arrow_forward_ios,
        onPressed: _currentPageIndex < categories.length - 1
            ? () => _navigateToCategory(_currentPageIndex + 1)
            : (categories.length == 1 && categories.first.id == 'default_all')
                ? () => _showCategoryAdditionGuidance()
                : null,
      ),
      
      // 趣味追加
      _buildToolbarButton(
        icon: Icons.add,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddHobbyScreen(),
            ),
          );
        },
        isAccent: true,
        isPill: true,
      ),
      
      // 活動記録
      _buildToolbarButton(
        icon: Icons.bar_chart,
        onPressed: _toggleActivityRecordMode,
      ),
      
      // 設定
      _buildToolbarButton(
        icon: Icons.settings,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SettingsScreen(),
            ),
          );
          
          if (result == true) {
            ref.read(categoryListProvider.notifier).reload();
          }
        },
      ),
    ];
  }

  /// 活動記録モードのツールバーを構築
  List<Widget> _buildActivityRecordToolbar(List<Category> categories) {
    return [
      // 左矢印（前のカテゴリ）
      _buildToolbarButton(
        icon: Icons.arrow_back_ios_new,
        onPressed: _currentPageIndex > 0 
            ? () => _navigateToCategory(_currentPageIndex - 1)
            : null,
      ),
      
      // 右矢印（次のカテゴリ）
      _buildToolbarButton(
        icon: Icons.arrow_forward_ios,
        onPressed: _currentPageIndex < categories.length - 1
            ? () => _navigateToCategory(_currentPageIndex + 1)
            : null,
      ),
      
      // 期間選択ボトムシートボタン（強調）
      _buildToolbarButton(
        icon: Icons.calendar_today,
        onPressed: () => _showPeriodSelectionBottomSheet(),
        isAccent: true,
        isPill: true,
      ),
      
      // 戻るボタン（中央配置）
      _buildToolbarButton(
        icon: Icons.close,
        onPressed: _toggleActivityRecordMode,
      ),
      
      // 設定ボタン
      _buildToolbarButton(
        icon: Icons.settings,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SettingsScreen(),
            ),
          );
          
          if (result == true) {
            ref.read(categoryListProvider.notifier).reload();
          }
        },
      ),
    ];
  }

  /// 今日の日付をフォーマット
  String _formatTodayDate() {
    final today = DateTime.now();
    final weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    final weekday = weekdays[today.weekday - 1];
    
    return '${today.year}年${today.month}月${today.day}日（$weekday）';
  }

  /// プレミアムアップグレードダイアログを表示
  void _showPremiumUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.lock,
              color: Colors.amber[600],
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'プレミアム機能',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          '過去2週間より古い活動記録を見るには、プレミアム版へのアップグレードが必要です。',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // プレミアムプラン選択画面を表示
              showDialog(
                context: context,
                builder: (_) => const PremiumPlanSelectionScreen(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('アップグレード'),
          ),
        ],
      ),
    );
  }

  /// 期間選択ボトムシートを表示
  void _showPeriodSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            final currentPeriodType = ref.read(activityPeriodTypeProvider);
            final currentPeriodInfo = ref.read(activityPeriodInfoProvider);
            final currentDate = ref.read(activityBaseDateProvider);
            
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
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
                  
                  // タイトルと今日の日付
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '期間選択',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '今日の日付: ${_formatTodayDate()}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // 期間タイプ選択タブ
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Consumer(
                      builder: (context, ref, _) {
                        final isPremium = ref.watch(premiumProvider);
                        
                        return Row(
                          children: PeriodType.values.map((type) {
                            final isSelected = type == currentPeriodType;
                            
                            // 期間タイプが利用可能かチェック
                            bool isTypeAvailable;
                            if (isPremium) {
                              isTypeAvailable = true;
                            } else {
                              // 無料版では、期間タイプで一部でも表示可能期間が含まれているかチェック
                              isTypeAvailable = ActivityRecordService.isPeriodTypeAvailableInFreeTier(type);
                            }
                            
                            return Expanded(
                              child: GestureDetector(
                                onTap: isTypeAvailable ? () {
                                  ref.read(activityRecordProvider.notifier).changePeriodType(type);
                                  setBottomSheetState(() {});
                                } : () => _showPremiumUpgradeDialog(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _getPeriodTypeIcon(type),
                                    color: isSelected 
                                        ? Colors.white 
                                        : (isTypeAvailable ? Colors.grey[600] : Colors.grey[400]),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    type.displayName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected 
                                          ? Colors.white 
                                          : (isTypeAvailable ? Colors.grey[600] : Colors.grey[400]),
                                    ),
                                  ),
                                  if (!isTypeAvailable) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.lock,
                                      size: 12,
                                      color: isSelected ? Colors.white : Colors.grey[400],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 期間選択リスト
                  Flexible(
                    child: _buildPeriodSelectionList(currentPeriodType, currentDate),
                  ),
                  
                  // 今日に戻るボタン
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ref.read(activityBaseDateProvider.notifier).state = DateTime.now();
                          ref.read(activityRecordProvider.notifier).reload();
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.today),
                        label: const Text('今日に戻る'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 期間選択リストを構築
  Widget _buildPeriodSelectionList(PeriodType periodType, DateTime currentDate) {
    switch (periodType) {
      case PeriodType.yearly:
        return _buildYearSelectionList(currentDate);
      case PeriodType.monthly:
        return _buildMonthSelectionList(currentDate);
      case PeriodType.biweekly:
        return _buildBiweekSelectionList(currentDate);
    }
  }

  /// 年選択リストを構築
  Widget _buildYearSelectionList(DateTime currentDate) {
    final todayYear = DateTime.now().year; // 今日の年を基準
    final currentYear = currentDate.year;
    // 今日の年から過去10年間のみ表示
    final years = List.generate(10, (index) => todayYear - index);
    
    return Consumer(
      builder: (context, ref, _) {
        final isPremium = ref.watch(premiumProvider);
        
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: years.length,
          itemBuilder: (context, index) {
            final year = years[index];
            final isSelected = year == currentYear;
            final yearPeriod = ActivityRecordService.getCurrentPeriodInfo(PeriodType.yearly, DateTime(year, 1, 1));
            final isAvailable = isPremium || ActivityRecordService.hasVisiblePortionInFreeTier(yearPeriod);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary
                        : (isAvailable ? Colors.grey[100] : Colors.grey[50]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_view_month,
                    color: isSelected 
                        ? Colors.white 
                        : (isAvailable ? Colors.grey[600] : Colors.grey[300]),
                    size: 20,
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      '${year}年',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected 
                            ? Theme.of(context).colorScheme.primary
                            : (isAvailable ? Colors.black87 : Colors.grey[400]),
                      ),
                    ),
                    if (!isAvailable) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.lock,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                    ],
                  ],
                ),
                trailing: isSelected 
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      )
                    : null,
                onTap: isAvailable ? () {
                  final newDate = DateTime(year, currentDate.month, currentDate.day);
                  ref.read(activityBaseDateProvider.notifier).state = newDate;
                  ref.read(activityRecordProvider.notifier).reload();
                  Navigator.pop(context);
                } : () => _showPremiumUpgradeDialog(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: isSelected 
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  /// 月選択リストを構築
  Widget _buildMonthSelectionList(DateTime currentDate) {
    final today = DateTime.now();
    final currentMonth = currentDate.month;
    final currentYear = currentDate.year;
    
    // 今日を含む月を最上位にして、過去24ヶ月を時系列逆順で表示
    final months = <DateTime>[];
    
    // 今日から過去24ヶ月生成（今日から過去へ）
    for (int i = 0; i <= 24; i++) {
      final monthDate = DateTime(today.year, today.month - i, 1);
      months.add(monthDate);
    }
    
    return Consumer(
      builder: (context, ref, _) {
        final isPremium = ref.watch(premiumProvider);
        
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: months.length,
          itemBuilder: (context, index) {
            final monthDate = months[index];
            final isSelected = monthDate.month == currentMonth && monthDate.year == currentYear;
            final monthPeriod = ActivityRecordService.getCurrentPeriodInfo(PeriodType.monthly, monthDate);
            final isAvailable = isPremium || ActivityRecordService.hasVisiblePortionInFreeTier(monthPeriod);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary
                        : (isAvailable ? Colors.grey[100] : Colors.grey[50]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_view_month,
                    color: isSelected 
                        ? Colors.white 
                        : (isAvailable ? Colors.grey[600] : Colors.grey[300]),
                    size: 20,
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      '${monthDate.year}年${monthDate.month}月',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected 
                            ? Theme.of(context).colorScheme.primary
                            : (isAvailable ? Colors.black87 : Colors.grey[400]),
                      ),
                    ),
                    if (!isAvailable) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.lock,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                    ],
                  ],
                ),
                trailing: isSelected 
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      )
                    : null,
                onTap: isAvailable ? () {
                  final newDate = DateTime(monthDate.year, monthDate.month, currentDate.day);
                  ref.read(activityBaseDateProvider.notifier).state = newDate;
                  ref.read(activityRecordProvider.notifier).reload();
                  Navigator.pop(context);
                } : () => _showPremiumUpgradeDialog(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: isSelected 
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  /// 2週間選択リストを構築
  Widget _buildBiweekSelectionList(DateTime currentDate) {
    final biweeks = <DateTime>[];
    final now = DateTime.now();
    
    // 今日を含む2週間を最上位にして、過去16回分（32週間）を時系列逆順で表示
    for (int i = 0; i <= 16; i++) {
      final biweekStart = now.subtract(Duration(days: i * 14));
      final mondayOfBiweek = biweekStart.subtract(Duration(days: biweekStart.weekday - 1));
      biweeks.add(mondayOfBiweek);
    }
    
    return Consumer(
      builder: (context, ref, _) {
        final isPremium = ref.watch(premiumProvider);
        
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: biweeks.length,
          itemBuilder: (context, index) {
            final biweekStart = biweeks[index];
            final biweekEnd = biweekStart.add(const Duration(days: 13));
            final currentBiweekStart = currentDate.subtract(Duration(days: currentDate.weekday - 1));
            final isSelected = biweekStart.year == currentBiweekStart.year &&
                              biweekStart.month == currentBiweekStart.month &&
                              biweekStart.day == currentBiweekStart.day;
            final biweekPeriod = ActivityRecordService.getCurrentPeriodInfo(PeriodType.biweekly, biweekStart);
            final isAvailable = isPremium || ActivityRecordService.hasVisiblePortionInFreeTier(biweekPeriod);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary
                        : (isAvailable ? Colors.grey[100] : Colors.grey[50]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.date_range,
                    color: isSelected 
                        ? Colors.white 
                        : (isAvailable ? Colors.grey[600] : Colors.grey[300]),
                    size: 20,
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      '${biweekStart.month}/${biweekStart.day} - ${biweekEnd.month}/${biweekEnd.day}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected 
                            ? Theme.of(context).colorScheme.primary
                            : (isAvailable ? Colors.black87 : Colors.grey[400]),
                      ),
                    ),
                    if (!isAvailable) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.lock,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  '${biweekStart.year}年',
                  style: TextStyle(
                    fontSize: 12,
                    color: isAvailable ? Colors.grey[600] : Colors.grey[400],
                  ),
                ),
                trailing: isSelected 
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      )
                    : null,
                onTap: isAvailable ? () {
                  ref.read(activityBaseDateProvider.notifier).state = biweekStart;
                  ref.read(activityRecordProvider.notifier).reload();
                  Navigator.pop(context);
                } : () => _showPremiumUpgradeDialog(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: isSelected 
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : null,
              ),
            );
          },
        );
      },
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
