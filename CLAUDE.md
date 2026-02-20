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

## App Store 審査対応完了 (2025-07-31)

### 🚨 審査指摘事項と対応

#### 初回審査結果 (v1.1.0+2)
App Storeから以下3点の指摘を受けた：

1. **Guideline 2.1 - App内課金商品未提出**
   - 問題: プレミアム機能があるがApp内課金商品が審査未提出
   - 対応: App Store Connectで3商品（月額・年額・買い切り）を審査提出

2. **Guideline 3.1.1 - 購入復元機能不備**  
   - 問題: 「購入を復元」ボタンが無い
   - 対応: 設定画面に明示的な「購入を復元」ボタンを追加実装

3. **Guideline 3.1.2 - 利用規約リンク不備**
   - 問題: サブスクリプション用利用規約リンクが無い
   - 対応: 利用規約ページ作成＋アプリ内外リンク追加

### ✅ 実装完了項目

#### コード修正 (2025-07-31)
- **settings_screen.dart**: 「購入を復元」ボタン追加（メニュー項目として）
- **terms_of_use_screen.dart**: 完全な利用規約ページ新規作成
- **premium_plan_selection_screen.dart**: 法的リンク（利用規約・プライバシーポリシー）追加
- **バージョン管理**: v1.1.0+2 維持（審査継続のため）

#### App Store Connect設定
- **App内課金商品**: 3商品の審査提出完了
  - shuumy_premium_monthly (¥300)
  - shuumy_premium_yearly (¥2,500)  
  - shuumy_premium_lifetime (¥5,000)
- **メタデータ**: 利用規約リンク追加完了

#### ビルド・提出
- **flutter build ios --release**: リリースビルド作成
- **Xcode Archive**: Product → Archive → Distribute App
- **再審査申請**: 2025-07-31 完了

### 🎯 審査対応成果

#### 技術的改善
- **App Store審査要件**: 完全準拠
- **法的コンプライアンス**: 利用規約・プライバシーポリシー完備
- **ユーザビリティ**: 購入復元機能の明確化

#### 開発プロセス改善
- **審査指摘の迅速対応**: 指摘から24時間以内に修正完了
- **バージョン管理**: 審査プロセスに適した版数管理
- **コード品質**: 機能追加でも既存機能への影響ゼロ

### 📱 次回審査結果待ち

#### 期待される結果
- **審査通過**: 指摘事項すべて対応済み
- **App Store公開**: シューマイ v1.1.0+2 正式リリース
- **プレミアム機能**: App内課金3プラン提供開始

#### 今後の開発方針
- **ユーザーフィードバック対応**: リリース後の改善要望収集
- **機能拡張**: プレミアム機能の更なる充実
- **安定性向上**: 継続的なバグ修正・パフォーマンス最適化

**審査対応完了**: App Store審査の全指摘事項に対応完了。再審査申請済み（2025-07-31）。

## App Store 再審査対応 (2025-08-01)

### 🚨 2回目審査指摘事項と対応

#### Bug Fix Submission 審査結果
**Submission ID**: d614f10c-ed7f-45cf-996c-838d9d788aad  
**Review date**: August 01, 2025  
**Version reviewed**: 1.1.0  

**指摘内容 (Guideline 3.1.2)**:
- App Store Connect のメタデータ（アプリ説明文）に利用規約リンクが不足
- サブスクリプション提供アプリの必須要件未充足

### ✅ 対応完了項目 (2025-08-01)

#### GitHub Pages 活用による解決
- **利用規約公開**: `https://tomurango.github.io/shuumy-app/terms.html` ✅
- **プライバシーポリシー**: `https://tomurango.github.io/shuumy-app/privacy.html` ✅
- **35コミットをpush**: GitHub Pages へ全変更反映完了

#### App Store Connect メタデータ更新
- **アプリ概要**: 利用規約・プライバシーポリシーURL追記完了
- **公開URL**: Web上でアクセス可能な状態を確保
- **審査要件**: Guideline 3.1.2 完全対応

### 🎯 対応の技術的詳細

#### 利用規約・プライバシーポリシー
- **既存内容**: 2025年6月20日版をそのまま活用（内容変更なし）
- **公開方法**: GitHub Pages での静的サイト公開
- **アクセス性**: App Store購入前にユーザーが確認可能

