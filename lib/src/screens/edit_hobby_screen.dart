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
      appBar: AppBar(
        title: const Text("趣味を編集"),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[300],
                backgroundImage: _selectedImage != null 
                    ? FileImage(_selectedImage!)
                    : _currentImage != null 
                        ? FileImage(_currentImage!)
                        : null,
                child: (_selectedImage == null && _currentImage == null)
                    ? const Icon(Icons.add_a_photo, size: 32, color: Colors.black45)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '趣味の名前',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _memoController,
              decoration: const InputDecoration(
                labelText: 'メモ（任意）',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final title = _titleController.text.trim();
                final memo = _memoController.text.trim();

                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("趣味の名前を入力してください")),
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
                  SnackBar(content: Text('「$title」を更新しました')),
                );
              },
              icon: const Icon(Icons.save),
              label: const Text('保存'),
            )
          ],
        ),
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