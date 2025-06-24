import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class BackgroundImageService {
  static const _settingsFileName = 'background_settings.json';
  static const _backgroundDirName = 'backgrounds';

  /// 現在の背景画像設定を取得
  static Future<BackgroundImageConfig> getCurrentConfig() async {
    try {
      final file = await _getSettingsFile();
      if (!(await file.exists())) {
        return BackgroundImageConfig.defaultConfig();
      }

      final contents = await file.readAsString();
      final jsonData = jsonDecode(contents);
      return BackgroundImageConfig.fromJson(jsonData);
    } catch (e) {
      return BackgroundImageConfig.defaultConfig();
    }
  }

  /// 背景画像設定を保存
  static Future<void> saveConfig(BackgroundImageConfig config) async {
    final file = await _getSettingsFile();
    final jsonData = config.toJson();
    await file.writeAsString(jsonEncode(jsonData));
  }

  /// カスタム背景画像を保存
  static Future<String> saveCustomBackground(File imageFile) async {
    final dir = await getApplicationDocumentsDirectory();
    final backgroundDir = Directory(path.join(dir.path, _backgroundDirName));
    
    if (!(await backgroundDir.exists())) {
      await backgroundDir.create(recursive: true);
    }

    final fileName = 'custom_${DateTime.now().millisecondsSinceEpoch}.${path.extension(imageFile.path)}';
    final savedFile = File(path.join(backgroundDir.path, fileName));
    await imageFile.copy(savedFile.path);
    
    return fileName;
  }

  /// カスタム背景画像のファイルを取得
  static Future<File?> getCustomBackgroundFile(String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = path.join(dir.path, _backgroundDirName, fileName);
      final file = File(filePath);
      
      return await file.exists() ? file : null;
    } catch (e) {
      return null;
    }
  }

  /// 使用されていないカスタム背景画像を削除
  static Future<void> cleanupUnusedBackgrounds(String? currentFileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final backgroundDir = Directory(path.join(dir.path, _backgroundDirName));
      
      if (!(await backgroundDir.exists())) return;

      final files = await backgroundDir.list().toList();
      for (final file in files) {
        if (file is File) {
          final fileName = path.basename(file.path);
          if (fileName != currentFileName) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      // エラーは無視（クリーンアップは重要ではない）
    }
  }

  /// デフォルト背景に戻す
  static Future<void> resetToDefault() async {
    final config = BackgroundImageConfig.defaultConfig();
    await saveConfig(config);
    await cleanupUnusedBackgrounds(null);
  }

  static Future<File> _getSettingsFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(path.join(dir.path, _settingsFileName));
  }
}

/// 背景画像の設定クラス
class BackgroundImageConfig {
  final BackgroundType type;
  final String? customFileName;

  const BackgroundImageConfig({
    required this.type,
    this.customFileName,
  });

  /// デフォルト設定（白背景）
  factory BackgroundImageConfig.defaultConfig() {
    return const BackgroundImageConfig(type: BackgroundType.none);
  }

  /// カスタム画像設定
  factory BackgroundImageConfig.custom(String fileName) {
    return BackgroundImageConfig(
      type: BackgroundType.custom,
      customFileName: fileName,
    );
  }

  factory BackgroundImageConfig.fromJson(Map<String, dynamic> json) {
    return BackgroundImageConfig(
      type: BackgroundType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BackgroundType.none,
      ),
      customFileName: json['customFileName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'customFileName': customFileName,
    };
  }

  /// 背景画像のImageProviderを取得
  Future<ImageProvider?> getImageProvider() async {
    switch (type) {
      case BackgroundType.none:
        return null; // 白背景（画像なし）
      case BackgroundType.custom:
        if (customFileName != null) {
          final file = await BackgroundImageService.getCustomBackgroundFile(customFileName!);
          if (file != null) {
            return FileImage(file);
          }
        }
        // カスタム画像が見つからない場合は白背景
        return null;
    }
  }
}

enum BackgroundType {
  none,          // 背景画像なし（白背景）
  custom,        // ユーザーが選択したカスタム画像
}