#### GitHub リポジトリ状況
- **リポジトリ**: `tomurango/shuumy-app`
- **Pages URL**: `https://tomurango.github.io/shuumy-app/`
- **push状況**: ローカル35コミットを完全同期
- **公開状態**: 利用規約・プライバシーポリシーが正常表示

### 📱 現在の審査状況

#### 今回の対応内容
- **問題の本質**: アプリ内実装済みだが、App Store Connect メタデータに記載なし
- **解決方法**: GitHub Pages + App Store Connect 説明文更新
- **対応時期**: 2025-08-01 即日対応完了

#### 次回審査への期待
- **Guideline 3.1.2**: 完全対応済み
- **技術要件**: Web公開・メタデータ記載の両方クリア
- **審査通過可能性**: 高（指摘事項を正確に解決）

#### バックアップ対応策
- **Bug Fix Option**: Appleが提示した「次回更新で解決」オプションも利用可能
- **現在選択**: 即座の問題解決を選択（メタデータ更新）

### 🚀 次回作業時の確認事項

1. **審査結果確認**: App Store Connect での通知確認
2. **公開準備**: 審査通過後のリリース作業
3. **ユーザー対応**: リリース後のフィードバック収集体制

**最新状況**: 2025-08-01時点で Guideline 3.1.2 の審査指摘に完全対応済み。GitHub Pages 公開 + App Store Connect メタデータ更新による解決完了。

## コードリファクタリング実施 (2025-09-11)

### 🎯 リファクタリングの目的
大きくなった `home_screen.dart` (3752行) の可読性とメンテナビリティ向上を目的とした構造改善を実施。

### 📁 新しいディレクトリ構造
```
lib/src/
├── screens/
│   ├── home/
│   │   └── widgets/
│   │       └── hobby_card_widget.dart      # 趣味カードウィジェット
│   ├── hobby/                              # 将来の趣味関連画面用
│   ├── memo/                               # 将来のメモ関連画面用 
│   └── settings/                           # 将来の設定関連画面用
├── shared/
│   ├── widgets/
│   │   └── hobby_options_sheet.dart        # 趣味オプションシート
│   └── utils/                              # 将来の共通ユーティリティ用
└── models/ services/ providers/            # 既存構造は維持
```

### ✅ 実装完了項目

#### HobbyCardWidget の抽出
- **元の場所**: `home_screen.dart` の `_buildHobbyCard()` 関数（~200行）
- **新しい場所**: `lib/src/screens/home/widgets/hobby_card_widget.dart`
- **機能**: 趣味カードの表示、Hero アニメーション、オプションメニュー連携

#### HobbyOptionsSheet の抽出  
- **元の場所**: `home_screen.dart` の `_showOptionsMenu()`, `_buildOptionTile()` 関数
- **新しい場所**: `lib/src/shared/widgets/hobby_options_sheet.dart`
- **機能**: 趣味編集・削除のボトムシート、確認ダイアログ

#### home_screen.dart の最適化
- **削除されたコード**: 約250行の関数とヘルパーメソッド
- **追加されたインポート**: 新しく作成したウィジェット
- **更新された呼び出し**: 新しいウィジェットを使用するように修正

### 🔧 技術的改善

#### コンポーネント分離の効果
- **責任の分離**: 各ウィジェットが単一の責任を持つ
- **再利用性向上**: 他の画面でも使用可能なコンポーネント
- **テスト容易性**: 独立したウィジェットのテストが可能
- **保守性向上**: 変更時の影響範囲を局所化

#### Hero ウィジェット重複問題の解決
- **問題**: リオーダーモード時の Hero tag 重複エラー
- **解決策**: モード別の Hero tag 生成
  ```dart
  tag: isReorderMode 
      ? 'hobby_image_reorder_${hobby.id}'  // リオーダーモード時
      : 'hobby_image_${hobby.id}',         // 通常モード時
  ```

#### カテゴリー連携機能の修正
- **問題**: 趣味追加時に現在のカテゴリーが初期選択されない
- **解決策**: AddHobbyScreen に `initialCategoryId` パラメータを渡すように修正
- **対象箇所**: Empty State の追加ボタン、ツールバーの FAB

