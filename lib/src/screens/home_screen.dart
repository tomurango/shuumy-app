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
import '../services/background_image_service.dart';
import '../services/category_service.dart';
import '../services/memo_service.dart';
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
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController?.dispose();
    _shakeController.dispose();
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
          // カテゴリー別コンテンツ（全画面）
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
                      // カテゴリ名表示
                      GestureDetector(
                        onTap: () => _showCategoryDropdown(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
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
                      
                      // 隠し操作エリア（ダブルタップで背景表示モード）
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
          
          // Floating ToolBar（下部）
          if (!_isBackgroundViewMode)
            Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 左矢印（前のカテゴリ）
                    _buildToolbarButton(
                      icon: Icons.arrow_back_ios,
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
                    
                    // 活動記録確認（未実装）
                    _buildToolbarButton(
                      icon: Icons.bar_chart,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('活動記録機能は準備中です'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
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
                  ],
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
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20), // 上部余白を縮めた
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
                    
                    return ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black,
                            Colors.black,
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.05, 0.85, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: ReorderableListView.builder(
                        itemCount: hobbiesInCategory.length,
                        padding: const EdgeInsets.only(top: 40, bottom: 120), // カテゴリ名とFloating ToolBarのための余白
                        onReorder: (oldIndex, newIndex) => _onReorderHobbies(category, oldIndex, newIndex, hobbiesInCategory),
                        buildDefaultDragHandles: false, // デフォルトのドラッグハンドルを無効化
                        scrollDirection: Axis.vertical,
                        proxyDecorator: (child, index, animation) {
                          return AnimatedBuilder(
                            animation: animation,
                            builder: (BuildContext context, Widget? child) {
                              final double animValue = Curves.easeInOut.transform(animation.value);
                              return Transform.scale(
                                scale: 1.0 + (0.03 * animValue), // 僅かに大きくする
                                child: Material(
                                  elevation: 3.0 + (2.0 * animValue), // MD3準拠のelevation変化
                                  borderRadius: BorderRadius.circular(12),
                                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                                  child: child,
                                ),
                              );
                            },
                            child: child,
                          );
                        },
                        childWhenDragging: const SizedBox.shrink(), // ドラッグ中は元の位置を空にする
                        itemBuilder: (context, index) {
                          final hobby = hobbiesInCategory[index];
                          final imagePath = p.join(dirPath, 'images', hobby.imageFileName);
                          final file = File(imagePath);
                          final exists = file.existsSync();

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
                      ),
                    );
                  },
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // メインアイコン
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF009977).withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.favorite_border,
                size: 60,
                color: Color(0xFF009977),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // メインメッセージ
            Text(
              category?.id == 'default_all' 
                  ? 'あなたの趣味を\n記録してみませんか？'
                  : '「${category?.name}」に\n趣味を追加しましょう',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // サブメッセージ
            Text(
              category?.id == 'default_all'
                  ? '趣味を追加して、活動記録を\n写真やメモで残しましょう'
                  : 'このカテゴリーにはまだ\n趣味が登録されていません',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 40),
            
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009977),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 2,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 機能紹介
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  _buildFeatureItem(
                    icon: Icons.photo_camera,
                    title: '写真で記録',
                    description: 'アイコンやメモに写真を添付',
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    icon: Icons.edit_note,
                    title: 'メモを残す',
                    description: '活動の記録や感想を保存',
                  ),
                  const SizedBox(height: 16),
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
}
