import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// 既存データをカテゴリー対応形式に移行するサービス
class DataMigrationService {
  static const String _migrationStatusFile = 'migration_status.json';
  static const String _currentVersion = '1.1.0'; // カテゴリー機能追加版

  /// データ移行が必要かチェックし、必要な場合は実行
  static Future<void> migrateIfNeeded() async {
    try {
      final currentMigrationVersion = await _getCurrentMigrationVersion();
      
      if (currentMigrationVersion != _currentVersion) {
        await _migrateToV1_1_0();
        await _saveMigrationVersion(_currentVersion);
      }
    } catch (e) {
      // 移行でエラーが発生してもアプリを停止させない
      print('Migration error (continuing anyway): $e');
    }
  }

  /// v1.1.0（カテゴリー機能）への移行
  static Future<void> _migrateToV1_1_0() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final hobbiesFile = File(path.join(dir.path, 'hobbies.json'));
      
      if (!await hobbiesFile.exists()) {
        return; // ファイルが存在しない場合は移行不要
      }

      final contents = await hobbiesFile.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);
      
      bool needsUpdate = false;
      final updatedList = jsonList.map((json) {
        // カテゴリー関連フィールドが存在しない場合は追加
        if (json['categoryId'] == null) {
          json['categoryId'] = 'default_all';
          needsUpdate = true;
        }
        
        if (json['createdAt'] == null) {
          json['createdAt'] = DateTime.now().toIso8601String();
          needsUpdate = true;
        }
        
        if (json['updatedAt'] == null) {
          json['updatedAt'] = DateTime.now().toIso8601String();
          needsUpdate = true;
        }
        
        return json;
      }).toList();

      // 変更があった場合のみファイルを更新
      if (needsUpdate) {
        await hobbiesFile.writeAsString(jsonEncode(updatedList));
        print('Data migration completed: ${updatedList.length} hobbies updated');
      }
    } catch (e) {
      print('Migration to v1.1.0 failed: $e');
      rethrow;
    }
  }

  /// 現在の移行バージョンを取得
  static Future<String?> _getCurrentMigrationVersion() async {
    try {
      final file = await _getMigrationStatusFile();
      if (await file.exists()) {
        final contents = await file.readAsString();
        final data = jsonDecode(contents);
        return data['version'] as String?;
      }
    } catch (e) {
      print('Failed to read migration version: $e');
    }
    return null;
  }

  /// 移行バージョンを保存
  static Future<void> _saveMigrationVersion(String version) async {
    try {
      final file = await _getMigrationStatusFile();
      final data = {
        'version': version,
        'migratedAt': DateTime.now().toIso8601String(),
      };
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      print('Failed to save migration version: $e');
    }
  }

  /// 移行ステータスファイルを取得
  static Future<File> _getMigrationStatusFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(path.join(dir.path, _migrationStatusFile));
  }
}