### 📊 定量的改善効果

#### ファイルサイズの改善
- **home_screen.dart**: 3752行 → 約3500行（約250行削減）
- **新規ファイル**: 2ファイル（約300行）
- **コードの分散**: 単一の巨大ファイル → 複数の焦点を絞ったファイル

#### 保守性の向上
- **関心の分離**: UI コンポーネントごとに独立したファイル
- **依存関係の明確化**: インポート文で依存関係が明確
- **変更時の安全性**: 局所的な変更による影響範囲の限定

### 🏗️ アーキテクチャへの影響

#### スケーラビリティの向上
- **将来の拡張性**: 新しいディレクトリ構造により機能追加が容易
- **チーム開発**: 複数開発者による並行開発が可能
- **コードレビュー**: 小さなファイル単位でのレビューが効率的

#### 既存機能への影響
- **完全な後方互換性**: 既存の機能・UI・UX に変更なし
- **パフォーマンス**: ウィジェット分離によるビルド最適化
- **動作確認**: Hero アニメーション、カテゴリー選択の正常動作を確認

### 🔮 今後のリファクタリング方針

#### 第二段階の候補
1. **活動記録関連**: `_buildActivityRecordContent` 系の関数群
2. **設定画面**: `settings_screen.dart` の分割
3. **共通ウィジェット**: 複数画面で使用されるコンポーネントの抽出

#### 継続的改善項目
- **型安全性の向上**: より厳密な型定義
- **エラーハンドリング**: 統一されたエラー処理パターン
- **パフォーマンス**: レンダリング最適化とメモリ使用量の削減

**リファクタリング成果**: コードベースの保守性が大幅に向上し、将来の機能追加とチーム開発への準備が整った。

## App Store アップデート準備 (v1.1.1+3) (2025-09-11)

### 🎯 アップデート内容
今回のアップデートは主に内部的な品質改善とバグ修正を含むメンテナンスリリースです。

#### 主な改善項目
- **安定性向上**: 特定操作時のエラーを修正し、アプリの安定性を改善
- **パフォーマンス最適化**: 内部コードの最適化により、アプリの動作速度を向上
- **UI/UX調整**: 趣味追加時のカテゴリー選択がより直感的に動作するよう改善
- **保守性向上**: 内部コードの構造改善により、今後の機能追加準備を完了

### 📱 App Store 用リリースノート

#### 日本語版 (App Store 用)
```
バージョン 1.1.1 の新機能

🔧 安定性とパフォーマンスの向上
• アプリの動作をより安定させるための内部改善を実施
• 趣味追加時のカテゴリー選択機能を改善
• 全体的な動作速度の最適化

🐛 バグ修正
• 特定の操作で発生していたエラーを修正
• アニメーション表示の問題を解決

いつもシューマイをご利用いただき、ありがとうございます。
今後もより使いやすいアプリを目指して改善を続けてまいります。
```

### 🏗️ ビルドとアップロード手順

#### 1. リリースビルドの作成
```bash
flutter clean
flutter pub get
flutter build ios --release
```

#### 2. Xcode でのアーカイブ
1. Xcode で `ios/Runner.xcworkspace` を開く
2. Product > Archive を実行
3. Organizer で「Distribute App」を選択
4. App Store Connect にアップロード

#### 3. App Store Connect での設定
- **バージョン**: 1.1.1
- **ビルド番号**: 3
- **リリースノート**: 上記の日本語版を使用
- **価格とApp内課金**: 既存設定を維持

#### 4. 審査提出
- メタデータの更新確認
- スクリーンショットの更新は不要（UI変更なし）
- 審査用情報の更新

### 📋 アップデート後の確認事項

#### ユーザー体験の確認
- 趣味追加時のカテゴリー自動選択の動作
- アプリ全体の安定性とパフォーマンス
- 既存機能への影響がないことの確認

#### 今後の開発方針
- ユーザーフィードバックの監視
- 次回大型アップデートの準備
- 新機能開発のための基盤整備完了

**次回作業**: リリースビルド作成 → Xcode アーカイブ → App Store Connect アップロード → 審査提出

## App Store 審査提出完了 (v1.1.1+3) (2025-09-11)

