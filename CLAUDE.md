# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

- **Run the app**: `flutter run`
- **Hot reload**: `r` (while app is running)
- **Analyze code**: `flutter analyze`
- **Run tests**: `flutter test`
- **Build for release**: `flutter build apk` (Android) or `flutter build ios` (iOS)
- **Get dependencies**: `flutter pub get`
- **Clean build cache**: `flutter clean`

## Architecture Overview

This is a Flutter app called "シューマイ" (shuumy) - a hobby tracking application with image-based hobby icons displayed in a grid layout.

### State Management
- Uses **Riverpod** (`flutter_riverpod`) for state management
- Main provider: `hobbyListProvider` in `lib/src/providers/hobby_list_provider.dart`

### Data Flow
1. **Models**: 
   - `Hobby` class with unique IDs for identification and management
   - `HobbyMemo` class for text+image memo functionality
2. **Storage**: 
   - `HobbyJsonService` for hobby data persistence
   - `MemoService` for memo data persistence  
   - `BackgroundImageService` for custom background management
3. **State**: `HobbyListNotifier` manages the list of hobbies and persists changes
4. **UI**: Grid-based layout with customizable background, detailed screens, and memo functionality

### File Structure
- `lib/main.dart` - App entry point with MaterialApp and ProviderScope
- `lib/src/models/` - Data models (Hobby, HobbyMemo)
- `lib/src/providers/` - Riverpod state providers
- `lib/src/screens/` - UI screens (HomeScreen, AddHobbyScreen, DetailHobbyScreen, Settings screens)
- `lib/src/services/` - Data services (JSON storage, memo management, background image service)
- `assets/` - Contains background image and app icon

### Key Dependencies
- `flutter_riverpod` - State management
- `image_picker` - Image selection functionality  
- `path_provider` - File system access
- `uuid` - Unique identifier generation
- `path` - Path manipulation utilities
- `url_launcher` - Email and external URL handling
- `package_info_plus` - App version information
- `in_app_purchase` - App内課金・サブスクリプション管理

### Data Storage
- **Hobbies**: `hobbies.json` in device's application documents directory
- **Memos**: `memos.json` with text content and optional image attachments
- **Background settings**: `background_settings.json` for custom background configuration
- **Images**: Stored in `{documents}/images/` and `{documents}/backgrounds/` directories
- **File naming**: Uses UUID for all image files to avoid conflicts

## Development Guidelines

### UI/UX Design Principles
- **Design style**: Twitter-inspired clean, minimal design with white backgrounds
- **Home screen**: iOS-style grid layout with customizable background image
- **Icon style**: iPhone-style rounded square icons (not circles) with shadow
- **Grid layout**: 4 columns, fixed aspect ratio for hobby icons
- **Navigation**: Bottom floating dock with add/settings buttons
- **Brand color**: #009977 (primary green) with complementary #00B386 for accents

### Code Conventions
- **File organization**: Follow existing `lib/src/` structure (models, providers, screens, services)
- **State management**: Use Riverpod exclusively, avoid other state management solutions
- **Naming**: Use descriptive Japanese text for UI labels, English for code identifiers
- **Error handling**: Always provide user-friendly Japanese error messages via SnackBar

### Data Management Rules
- **Image storage**: Always use UUID for image filenames to avoid conflicts
- **JSON persistence**: Maintain backward compatibility when modifying Hobby model
- **File operations**: Use path_provider for cross-platform directory access
- **State updates**: Always persist changes to JSON when modifying hobby list

### Feature Development Approach
- **Incremental**: Add features without breaking existing functionality
- **Twitter-style UI**: Clean, flat design with minimal shadows and left-aligned layouts
- **Local-first**: Prioritize offline functionality, avoid cloud dependencies
- **Performance**: Consider grid rendering performance for large hobby collections

## Recent Major Features Added

### Memo System (2025-06-20)
- **HobbyMemo model**: Text content with optional image attachments (280 char limit)
- **AddMemoScreen**: Twitter-style memo creation interface
- **MemoService**: JSON persistence for memo data
- **DetailHobbyScreen**: Twitter-profile style layout displaying memos

### Settings & App Management
- **SettingsScreen**: Complete settings interface for app release
- **AboutScreen**: App information with real logo from assets
- **PrivacyPolicyScreen**: Comprehensive privacy policy
- **DataResetService**: Safe data deletion functionality
- **Contact**: Email integration (shuumyapp@gmail.com)

### Background Customization
- **BackgroundImageService**: Custom background image management
- **BackgroundSettingsScreen**: User-friendly background selection interface
- **Dynamic loading**: Real-time background updates in HomeScreen

### App Identity
- **App name**: Changed to "シューマイ" (katakana) across all platforms
- **Icon design**: iPhone-style rounded squares instead of circles
- **Brand integration**: Consistent use of #009977 and #00B386 colors

### Technical Improvements
- **Unique IDs**: All hobbies now have UUID for reliable identification
- **Edit/Delete**: Full CRUD operations for hobbies
- **Image management**: Automatic cleanup of unused image files
- **Error handling**: Comprehensive error handling with Japanese messages

