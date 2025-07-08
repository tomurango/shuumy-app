import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../services/hobby_storage.dart';
import '../models/hobby.dart';
import '../models/category.dart';
import '../providers/hobby_list_provider.dart';
import '../providers/category_provider.dart';
import '../providers/premium_provider.dart';
import 'premium_plan_selection_screen.dart';

class EditHobbyScreen extends ConsumerStatefulWidget {
  final Hobby hobby;
  
  const EditHobbyScreen({super.key, required this.hobby});

  @override
  ConsumerState<EditHobbyScreen> createState() => _EditHobbyScreenState();
}

class _EditHobbyScreenState extends ConsumerState<EditHobbyScreen> {
  late TextEditingController _titleController;
  late TextEditingController _memoController;

  File? _selectedImage;
  File? _currentImage;
  late String _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.hobby.title);
    _memoController = TextEditingController(text: widget.hobby.memo ?? '');
    _selectedCategoryId = widget.hobby.categoryId;
    _loadCurrentImage();
  }

  Future<void> _loadCurrentImage() async {
    final dir = await getApplicationDocumentsDirectory();
    final imagePath = path.join(dir.path, 'images', widget.hobby.imageFileName);
    final file = File(imagePath);
    if (file.existsSync()) {
      setState(() {
        _currentImage = file;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
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
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "趣味を編集",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final title = _titleController.text.trim();
              final memo = _memoController.text.trim();

              if (title.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("趣味の名前を入力してください"),
                    backgroundColor: Colors.red[400],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
                return;
              }

              String imageFileName = widget.hobby.imageFileName;
              
              if (_selectedImage != null) {
                final savedImageFile = await HobbyStorageService.saveImageToLocalDirectory(_selectedImage!);
                imageFileName = path.basename(savedImageFile.path);
                
                final dir = await getApplicationDocumentsDirectory();
                final oldImagePath = path.join(dir.path, 'images', widget.hobby.imageFileName);
                final oldImageFile = File(oldImagePath);
                if (oldImageFile.existsSync()) {
                  await oldImageFile.delete();
                }
              }

              final updatedHobby = Hobby(
                id: widget.hobby.id,
                title: title,
                memo: memo.isEmpty ? null : memo,
                imageFileName: imageFileName,
                categoryId: _selectedCategoryId,
                order: widget.hobby.order, // 順序は変更しない
                createdAt: widget.hobby.createdAt,
                updatedAt: DateTime.now(),
              );

              ref.read(hobbyListProvider.notifier).update(updatedHobby);

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('「$title」を更新しました'),
                  backgroundColor: const Color(0xFF1DA1F2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            child: const Text(
              '保存',
              style: TextStyle(
                color: Color(0xFF1DA1F2),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 区切り線
          Container(
            height: 1,
            color: Colors.grey[200],
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 画像選択セクション
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.grey[100],
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: _selectedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : _currentImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.file(
                                        _currentImage!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 32,
                                      color: Colors.grey[600],
                                    ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "アイコン画像",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedImage != null ? "新しい画像を選択しました" : "タップして画像を変更",
                              style: TextStyle(
                                fontSize: 14,
                                color: _selectedImage != null ? const Color(0xFF1DA1F2) : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // 趣味名セクション
                  const Text(
                    "趣味の名前",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: '例: 読書、料理、写真撮影',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF1DA1F2), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // メモセクション
                  const Text(
                    "メモ（任意）",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _memoController,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'この趣味について詳しく説明してください...',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF1DA1F2), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // カテゴリー選択セクション
                  _buildCategorySelector(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  /// カテゴリー選択ウィジェットを構築
  Widget _buildCategorySelector() {
    final categories = ref.watch(categoryListProvider);
    final isPremium = ref.watch(premiumProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "カテゴリー",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategoryId,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  // プレミアム機能チェック
                  if (newValue != 'default_all' && !isPremium) {
                    _showPremiumRequiredDialog();
                    return;
                  }
                  
                  setState(() {
                    _selectedCategoryId = newValue;
                  });
                }
              },
              items: categories.map((Category category) {
                return DropdownMenuItem<String>(
                  value: category.id,
                  child: Row(
                    children: [
                      Icon(
                        category.id == 'default_all' 
                            ? Icons.all_inclusive 
                            : Icons.folder_outlined,
                        size: 20,
                        color: category.id == 'default_all' 
                            ? const Color(0xFF009977)
                            : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 16,
                          color: category.id == 'default_all' || isPremium
                              ? Colors.black87
                              : Colors.grey[500],
                        ),
                      ),
                      if (category.id != 'default_all' && !isPremium) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.lock_outline,
                          size: 16,
                          color: Colors.grey[500],
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
              icon: Icon(
                Icons.arrow_drop_down,
                color: Colors.grey[600],
              ),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        
        if (!isPremium && categories.length > 1) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'カスタムカテゴリーはプレミアム機能です',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[800],
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

  /// プレミアム機能が必要な場合のダイアログを表示
  void _showPremiumRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.star,
              color: Colors.amber[600],
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text('プレミアム機能'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'カスタムカテゴリーはプレミアム機能です。',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.amber[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'プレミアム版では無制限のカテゴリー作成が可能です',
                      style: TextStyle(
                        fontSize: 12,
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
            onPressed: () {
              Navigator.pop(context);
              _showPremiumPurchaseDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'プレミアムを見る',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// プレミアム購入ダイアログを表示
  void _showPremiumPurchaseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.star,
              color: Colors.amber[600],
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text('プレミアム版にアップグレード'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'カスタムカテゴリー機能を利用するには、プレミアム版が必要です。',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.amber[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'プレミアム版の特典',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• 無制限のカテゴリー作成\n• カテゴリー別背景画像\n• カテゴリーの管理機能\n• 将来の新機能も利用可能',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '月額',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.amber[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(
                      text: '¥300',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.amber[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: ' / 年額',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.amber[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(
                      text: '¥2,500',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.amber[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: ' / 買い切り',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.amber[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(
                      text: '¥1,800',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.amber[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
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
            onPressed: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => const PremiumPlanSelectionScreen(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '購入する',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}