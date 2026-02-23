import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class HobbyStorageService {
  static final _uuid = Uuid();

  /// 選択された画像ファイルをアプリ内部の画像保存フォルダにコピーして返す
  static Future<File> saveImageToLocalDirectory(File originalImage) async {
    final appDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory('${appDir.path}/images');

    // ディレクトリがなければ作成
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }

    final fileExtension = originalImage.path.split('.').last;
    final newFileName = '${_uuid.v4()}.$fileExtension';
    final newPath = '${imageDir.path}/$newFileName';

    final newImage = await originalImage.copy(newPath);
    return newImage;
  }

  /// 選択されたヘッダー画像ファイルをアプリ内部の headers フォルダにコピーして返す
  static Future<File> saveHeaderImageToLocalDirectory(File originalImage) async {
    final appDir = await getApplicationDocumentsDirectory();
    final headerDir = Directory('${appDir.path}/headers');

    if (!await headerDir.exists()) {
      await headerDir.create(recursive: true);
    }

    final fileExtension = originalImage.path.split('.').last;
    final newFileName = '${_uuid.v4()}.$fileExtension';
    final newPath = '${headerDir.path}/$newFileName';

    final newImage = await originalImage.copy(newPath);
    return newImage;
  }
}
