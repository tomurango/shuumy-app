import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../services/hobby_storage.dart';
import '../models/hobby.dart';
import '../providers/hobby_list_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.hobby.title);
    _memoController = TextEditingController(text: widget.hobby.memo ?? '');
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
}