### ✅ 提出完了項目

#### リリース準備完了
- **バージョン**: 1.1.1+3
- **リリースビルド**: 30.5MB (正常完了)
- **Xcode アーカイブ**: 完了
- **App Store Connect アップロード**: 完了
- **審査提出**: 2025-09-11 完了

#### App Store 設定内容
- **プロモーションテキスト**: 「安定性とパフォーマンスが大幅向上！趣味管理がより快適に。カテゴリー選択の改善、エラー修正、動作速度最適化を実施。あなたの趣味ライフをもっとスムーズにサポートします。」(84文字)
- **最新情報**: バグ修正・安定性向上・UX改善を中心とした内容 (580文字)
- **価格設定**: 無料 + App内課金3プラン維持

#### 技術的成果
- **Hero ウィジェット重複エラー**: 完全修正
- **カテゴリー自動選択**: UX改善実装
- **コードリファクタリング**: 250行削減、保守性向上
- **新ディレクトリ構造**: 将来拡張への準備完了

### 📋 審査期間中の注意事項
- **想定審査期間**: 24-48時間
- **リジェクト時対応**: 迅速修正体制
- **リリース後監視**: ユーザーフィードバック収集
- **次回アップデート**: 新機能開発準備

### 🎯 今回のアップデート成果まとめ
1. **安定性**: アプリクラッシュ要因を解決
2. **パフォーマンス**: 内部最適化による動作向上
3. **UX**: より直感的なカテゴリー選択
4. **コード品質**: 大幅なリファクタリング完了
5. **拡張性**: 新機能追加基盤の整備

**開発完了**: メンテナンスリリース v1.1.1+3 の開発・提出が完了。ユーザー体験の向上と将来の機能拡張への準備が整った。

## App Store 審査通過・リリース完了 (v1.1.2+1) (2025-09-11)

### 🎉 審査結果
- **審査状況**: ✅ 審査通過
- **リリース日**: 2025-09-11
- **公開バージョン**: 1.1.2+1
- **審査所要時間**: 約24-48時間（想定通り）

### ✅ リリース成果
- **メンテナンスリリース**: 安定性・パフォーマンス・UX改善を含む品質向上アップデート
- **審査プロセス**: スムーズに通過、リジェクト無し
- **App Store公開**: 全ユーザーに配信開始

### 📱 現在の App Store 状態
- **最新バージョン**: 1.1.2 (ビルド 1)
- **App内課金**: 3プラン正常動作中
- **ダウンロード**: 利用可能
- **評価**: ユーザーフィードバック収集中

### 🔮 次期開発に向けて
- **安定版確立**: v1.1.2+1 が最新の安定版として公開中
- **フィードバック収集**: ユーザーレビュー・要望の監視体制
- **次回アップデート準備**: 新機能開発の基盤が整った状態
- **技術的負債解消**: リファクタリングにより保守性が大幅向上

**リリース完了**: App Store での v1.1.2+1 公開成功。メンテナンスリリースとして安定性・パフォーマンス・UX改善を全ユーザーに提供開始。

## Android版リリース準備開始 (2025-10-13)

### 🎯 プロジェクト目標
iOS版（v1.1.2+1）と同等の機能をAndroid版としてGoogle Playでリリース。

### ✅ 完了した作業

#### 開発者アカウント・環境設定
- **Google Play開発者アカウント登録**: 完了（$25の1回払い、本人確認済み）
- **アプリケーションID変更**: `com.example.shuumy` → `com.tomurango.shuumy`（iOS版に統一）
- **Kotlinパッケージ移行**: `com/example/shuumy/` → `com/tomurango/shuumy/`

#### リリース署名設定
- **キーストア作成**: `upload-keystore.jks` 作成完了
  - キーエイリアス: upload
  - 有効期限: 10000日
  - 保存場所: `~/upload-keystore.jks`
- **署名設定ファイル**: `android/key.properties` 作成
- **build.gradle.kts更新**:
  - リリース署名設定追加
  - インポート文追加（`java.util.Properties`, `java.io.FileInputStream`）

#### ビルド成功
- **AABファイル**: `app-release.aab` 作成成功（23.3MB）
- **ビルドコマンド**: `flutter build appbundle --release`
- **署名状態**: リリース用キーストアで正常に署名済み

