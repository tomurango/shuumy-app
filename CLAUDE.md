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

## 最新の開発状況 (2025-07-25)

### ✅ 完了した作業 (2025-07-25)

#### 活動記録機能 (完全実装済み)
- **コミット**: 6596d25 で完全実装済み
- **データアーキテクチャ**: 
  - `ActivityRecordService`: 統計計算とデータ集計エンジン
  - `ActivityRecordProvider`: Riverpod状態管理
  - `PeriodInfo`モデル: 期間情報の動的生成

#### 主要機能の詳細実装
- **期間別表示**: 週間・月間・年間の切り替え可能な活動記録
- **カテゴリー別統計**: 選択中カテゴリーの活動データ集計と表示
- **インタラクティブカレンダー**: 
  - 趣味別色分け表示（HSV色空間による一意色生成）
  - 活動日の視覚的ハイライト
  - 凡例表示による趣味と色の対応
- **統計情報カード**: 
  - 総メモ数・活動日数の集計
  - 趣味別活動回数ランキング（上位5つ）
- **期間内メモ一覧**: 選択期間内のメモを時系列で表示

#### UI/UXの完全実装
- **スムーズアニメーション**: 
  - 並行実行による高速モード切り替え
  - ツールバーと背景の協調アニメーション
- **レスポンシブ期間選択**: 
  - ボトムシート形式の期間選択UI
  - 今日の日付表示と現在選択期間の明確な区別
  - 過去のみ選択可能（未来日付制限）
- **直感的操作**: 
  - ヘッダーでのフリック・タップ操作
  - 視覚的フィードバック（無効ボタンのグレーアウト）
  - ツールバーボタンの最適化配置

#### 技術実装の詳細
- **期間管理システム**: 
  - 年・月・週の動的期間情報生成
  - 未来日付への移動制限
  - 今日基準の期間計算
- **色彩システム**: 
  - 趣味名ハッシュベースの一意色生成
  - HSV色空間での鮮やかな色調統一
  - アクセシビリティ考慮の色コントラスト

### 🎯 現在の技術状況
- **活動記録**: 完全機能実装・UI最適化完了
- **Material Design 3**: 全画面MD3準拠・テーマ統一
- **パフォーマンス**: 並行処理最適化・レスポンシブUI
- **コード品質**: 型安全性・エラーハンドリング・保守性確保

## カレンダー表示の大幅改善 (2025-07-28)

### ✅ 完了した改善項目

#### 複数趣味表示の視認性向上
- **ドット強化**: 小さすぎた表示を大幅にサイズアップ
  - 2週間表示：8x8px（複数・単一統一）
  - 月間表示：7x7px（複数・単一統一）
  - 年間表示：6x6px（複数・単一統一）
- **影効果追加**: BoxShadow による立体感と視認性向上
- **表示数増加**: 複数趣味時の表示可能数を3個→5個に増加

#### 角丸四角形デザインへの統一
- **形状変更**: `BoxShape.circle` から `BorderRadius.circular()` へ
- **サイズ別角丸半径**:
  - 8x8px: 半径3px
  - 7x7px: 半径2.5px  
  - 6x6px: 半径2px
- **モダンUIの実現**: iOSライクな角丸四角形でモダンな印象

#### 日付セルの完全シンプル化
- **色変化の削除**: 活動有無による日付テキスト色変化を廃止
- **背景色統一**: 趣味色による背景色を白色に統一
- **境界線削除**: 活動表示用の境界線を完全削除
- **フォント統一**: 太字表示を廃止して `FontWeight.normal` に統一

#### 年間表示の改善
- **件数テキスト削除**: 「5件」等の表示を削除してドットのみに
- **単一趣味ドット追加**: 年間表示でも単一趣味時にドット表示
- **レイアウト統一**: 他のカレンダー表示と一貫したデザイン

#### レジェンド(色凡例)の改善
- **ドット形状統一**: 10x10px の角丸四角形（半径3px）
- **背景色変更**: 趣味色背景 → 統一グレー背景
- **コントラスト向上**: より読みやすい色設定
- **影効果追加**: レジェンドドットにも軽い影効果

### 🎨 デザイン哲学の転換
- **わかりやすさ最優先**: 装飾より視認性を重視する設計思想
- **余分な装飾の削除**: 日付の色変化・境界線・背景色などを削除
- **情報の簡潔化**: ドットのみで活動状況を表現するシンプル設計
- **統一感の確保**: 全表示モードでの一貫したビジュアル言語

### 🔧 実装技術詳細
- **BoxDecoration最適化**: borderRadius と boxShadow の効果的活用
- **色管理**: ActivityRecordService.getHobbyColor() による一貫した色生成
- **レスポンシブ設計**: 表示サイズに応じた最適なドット寸法
- **パフォーマンス**: 影効果計算の最適化と描画効率の向上

## 最新の重要修正 (2025-07-28)

### 🔧 活動記録機能の期間境界問題解決

#### 解決した問題
- **境界データ混入**: 隣接期間のデータが誤って含まれる問題を完全修正
- **2週間表示実装**: 週間から2週間表示への変更（ユーザー要望対応）
- **無料版制限強化**: 閲覧不可期間への移動を防止