## 現在の開発状況 (2025-07-04)

### 🎯 完了した主要機能

#### カテゴリー機能 (完全実装済み)
- **データモデル**: Category モデルと hobby.categoryId による関連付け
- **UI改造**: HomeScreenをPageView + TabBar によるカテゴリー別表示に変更
- **カテゴリー管理**: 作成・編集・削除・並び替え機能
- **背景画像**: カテゴリー別の背景画像設定機能
- **データ移行**: 既存ユーザーとの互換性確保

#### プレミアム機能 (完全実装済み)
- **3段階料金体系**: 月額・年額・買い切りプラン
- **機能制限**: 無料版ではカテゴリー機能を制限
- **購入・復元**: App内課金による購入とサブスクリプション管理
- **UI**: プレミアムプラン選択画面とサブスクリプション情報表示

#### App Store Connect 設定
- **商品登録完了**: 3つの商品IDで設定済み
  - `shuumy_premium_monthly`
  - `shuumy_premium_yearly` 
  - `shuumy_premium_lifetime`

### ⚠️ 現在の課題・検討事項

#### 価格設定（App Store Connect設定済み）
**最終決定済み価格:**
- 月額: ¥300
- 年額: ¥2,500
- 買い切り: ¥5,000

**設定状況:**
- App Store Connect で日本円での価格設定完了
- 3段階の料金体系でバランス良く設定

### 🔧 技術実装詳細

#### PremiumService の主要機能
- **サブスクリプション管理**: 期限追跡、自動期限切れ処理
- **購入復元**: 手動復元機能とエラーハンドリング
- **商品情報取得**: 複数商品の価格・詳細情報取得
- **デバッグ機能**: テスト用のプレミアム状態設定

#### CategoryService の主要機能  
- **CRUD操作**: カテゴリーの作成・読み取り・更新・削除
- **並び替え**: ドラッグ&ドロップによる順序変更
- **背景画像**: カテゴリー別背景画像の管理
- **安全削除**: 関連する趣味の自動移行

### 📱 次回作業時の確認事項

1. **価格表示問題の解決**
   - ドル表記で表示される問題の調査・修正
   - 日本円での正確な価格表示確認

2. **動作確認 (Sandbox環境)**
   - 実機でのApp内課金テスト
   - プレミアム機能の動作確認
   - サブスクリプション管理テスト

3. **審査提出準備**
   - 最終的な動作確認
   - App Store Connect での審査提出

### 🎨 アプリの現在の構成

**メイン画面**: PageView + TabBar による カテゴリー別趣味表示
**プレミアム機能**: カテゴリー作成・管理・背景設定
**料金体系**: 3段階プラン (価格見直し予定)
**審査状況**: App Store Connect 設定完了、実機テスト待ち

## 最新の開発状況 (2025-07-08)

### ✅ 完了した作業 (2025-07-08)

#### Material Design 3 完全対応とUI最適化
- **テーマ設定**: main.dartでMaterial Design 3テーマを緑色ブランドカラー (#009977) で統一
- **半透明要素の置き換え**: ホーム画面のツールバー・カテゴリ名を MD3 の surfaceContainer に変更
- **ReorderableListView改善**: 二重表示問題を公式推奨の MediaQuery.removePadding で解決
- **動的影効果**: スクロール時のみ表示される自然な影をカテゴリ名上部に実装
- **UIポリッシュ**: 
  - アイコンの中央配置修正 (Icons.arrow_back_ios_new 使用)
  - 空状態表示の最適化 (ツールバー重複回避)
  - ScrollController の適切な管理 (カテゴリ別インスタンス)
- **コミット**: a1bd6e4 で全変更を保存済み

#### 技術的改善詳細
- **カテゴリ別ScrollController**: `Map<String, ScrollController>` で複数ビューの競合を解決
- **動的影システム**: スクロール位置に応じて影の表示/非表示を制御
- **MD3カラーシステム**: ColorScheme.fromSeed で一貫したテーマ適用
- **プロキシデコレーター**: ReorderableListView で MediaQuery パディング削除

### 🔄 次の作業タスク

1. **背景設定画面の動作確認**
   - カテゴリー別背景画像の設定・変更テスト
   - 画像選択・保存・削除の動作確認
   - プレミアム機能制限の動作確認

2. **カテゴリ並べ替えの動作確認**
   - カテゴリ管理画面のドラッグ&ドロップ機能テスト
   - 並び替え後の永続化確認
   - ホーム画面での表示順序反映確認

3. **活動記録機能の相談**
   - 既存のメモ機能との連携検討
   - 新機能の設計・実装方針の議論
   - UI/UX設計の相談

### 🎯 現在の技術状況
- **UI統一性**: Material Design 3 完全準拠
- **パフォーマンス**: スクロール最適化・メモリ効率改善
- **コード品質**: 型安全性・エラーハンドリング強化
- **ユーザビリティ**: 直感的な操作性・視覚的フィードバック改善