#### Google Play Console設定
- **アプリ作成**: 「シューマイ」登録完了
- **基本情報設定**:
  - アプリ名: シューマイ
  - デフォルト言語: 日本語（日本）
  - カテゴリ: ライフスタイル
  - 無料アプリ

#### ストア掲載情報
- **簡単な説明**: 作成済み（47文字）
- **詳しい説明**: 作成済み（約770文字）
- **スクリーンショット**: Pixel 2エミュレーターで撮影（1080x1920）
  - Android Studio Device Manager使用
  - Pixel_2_API_32 エミュレーター作成
  - 複数画面のスクリーンショット撮影完了

#### アプリコンテンツ設定
- **アプリのアクセス権**: 「アクセス制限なし」を選択
- **データの収集とセキュリティ**: 「いいえ」（ローカルストレージのみ）
- **プライバシーポリシー**: https://tomurango.github.io/shuumy-app/privacy.html
- **利用規約**: https://tomurango.github.io/shuumy-app/terms.html

### ⚠️ 現在の課題

#### Google Playの新ポリシー要件
App内課金を含むアプリは、製品版リリース前に以下が必須：
- **テスター人数**: 最低20人
- **テスト期間**: 連続14日間
- **テスト方法**: クローズドテストまたはオープンテスト

#### 対応方法の検討中
**Option A: クローズドテスト**
- メールアドレスで20人を招待
- 知人・友人 + SNS募集

**Option B: オープンテスト**
- 誰でもGoogle Playから参加可能
- SNS告知のみでOK
- より現実的な選択肢

### 📋 残りのタスク

#### テスト準備
- [ ] テスト方法の決定（クローズド/オープン）
- [ ] テスター募集用SNS告知文作成
- [ ] 内部テストリリース作成
- [ ] クローズド/オープンテストへの移行

#### App内課金設定
- [ ] Google Play Consoleでの商品登録（3プラン）
  - 月額: ¥300
  - 年額: ¥2,500
  - 買い切り: ¥5,000
- [ ] App内課金コードの動作確認

#### テスト期間
- [ ] 20人以上のテスター参加確認
- [ ] 14日間のテスト実行
- [ ] クラッシュレポート監視
- [ ] フィードバック対応

#### 製品版リリース
- [ ] テスト完了後、製品版に昇格
- [ ] 審査提出
- [ ] 審査対応

### 🔧 技術的メモ

#### ビルド時の警告（無視可能）
- **NDK version warning**: プラグインが新しいNDK要求（動作には影響なし）
- **EGL Error**: エミュレーター特有のグラフィックス警告（実機では発生しない）
- **In-App Purchase not available**: エミュレーターでは正常な挙動

#### ファイル構成変更
- `android/key.properties`: 追加（.gitignoreに登録済み）
- `android/app/build.gradle.kts`: リリース署名設定追加
- `android/app/src/main/kotlin/com/tomurango/shuumy/MainActivity.kt`: パッケージ変更

### 📱 iOS版との対応

| 項目 | iOS版 | Android版 |
|------|-------|----------|
| アプリ名 | シューマイ | シューマイ |
| Bundle/Package ID | com.tomurango.shuumy | com.tomurango.shuumy |
| バージョン | 1.1.2+1 | 1.1.2+1 |
| 月額プラン | ¥300 | ¥300 |
| 年額プラン | ¥2,500 | ¥2,500 |
| 買い切り | ¥5,000 | ¥5,000 |
| プライバシーポリシー | https://tomurango.github.io/shuumy-app/privacy.html | 同じ |
| 利用規約 | https://tomurango.github.io/shuumy-app/terms.html | 同じ |

### 🚀 次回作業時の確認事項

1. **テスター募集方法の決定**: オープンテストが推奨
2. **SNS告知の準備**: iOS版の実績をアピール
3. **タイムライン策定**: テスト開始から製品版まで約3週間を想定

**現在の状態**: Google Play Console設定完了、テスト方法の選択待ち

## メモのピン留め機能追加 (2025-02-05)

### ✅ 完了した実装 (v1.2.0+1)

