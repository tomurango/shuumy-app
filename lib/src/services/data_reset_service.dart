import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class DataResetService {
  /// すべてのデータを初期化する
  static Future<void> resetAllData() async {
    final dir = await getApplicationDocumentsDirectory();
    
    // JSONファイルを削除
    await _deleteFileIfExists(path.join(dir.path, 'hobbies.json'));
    await _deleteFileIfExists(path.join(dir.path, 'memos.json'));
    
    // 画像フォルダを削除
    final imageDir = Directory(path.join(dir.path, 'images'));
    if (await imageDir.exists()) {
      await imageDir.delete(recursive: true);
    }
  }
  
  /// ファイルが存在する場合は削除する
  static Future<void> _deleteFileIfExists(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
  
  /// 指定した趣味に関連するデータのみを削除する
  static Future<void> resetHobbyData(String hobbyId) async {
    // この機能は将来的に実装する場合のためのプレースホルダー
    throw UnimplementedError('個別の趣味データ削除は未実装です');
  }
}