import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// 既存データをカテゴリー対応形式に移行するサービス
class DataMigrationService {
  static const String _migrationStatusFile = 'migration_status.json';
  static const String _currentVersion = '1.2.1'; // カテゴリー名変更版（樹形図対応）

  /// データ移行が必要かチェックし、必要な場合は実行
  static Future<void> migrateIfNeeded() async {
    try {
      final currentMigrationVersion = await _getCurrentMigrationVersion();

      // バージョンごとに順次移行を実行
      if (currentMigrationVersion == null) {
        await _migrateToV1_1_0();
        await _migrateToV1_2_0();
        await _saveMigrationVersion(_currentVersion);
      } else if (currentMigrationVersion == '1.1.0') {
        await _migrateToV1_2_0();
        await _saveMigrationVersion(_currentVersion);
      } else if (currentMigrationVersion == '1.2.0') {
        // 樹形図データの更新のみ実行
        await _migrateToV1_2_0();
        await _saveMigrationVersion(_currentVersion);
      } else if (currentMigrationVersion != _currentVersion) {
        await _migrateToV1_2_0();
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

  /// v1.2.0（カテゴリー名変更: すべて→マイ趣味）への移行
  static Future<void> _migrateToV1_2_0() async {
    try {
      final dir = await getApplicationDocumentsDirectory();

      // categories.jsonの更新
      final categoriesFile = File(path.join(dir.path, 'categories.json'));
      if (await categoriesFile.exists()) {
        final contents = await categoriesFile.readAsString();
        final List<dynamic> jsonList = jsonDecode(contents);

        bool needsUpdate = false;
        final updatedList = jsonList.map((json) {
          if (json['id'] == 'default_all' && json['name'] == 'すべて') {
            json['name'] = 'マイ趣味';
            needsUpdate = true;
          }
          return json;
        }).toList();

        if (needsUpdate) {
          await categoriesFile.writeAsString(jsonEncode(updatedList));
          print('Data migration completed: Category name updated to マイ趣味');
        }
      }

      // tree_nodes.jsonの更新（樹形図データ）
      final treeNodesFile = File(path.join(dir.path, 'tree_nodes.json'));
      if (await treeNodesFile.exists()) {
        final contents = await treeNodesFile.readAsString();
        final List<dynamic> jsonList = jsonDecode(contents);

        bool needsUpdate = false;
        final updatedList = jsonList.map((json) {
          // default_allカテゴリーノードの名前を更新
          if (json['id'] == 'category_default_all' && json['title'] == 'すべて') {
            json['title'] = 'マイ趣味';
            needsUpdate = true;
          }
          return json;
        }).toList();

        if (needsUpdate) {
          await treeNodesFile.writeAsString(jsonEncode(updatedList));
          print('Data migration completed: Tree node name updated to マイ趣味');
        }
      }
    } catch (e) {
      print('Migration to v1.2.0 failed: $e');
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