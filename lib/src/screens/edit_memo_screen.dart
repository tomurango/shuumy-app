import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/hobby_memo.dart';
import '../services/hobby_storage.dart';
import '../services/memo_service.dart';

class EditMemoScreen extends StatefulWidget {
  final HobbyMemo memo;
  
  const EditMemoScreen({super.key, required this.memo});

  @override
  State<EditMemoScreen> createState() => _EditMemoScreenState();
}

class _EditMemoScreenState extends State<EditMemoScreen> {
  late TextEditingController _contentController;
  File? _selectedImage;
  File? _currentImage;
  bool _isLoading = false;
  bool _imageChanged = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.memo.content);
    _loadCurrentImage();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentImage() async {
    if (widget.memo.imageFileName != null) {
      final dir = await getApplicationDocumentsDirectory();
      final imagePath = path.join(dir.path, 'images', widget.memo.imageFileName!);
      final file = File(imagePath);
      
      if (file.existsSync()) {
        setState(() {
          _currentImage = file;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _imageChanged = true;
      });
    }
  }

  Future<void> _removeImage() async {
    setState(() {
      _selectedImage = null;
      _currentImage = null;
      _imageChanged = true;
    });
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
          "メモを編集",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () async {
              final content = _contentController.text.trim();
              
              if (content.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("メモ内容を入力してください"),
                    backgroundColor: Colors.red[400],
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              setState(() {
                _isLoading = true;
              });

              try {
                String? imageFileName = widget.memo.imageFileName;
                
                // 画像が変更された場合の処理
                if (_imageChanged) {
                  // 古い画像ファイルを削除
                  if (widget.memo.imageFileName != null) {
                    final dir = await getApplicationDocumentsDirectory();
                    final oldImagePath = path.join(dir.path, 'images', widget.memo.imageFileName!);
                    final oldFile = File(oldImagePath);
                    if (oldFile.existsSync()) {
                      await oldFile.delete();
                    }
                  }
                  
                  // 新しい画像を保存
                  if (_selectedImage != null) {
                    final savedFile = await HobbyStorageService.saveImageToLocalDirectory(_selectedImage!);
                    imageFileName = path.basename(savedFile.path);
                  } else {
                    imageFileName = null;
                  }
                }

                // 更新されたメモを作成
                final updatedMemo = HobbyMemo(
                  id: widget.memo.id,
                  hobbyId: widget.memo.hobbyId,
                  content: content,
                  imageFileName: imageFileName,
                  createdAt: widget.memo.createdAt, // 作成日時は変更しない
                );

                await MemoService.updateMemo(updatedMemo);
                
                if (mounted) {
                  Navigator.pop(context, true); // 編集成功を通知
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("エラーが発生しました: $e"),
                      backgroundColor: Colors.red[400],
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              }
            },
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    "保存",
                    style: TextStyle(
                      color: Color(0xFF009977),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // メモ内容入力フィールド
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  hintText: "今日はどんなことがありましたか？",
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 画像プレビュー
            if (_selectedImage != null || _currentImage != null) ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImage ?? _currentImage!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        onPressed: _removeImage,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            
            // ツールバー
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo_library, color: Color(0xFF009977)),
                  onPressed: _pickImage,
                ),
                const Spacer(),
                Text(
                  "${_contentController.text.length}/280",
                  style: TextStyle(
                    color: _contentController.text.length > 280 
                        ? Colors.red 
                        : Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}