#### メモのピン留め機能
- **HobbyMemoモデル**: `isPinned`フィールド追加
- **MemoService**: `togglePinMemo()`メソッド実装
- **ソート機能**: ピン留めメモを最上位に自動表示
- **UI実装**: ピンアイコン表示とメニュー項目追加
- **複数ピン留め対応**: ユーザーが必要な数だけピン留め可能

#### UI/UX改善
- メモの「...」ボタンを右端に配置
- 保存ボタンのテキストを「投稿」→「保存」に統一

#### バージョン管理
- **iOS版**: 1.2.0+1
- **Xcode Archive**: 作成済み（App Store提出準備完了）

## 活動記録機能の大幅リニューアル計画 (2025-02-05)

### 🎯 新機能の方針

#### 現在の活動記録機能（v1.2.0）
- **アクセス方法**: ホーム画面右下のツールバーからカテゴリごとに切り替え
- **表示内容**: カレンダー形式でメモの活動記録を可視化
- **期間選択**: 2週間・月間・年間の3つの表示モード
- **データソース**: 既存のメモ（HobbyMemo）を集計

#### 新しい活動記録機能の設計（v1.3.0予定）

##### 1. 統合活動記録画面への変更
**変更内容:**
- **アクセス方法の変更**: ホーム画面のツールバーから → 設定画面内の専用メニュー項目へ移動
- **表示形式**: 全カテゴリーの活動記録をまとめて表示
- **カテゴリーフィルター**: 画面上部でカテゴリーを選択して切り替え可能

**メリット:**
- ホーム画面の操作がシンプルになる
- 全体の活動記録を俯瞰しやすい
- 設定画面が充実し、統計・分析機能の印象を強化

##### 2. トーナメント表／樹形図機能の追加
**コンセプト:**
- メモとは**別の新しい記録形式**として実装
- トーナメント表や樹形図のような**階層構造**を持つデータ記録
- 趣味の進捗や目標達成の過程を視覚的に追跡

**想定されるユースケース:**
- スポーツの大会結果記録（トーナメント表）
- スキルツリーの進捗管理（樹形図）
- 目標の段階的達成記録（マイルストーン）
- プロジェクトの進行状況（ガントチャート風）

**技術的検討事項:**
- **新しいデータモデル**: `TreeNode` or `TournamentRecord`
- **データ構造**: 親子関係を持つノード形式
- **UI実装**: カスタムペイントまたはグラフライブラリ使用
- **保存形式**: JSON with 階層構造

### 📋 実装計画

#### Phase 1: 活動記録画面の移動
1. 設定画面に「活動記録」メニュー項目を追加
2. 専用の活動記録画面を新規作成
3. 既存のカレンダー表示機能を移植
4. ホーム画面のツールバーから活動記録ボタンを削除

#### Phase 2: 樹形図機能の設計
1. データモデルの設計（TreeNode / TournamentRecord）
2. UI/UXデザインの決定（表示形式・操作方法）
3. ユーザーストーリーの明確化
4. 技術スタックの選定（描画ライブラリ等）

#### Phase 3: 実装
1. データモデル実装
2. サービス層実装（CRUD操作）
3. UI実装（樹形図の描画・編集）
4. 既存の活動記録画面との統合

### 🔍 検討が必要な詳細項目
- 樹形図の具体的な表示形式（トーナメント表 vs ツリー構造 vs その他）
- ユーザーが作成・編集する際の操作フロー
- メモとの関連性（リンクするか独立させるか）
- プレミアム機能としての位置付け

**現在の状態**: v1.2.0 Archive作成済み、新機能の設計段階

## Phase 1完了: 活動記録画面の移行 (2025-02-09)

### ✅ 完了した作業

#### 活動記録機能の専用画面化
- **新規ファイル**: `activity_record_screen.dart`（1,391行）
- **設定画面**: 「活動記録」メニュー項目追加
- **カレンダー機能移植**: 2週間・月間・年間ビューの完全移植
- **ホーム画面シンプル化**: 3,301行 → 1,259行（62%削減）

#### 改善効果
- **コードの責任分離**: 活動記録とホーム画面を完全分離
- **可読性向上**: 巨大なhome_screen.dartを分割
- **保守性向上**: 複雑なアニメーションロジック削除
- **ホーム画面の専念**: 趣味グリッド表示に集中

