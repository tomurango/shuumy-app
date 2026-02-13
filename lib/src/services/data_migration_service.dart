import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// 既存データをカテゴリー対応形式に移行するサービス
class DataMigrationService {
  static const String _migrationStatusFile = 'migration_status.json';
  static const String _currentVersion = '1.3.0'; // 樹形図データ統合版

  /// データ移行が必要かチェックし、必要な場合は実行
  static Future<void> migrateIfNeeded() async {
    try {
      final currentMigrationVersion = await _getCurrentMigrationVersion();

      // バージョンごとに順次移行を実行
      if (currentMigrationVersion == null) {
        await _migrateToV1_1_0();
        await _migrateToV1_2_0();
        await _migrateToV1_3_0();
        await _saveMigrationVersion(_currentVersion);
      } else if (currentMigrationVersion == '1.1.0') {
        await _migrateToV1_2_0();
        await _migrateToV1_3_0();
        await _saveMigrationVersion(_currentVersion);
      } else if (currentMigrationVersion == '1.2.0' || currentMigrationVersion == '1.2.1') {
        await _migrateToV1_3_0();
        await _saveMigrationVersion(_currentVersion);
      } else if (currentMigrationVersion != _currentVersion) {
        await _migrateToV1_3_0();
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

    } catch (e) {
      print('Migration to v1.2.0 failed: $e');
      rethrow;
    }
  }

  /// v1.3.0（樹形図データ統合: tree_nodes.json → hobbies.json）への移行
  static Future<void> _migrateToV1_3_0() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final treeNodesFile = File(path.join(dir.path, 'tree_nodes.json'));
      final hobbiesFile = File(path.join(dir.path, 'hobbies.json'));

      // tree_nodes.jsonが存在しない場合は移行不要
      if (!await treeNodesFile.exists()) {
        print('No tree_nodes.json found, skipping v1.3.0 migration');
        return;
      }

      // hobbies.jsonが存在しない場合も移行不要
      if (!await hobbiesFile.exists()) {
        print('No hobbies.json found, skipping v1.3.0 migration');
        return;
      }

      final treeNodesContents = await treeNodesFile.readAsString();
      final List<dynamic> treeNodes = jsonDecode(treeNodesContents);

      final hobbiesContents = await hobbiesFile.readAsString();
      final List<dynamic> hobbies = jsonDecode(hobbiesContents);

      // カスタムノードのみをフィルタリング
      final customNodes = treeNodes.where((node) => node['type'] == 'custom').toList();

      if (customNodes.isEmpty) {
        print('No custom nodes found, deleting tree_nodes.json');
        await treeNodesFile.delete();
        return;
      }

      // 親ノードIDごとにカスタムノードをグループ化
      final Map<String, List<Map<String, dynamic>>> nodesByParent = {};
      for (final node in customNodes) {
        final parentId = node['parentId'] as String?;
        if (parentId != null) {
          nodesByParent.putIfAbsent(parentId, () => []);
          nodesByParent[parentId]!.add(Map<String, dynamic>.from(node));
        }
      }

      // 各趣味にカスタムノードを追加
      bool hobbiesUpdated = false;
      for (int i = 0; i < hobbies.length; i++) {
        final hobby = hobbies[i];
        final hobbyId = hobby['id'] as String;
        final hobbyNodeId = 'hobby_$hobbyId';

        // この趣味の直接の子ノードを取得
        final directChildren = nodesByParent[hobbyNodeId] ?? [];
        if (directChildren.isEmpty) continue;

        // 子ノードを再帰的に構築
        final children = _buildChildrenRecursively(directChildren, nodesByParent);

        // 既存のchildrenと統合（既存がある場合）
        final existingChildren = hobby['children'] as List<dynamic>? ?? [];
        hobby['children'] = [...existingChildren, ...children];
        hobbies[i] = hobby;
        hobbiesUpdated = true;
      }

      // hobbies.jsonを更新
      if (hobbiesUpdated) {
        await hobbiesFile.writeAsString(jsonEncode(hobbies));
        print('Data migration completed: Custom nodes integrated into hobbies.json');
      }

      // tree_nodes.jsonを削除
      await treeNodesFile.delete();
      print('tree_nodes.json deleted after successful migration');
    } catch (e) {
      print('Migration to v1.3.0 failed: $e');
      rethrow;
    }
  }

  /// 子ノードを再帰的に構築するヘルパーメソッド
  static List<Map<String, dynamic>> _buildChildrenRecursively(
    List<Map<String, dynamic>> nodes,
    Map<String, List<Map<String, dynamic>>> nodesByParent,
  ) {
    return nodes.map((node) {
      final nodeId = node['id'] as String;
      final childNodes = nodesByParent[nodeId] ?? [];

      // HobbyNode形式に変換
      final hobbyNode = {
        'id': nodeId,
        'title': node['title'] ?? '',
        'description': node['description'],
        'order': node['order'] ?? 0,
        'createdAt': node['createdAt'] ?? DateTime.now().toIso8601String(),
        'updatedAt': node['updatedAt'],
        'children': childNodes.isNotEmpty
            ? _buildChildrenRecursively(childNodes, nodesByParent)
            : <Map<String, dynamic>>[],
      };

      return hobbyNode;
    }).toList();
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