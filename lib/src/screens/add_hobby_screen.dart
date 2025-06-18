import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/hobby_storage.dart';
import '../models/hobby.dart';
import '../services/hobby_json_service.dart';
import '../providers/hobby_list_provider.dart';

class AddHobbyScreen extends ConsumerStatefulWidget {
  const AddHobbyScreen({super.key});

  @override
  ConsumerState<AddHobbyScreen> createState() => _AddHobbyScreenState();
}

class _AddHobbyScreenState extends ConsumerState<AddHobbyScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  File? _selectedImage;

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
        title: const Text("趣味を追加"),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // アイコン画像のプレビュー
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[300],
                backgroundImage:
                    _selectedImage != null ? FileImage(_selectedImage!) : null,
                child: _selectedImage == null
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

                if (_selectedImage == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("アイコン画像を選んでください")),
                  );
                  return;
                }

                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("趣味の名前を入力してください")),
                  );
                  return;
                }

                // ファイルを保存ディレクトリにコピー
                final savedImageFile = await HobbyStorageService.saveImageToLocalDirectory(_selectedImage!);

                // savedImageFile.path を Hobbyモデルなどで使えるように保存
                print('保存先: ${savedImageFile.path}');

                final fileName = path.basename(savedImageFile.path);
                
                // Hobbyインスタンス保存処理
                final newHobby = Hobby(
                  title: title,
                  memo: memo.isEmpty ? null : memo,
                  imageFileName: fileName,
                );

                final hobbies = await HobbyJsonService.loadHobbies();
                hobbies.add(newHobby);
                await HobbyJsonService.saveHobbies(hobbies);

                ref.read(hobbyListProvider.notifier).add(newHobby);


                Navigator.pop(context);
              },
              icon: const Icon(Icons.save),
              label: const Text('保存'),
            )
          ],
        ),
      ),
    );
  }
}