### 🎯 次のステップ
Phase 2: 樹形図機能の詳細設計 → Phase 3: 実装

## Phase 2詳細設計: 樹形図機能 (2025-02-09)

### 🎨 樹形図機能の全体像

#### コンセプト
既存のカテゴリー・趣味データを**ルート構造**として利用し、その下に自由な階層構造を追加できる「構造整理ツール」

#### 階層構造の定義

```
[ルート（非表示）]
    │
    ├── カテゴリA（読み取り専用・既存データ）
    │   ├── 趣味1（読み取り専用・既存データ）
    │   │   ├── ノードA（編集可能・新規追加）
    │   │   │   ├── ノードA-1（編集可能）
    │   │   │   └── ノードA-2（編集可能）
    │   │   └── ノードB（編集可能・新規追加）
    │   │       └── ノードB-1（編集可能）
    │   │
    │   └── 趣味2（読み取り専用・既存データ）
    │       └── ノードC（編集可能・新規追加）
    │
    └── カテゴリB（読み取り専用・既存データ）
        └── 趣味3（読み取り専用・既存データ）
            ├── ノードD（編集可能・新規追加）
            └── ノードE（編集可能・新規追加）
```

**階層レベル:**
- **Level 0（表示）**: ルートノード（シューマイアイコン表示）
- **Level 1（読み取り専用）**: カテゴリー（既存データから自動生成）
- **Level 2（読み取り専用）**: 趣味（既存データから自動生成）
- **Level 3以降（編集可能）**: ユーザーが自由に追加・編集できるノード

### 📊 データモデル設計

#### TreeNode モデル
```dart
class TreeNode {
  final String id;              // UUID
  final String? parentId;       // 親ノードID（null = ルート）
  final String title;           // ノードタイトル
  final String? description;    // 説明文（オプション）
  final NodeType type;          // ノードタイプ
  final DateTime createdAt;     // 作成日時
  final DateTime? updatedAt;    // 更新日時
  final int order;              // 兄弟ノード間の順序
  final bool isCompleted;       // 完了状態（チェックボックス用）

  // 既存データとの紐付け（type = category/hobby の場合のみ）
  final String? categoryId;     // カテゴリーID
  final String? hobbyId;        // 趣味ID
}

enum NodeType {
  root,       // ルートノード（非表示）
  category,   // カテゴリー（既存データ・読み取り専用）
  hobby,      // 趣味（既存データ・読み取り専用）
  custom,     // カスタムノード（編集可能）
}
```

#### データ永続化
- **ファイル名**: `tree_nodes.json`
- **保存場所**: アプリケーションドキュメントディレクトリ
- **形式**: JSON配列（フラット構造、親子関係はparentIdで管理）

### 🖼️ UI/UX設計

#### 画面構成
```
┌─────────────────────────────┐
│  ← 樹形図      🔍 ⋮          │ ← AppBar
├─────────────────────────────┤
│                             │
│  ┌───────────────┐          │
│  │  カテゴリA    │          │ ← Level 1（読み取り専用）
│  └───┬───────────┘          │
│      │                      │
│      ├─┬──────────┐         │
│      │ │ 趣味1    │         │ ← Level 2（読み取り専用）
│      │ └──┬───────┘         │
│      │    │                 │
│      │    ├─ ノードA    ✓   │ ← Level 3+（編集可能）
│      │    │  └─ ノードA-1   │
│      │    │                 │
│      │    └─ ノードB        │
│      │                      │
│      └─┬──────────┐         │
│        │ 趣味2    │         │
│        └──┬───────┘         │
│           └─ ノードC        │
│                             │
│  [+ カテゴリーを展開]       │ ← 折りたたみ可能
└─────────────────────────────┘
```

#### 画面遷移
1. **設定画面 → 樹形図画面**
   - メニューから「樹形図」を選択
   - 全体表示で開始

2. **ホーム画面（カテゴリー選択中） → 樹形図画面**
   - ツールバーに「樹形図」ボタン追加
   - 現在のカテゴリー位置に自動スクロール＆展開

3. **活動記録画面 → 樹形図画面**
   - （将来的に）カレンダーから樹形図への連携も検討

#### 操作方法