#### 技術的修正内容
```dart
// 修正前（問題あり）
final startCheck = memoDate.isAfter(periodInfo.startDate.subtract(Duration(days: 1)));
final endCheck = memoDate.isBefore(periodInfo.endDate.add(Duration(seconds: 1)));

// 修正後（正確）
final startCheck = !memoDate.isBefore(periodInfo.startDate);
final endCheck = !memoDate.isAfter(periodInfo.endDate);
```

#### UI/UX改善
- **期間移動制限**: 無料版ユーザーの制限を視覚的に表示
- **ボタン制御**: 移動不可期間のボタンをグレーアウト
- **フリック制限**: 左右フリック操作でも制限を適用
- **ミリ秒精度**: 期間終了時刻を `.999` まで対応

#### パフォーマンス最適化
- **不要処理削除**: `ref.invalidate()` の過剰な使用を除去
- **自動依存管理**: Riverpodの機能を活用した効率化
- **デバッグ除去**: 本番環境用のクリーンなコード

### 📋 次期開発予定

#### 活動記録機能の拡張検討
1. **料金体系の検討**
   - 活動記録機能のプレミアム化可否
   - 既存料金プランとの整合性

2. **細かいアニメーション改善**
   - モード切り替え時の微調整
   - ユーザーフィードバックベースの最適化

#### 継続的な改善項目
- **背景設定画面**: カテゴリー別背景画像機能テスト
- **カテゴリ管理**: ドラッグ&ドロップ並び替え確認  
- **プレミアム機能**: サブスクリプション動作テスト

## App Store リリース準備 (2025-07-28)

### ✅ バージョン情報更新完了
- **アプリバージョン**: 1.0.0+1 → 1.1.0+2
- **変更理由**: 大幅な機能追加（活動記録機能・カレンダー改善）によるマイナーバージョンアップ
- **ビルド番号**: App Store Connect での更新審査用に増加

### 🚀 本リリースの主要内容
- **メジャー機能**: カレンダー表示の大幅改善（視認性重視）
- **新機能**: 活動記録モード（2週間・月間・年間表示）
- **UI改善**: 角丸四角形ドット・シンプル化・日付表示統一
- **UX改善**: アニメーション問題修正・スムーズな操作性
- **プレミアム機能**: 期間制限・カテゴリ機能の安定動作

### 📱 リリース準備チェックリスト
- [x] バージョン番号更新（pubspec.yaml）
- [x] カレンダー表示改善実装完了
- [x] 活動記録機能実装完了  
- [x] アニメーション問題修正完了
- [x] UI統一（趣味画面メモ表示左端揃え）完了
- [x] コミット履歴整理完了（32コミット）
- [x] App Store用テキスト作成完了
- [ ] 実機での最終動作確認
- [ ] App Store Connect でのビルドアップロード
- [ ] 審査用メタデータ更新
- [ ] 審査提出

## 最終開発状況まとめ (2025-07-28)

### 🎉 開発完了項目（v1.1.0）

#### カレンダー表示の完全リニューアル
- **ドット表示強化**: 3x3px → 8x8px等、大幅サイズアップで視認性劇的改善
- **角丸四角形デザイン**: モダンなiOSライクUI実現
- **統一されたサイズ**: 単一・複数趣味で同一サイズに統一
- **シンプル化**: 日付の色変化・背景色・境界線を削除
- **影効果**: BoxShadow で立体感と視認性向上

#### 活動記録機能の完全実装
- **3つの表示期間**: 2週間・月間・年間での活動振り返り
- **プレミアム機能**: 無料版は過去2週間制限、プレミアム版は全期間
- **視覚的統計**: カラフルなカレンダーと統計情報カード
- **メモ連携**: 既存メモ機能とシームレス統合

#### 技術基盤の改善
- **Material Design 3**: 完全準拠とテーマ統一
- **アニメーション修正**: 活動記録画面の表示問題解決
- **レイアウト統一**: 趣味画面メモ表示の左端揃え修正
- **パフォーマンス**: 並行処理最適化・キャッシュ管理改善

### 🚀 App Store申請準備完了

#### 提供ファイル
- **プロモーションテキスト**: 159文字、視認性改善を前面アピール
- **最新情報**: 580文字、新機能・改善点を詳細説明
- **バージョン情報**: v1.1.0+2 (マイナーバージョンアップ)

#### 次回作業時の優先タスク
1. **実機テスト**: iPhone/iPad での全機能動作確認
2. **ビルド作成**: `flutter build ios --release`
3. **アップロード**: Xcode Archive → App Store Connect
4. **メタデータ更新**: スクリーンショット・説明文更新
5. **審査提出**: Apple Review 申請

### 🔮 今後の継続開発方針
- **ユーザーフィードバック重視**: レビュー・要望への迅速対応
- **データ分析強化**: 活動記録機能の更なる充実
- **UI/UX継続改善**: 使いやすさの追求
- **安定性向上**: バグ修正・パフォーマンス最適化

**開発成果**: 大幅な機能拡張とUI改善により、ユーザビリティが劇的に向上。App Store での評価向上と新規ユーザー獲得に期待。