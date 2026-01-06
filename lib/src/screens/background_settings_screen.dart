import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../services/background_image_service.dart';
import '../services/category_service.dart';
import '../providers/premium_provider.dart';
import '../providers/category_provider.dart';

class BackgroundSettingsScreen extends ConsumerStatefulWidget {
  final String? initialCategoryId;
  
  const BackgroundSettingsScreen({
    super.key,
    this.initialCategoryId,
  });

  @override
  ConsumerState<BackgroundSettingsScreen> createState() => _BackgroundSettingsScreenState();
}

class _BackgroundSettingsScreenState extends ConsumerState<BackgroundSettingsScreen> {
  BackgroundImageConfig? _currentConfig;
  bool _isLoading = false;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
    _loadCurrentConfig();
  }

  Future<void> _loadCurrentConfig() async {
    setState(() {
      _isLoading = true;
    });

    try {
      BackgroundImageConfig config;
      
      if (_selectedCategoryId != null) {
        // カテゴリ別背景を読み込み
        final categories = ref.read(categoryListProvider);
        final category = categories.firstWhere(
          (c) => c.id == _selectedCategoryId,
          orElse: () => throw Exception('カテゴリが見つかりません'),
        );
        
        if (category.backgroundImagePath != null) {
          // カテゴリ専用背景があるかチェック
          final backgroundFile = await CategoryService.getCategoryBackgroundFile(category.backgroundImagePath!);
          
          if (backgroundFile != null) {
            config = BackgroundImageConfig(
              type: BackgroundType.custom,
              customFileName: category.backgroundImagePath,
            );
          } else {
            // カテゴリ専用背景がない場合はグローバル背景を表示
            config = await BackgroundImageService.getCurrentConfig();
          }
        } else {
          // カテゴリ専用背景が設定されていない場合はグローバル背景を表示
          config = await BackgroundImageService.getCurrentConfig();
        }
      } else {
        // グローバル背景を読み込み
        config = await BackgroundImageService.getCurrentConfig();
      }
      
      setState(() {
        _currentConfig = config;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('設定の読み込みに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectCustomImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // 品質を調整してファイルサイズを抑制
      );

      if (pickedFile == null) return;

      setState(() {
        _isLoading = true;
      });

      // 画像を保存
      final imageFile = File(pickedFile.path);
      
      if (_selectedCategoryId != null) {
        // カテゴリ別背景として保存
        final fileName = await CategoryService.saveCategoryBackground(imageFile);
        // カテゴリ情報を取得して背景画像パスを更新
        final categories = ref.read(categoryListProvider);
        final category = categories.firstWhere((c) => c.id == _selectedCategoryId);
        final updatedCategory = category.copyWith(backgroundImagePath: fileName);

        // プロバイダー経由で更新（並び替え情報を保持）
        await ref.read(categoryListProvider.notifier).updateCategory(updatedCategory);

        setState(() {
          _currentConfig = BackgroundImageConfig.custom(fileName);
        });
      } else {
        // グローバル背景として保存
        final fileName = await BackgroundImageService.saveCustomBackground(imageFile);
        
        // 新しい設定を作成・保存
        final newConfig = BackgroundImageConfig.custom(fileName);
        await BackgroundImageService.saveConfig(newConfig);
        
        // 古い背景画像を削除
        if (_currentConfig?.customFileName != null) {
          await BackgroundImageService.cleanupUnusedBackgrounds(fileName);
        }

        setState(() {
          _currentConfig = newConfig;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('背景画像を変更しました'),
            backgroundColor: Colors.green,
          ),
        );
        
        // 変更を通知してホーム画面を更新
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('画像の設定に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetToDefault() async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (_selectedCategoryId != null) {
        // カテゴリ別背景をリセット
        // カテゴリ情報を取得して背景画像パスをリセット
        final categories = ref.read(categoryListProvider);
        final category = categories.firstWhere((c) => c.id == _selectedCategoryId);
        final updatedCategory = category.copyWith(backgroundImagePath: null);

        // プロバイダー経由で更新（並び替え情報を保持）
        await ref.read(categoryListProvider.notifier).updateCategory(updatedCategory);
      } else {
        // グローバル背景をリセット
        await BackgroundImageService.resetToDefault();
      }
      
      setState(() {
        _currentConfig = const BackgroundImageConfig(type: BackgroundType.none);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('白背景に戻しました'),
            backgroundColor: Colors.green,
          ),
        );
        
        // 変更を通知してホーム画面を更新
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('リセットに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          '背景画像',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 区切り線
                Container(
                  height: 1,
                  color: Colors.grey[200],
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // カテゴリ選択
                        _buildCategorySelector(),
                        
                        const SizedBox(height: 24),
                        
                        // 現在の背景プレビュー
                        const Text(
                          '現在の背景',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _currentConfig != null
                                ? FutureBuilder<ImageProvider?>(
                                    future: _getCurrentBackgroundImageProvider(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData && snapshot.data != null) {
                                        return Image(
                                          image: snapshot.data!,
                                          fit: BoxFit.cover,
                                        );
                                      }
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: Icon(
                                            Icons.image,
                                            size: 50,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // 現在選択中のカテゴリ表示
                        Text(
                          _getSelectedCategoryDescription(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 28),
                        
                        // 操作ボタン
                        const Text(
                          '背景画像を変更',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // カスタム画像を選択
                        _buildActionButton(
                          icon: Icons.photo_library,
                          title: 'カスタム画像を選択',
                          subtitle: '写真ライブラリから画像を選択',
                          onTap: _selectCustomImage,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // 白背景に戻す
                        _buildActionButton(
                          icon: Icons.restore,
                          title: '白背景に戻す',
                          subtitle: '背景画像を削除して白背景にします',
                          onTap: _resetToDefault,
                          isDestructive: false,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red : const Color(0xFF009977),
          size: 28,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDestructive ? Colors.red : Colors.black,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  /// 現在の背景画像プロバイダーを取得（カテゴリ専用背景対応）
  Future<ImageProvider?> _getCurrentBackgroundImageProvider() async {
    try {
      if (_selectedCategoryId != null) {
        // カテゴリ専用背景を取得
        final categories = ref.read(categoryListProvider);
        final category = categories.firstWhere(
          (c) => c.id == _selectedCategoryId,
          orElse: () => throw Exception('カテゴリが見つかりません'),
        );
        
        if (category.backgroundImagePath != null) {
          final backgroundFile = await CategoryService.getCategoryBackgroundFile(category.backgroundImagePath!);
          if (backgroundFile != null) {
            return FileImage(backgroundFile);
          }
        }
        
        // カテゴリ専用背景がない場合はグローバル背景
        final globalConfig = await BackgroundImageService.getCurrentConfig();
        return await globalConfig.getImageProvider();
      } else {
        // グローバル背景
        return await _currentConfig!.getImageProvider();
      }
    } catch (e) {
      return null;
    }
  }

  /// 選択中のカテゴリの説明を取得
  String _getSelectedCategoryDescription() {
    if (_selectedCategoryId == null) {
      return 'グローバル背景のプレビュー';
    } else {
      final categories = ref.read(categoryListProvider);
      final category = categories.firstWhere(
        (c) => c.id == _selectedCategoryId,
        orElse: () => throw Exception('カテゴリが見つかりません'),
      );
      
      if (category.backgroundImagePath != null) {
        return '「${category.name}」カテゴリの専用背景';
      } else {
        return '「${category.name}」カテゴリ（グローバル背景を継承）';
      }
    }
  }

  /// カテゴリのプレビュー画像を取得
  Future<ImageProvider?> _getCategoryPreviewImage(String? categoryId) async {
    try {
      if (categoryId == null) {
        // グローバル背景
        final config = await BackgroundImageService.getCurrentConfig();
        return await config.getImageProvider();
      } else {
        // カテゴリ別背景
        final categories = ref.read(categoryListProvider);
        final category = categories.firstWhere(
          (c) => c.id == categoryId,
          orElse: () => throw Exception('カテゴリが見つかりません'),
        );
        
        if (category.backgroundImagePath != null) {
          final file = await CategoryService.getCategoryBackgroundFile(category.backgroundImagePath!);
          if (file != null) {
            return FileImage(file);
          }
        }
        
        // カテゴリ専用背景がない場合、グローバル背景を使用
        final globalConfig = await BackgroundImageService.getCurrentConfig();
        return await globalConfig.getImageProvider();
      }
    } catch (e) {
      return null;
    }
  }

  /// カテゴリ選択UI
  Widget _buildCategorySelector() {
    final categories = ref.watch(categoryListProvider);
    final isPremium = ref.watch(premiumProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '背景を設定するカテゴリ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // すべてのカテゴリ
        _buildCategoryOption(
          title: 'すべて',
          subtitle: 'グローバル背景として設定',
          categoryId: null,
          icon: Icons.apps,
        ),
        
        // 個別カテゴリ（プレミアムのみ）
        if (isPremium && categories.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          
          ...categories.map((category) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildCategoryOption(
              title: category.name,
              subtitle: 'このカテゴリのみの背景として設定',
              categoryId: category.id,
              icon: Icons.folder_outlined,
            ),
          )),
        ] else if (!isPremium && categories.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.lock, color: Colors.grey[600], size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'カテゴリ別背景はプレミアム機能です',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// カテゴリ選択オプション
  Widget _buildCategoryOption({
    required String title,
    required String subtitle,
    required String? categoryId,
    required IconData icon,
  }) {
    final isSelected = _selectedCategoryId == categoryId;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryId = categoryId;
        });
        _loadCurrentConfig();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF009977).withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF009977) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // プレビューサムネイル
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? const Color(0xFF009977) : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: FutureBuilder<ImageProvider?>(
                  future: _getCategoryPreviewImage(categoryId),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      return Image(
                        image: snapshot.data!,
                        fit: BoxFit.cover,
                      );
                    }
                    return Container(
                      color: Colors.grey[100],
                      child: Icon(
                        icon,
                        color: isSelected ? const Color(0xFF009977) : Colors.grey[400],
                        size: 20,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? const Color(0xFF009977) : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF009977),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}