**閲覧:**
- カテゴリー・趣味をタップで展開/折りたたみ
- スクロールで全体を閲覧
- ピンチ操作でズーム（将来的に検討）

**編集（Level 3以降のみ）:**
- ノードをロングタップ → 編集メニュー表示
  - 編集
  - 削除
  - 完了/未完了切り替え
  - 子ノード追加
- ノード横の「+」ボタン → 子ノード追加
- ドラッグ&ドロップで並び替え（将来的に検討）

**追加:**
- 趣味ノードの下に「+ ノードを追加」ボタン
- タップでノード作成ダイアログ表示
- タイトル入力 → 保存

### 🔧 技術実装設計

#### サービス層
```dart
class TreeNodeService {
  // CRUD操作
  static Future<List<TreeNode>> loadAllNodes();
  static Future<void> saveNodes(List<TreeNode> nodes);
  static Future<void> addNode(TreeNode node);
  static Future<void> updateNode(TreeNode node);
  static Future<void> deleteNode(String nodeId);

  // ツリー構築
  static List<TreeNode> buildTree(List<TreeNode> flatNodes);
  static List<TreeNode> getChildren(String parentId, List<TreeNode> nodes);

  // 既存データ統合
  static Future<void> syncWithExistingData();
  static TreeNode createCategoryNode(Category category);
  static TreeNode createHobbyNode(Hobby hobby, String categoryId);
}
```

#### プロバイダー
```dart
// ツリーノードリスト
final treeNodeListProvider = StateNotifierProvider<TreeNodeListNotifier, List<TreeNode>>;

// 展開状態管理
final expandedNodesProvider = StateProvider<Set<String>>;

// 選択中のノード
final selectedNodeProvider = StateProvider<String?>;
```

#### UI実装方針
- **Flutter標準ウィジェット使用**: CustomPaintは不使用
- **ExpansionTile or ListView**: 階層表示はネストしたListViewで実装
- **インデント表示**: Paddingで階層の深さを表現
- **接続線**: Containerとborderで視覚的に表現

### 🎯 実装フェーズの詳細

#### Phase 2.1: データ層実装
1. TreeNodeモデル作成
2. TreeNodeService実装
3. JSON永続化機能
4. 既存データ同期機能

#### Phase 2.2: 状態管理
1. TreeNodeListNotifierプロバイダー作成
2. 展開状態管理
3. 選択状態管理

#### Phase 2.3: UI実装
1. 樹形図画面の基本構造
2. ツリー表示ウィジェット
3. ノード追加・編集ダイアログ
4. カテゴリー位置への自動フォーカス

#### Phase 2.4: 統合
1. 設定画面からのナビゲーション
2. ホーム画面からのナビ�ディープリンク
3. 既存データとの自動同期

### 💡 ユースケース例

#### ケース1: プログラミング学習の整理
```
カテゴリー: 勉強
  └── 趣味: Flutter開発
      ├── 基礎知識 ✓
      │   ├── Dartの文法 ✓
      │   └── ウィジェット基礎 ✓
      ├── 状態管理
      │   ├── Provider ✓
      │   ├── Riverpod（進行中）
      │   └── Bloc
      └── アプリ公開
          ├── App Store申請
          └── Google Play申請
```

#### ケース2: 資格取得の目標管理
```
カテゴリー: キャリア
  └── 趣味: 資格勉強
      ├── 基本情報技術者 ✓
      │   ├── 午前試験対策 ✓
      │   └── 午後試験対策 ✓
      └── 応用情報技術者
          ├── テキスト読了
          ├── 過去問演習
          └── 模試受験
```

### 🔍 未解決の検討事項

1. **ノードの最大階層数**: 制限を設けるか？（推奨: 10階層まで）
2. **ノードアイコン**: カスタムアイコン対応するか？
3. **ノードの色分け**: 完了状態以外の色分けは必要か？
4. **検索機能**: ノード検索機能は必要か？
5. **エクスポート機能**: 樹形図のスクリーンショット保存は？
6. **プレミアム機能**: 無料版での制限は設けるか？

### 📋 次のアクション

設計内容の確認とフィードバック受領後、Phase 2.1（データ層実装）から着手予定。

**現在の状態**: Phase 2設計完了、フィードバック待ち