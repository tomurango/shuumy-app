import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'プライバシーポリシー',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // 区切り線
          Container(
            height: 1,
            color: Colors.grey[200],
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'プライバシーポリシー',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    '最終更新日: 2025年6月20日',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  _buildSection(
                    '1. 情報の収集について',
                    'shuumyアプリは、以下の情報を収集します：\n\n'
                    '• ユーザーが入力した趣味のタイトルとメモ\n'
                    '• ユーザーが選択した画像ファイル\n'
                    '• アプリの使用状況に関する基本的な情報\n\n'
                    'これらの情報はすべて端末内にのみ保存され、外部サーバーには送信されません。',
                  ),
                  
                  _buildSection(
                    '2. 情報の使用について',
                    '収集した情報は以下の目的で使用されます：\n\n'
                    '• アプリの基本機能の提供\n'
                    '• ユーザーエクスペリエンスの向上\n'
                    '• アプリの不具合修正と改善\n\n'
                    'ユーザーの個人情報を第三者と共有することはありません。',
                  ),
                  
                  _buildSection(
                    '3. データの保存について',
                    'アプリで作成されたすべてのデータ（趣味の情報、メモ、画像）は、ユーザーの端末内にのみ保存されます。\n\n'
                    'クラウドサービスや外部サーバーへのデータ送信は行いません。',
                  ),
                  
                  _buildSection(
                    '4. データの削除について',
                    'ユーザーはいつでも以下の方法でデータを削除できます：\n\n'
                    '• 個別の趣味やメモの削除\n'
                    '• 設定画面からのデータ初期化\n'
                    '• アプリのアンインストール\n\n'
                    'アプリをアンインストールすると、すべてのデータが完全に削除されます。',
                  ),
                  
                  _buildSection(
                    '5. 写真・画像へのアクセス',
                    'アプリは趣味のアイコンとメモの画像添付のために、端末の写真ライブラリへのアクセス許可を求めます。\n\n'
                    'これらの画像は端末内にコピーされ、外部に送信されることはありません。',
                  ),
                  
                  _buildSection(
                    '6. 第三者サービスについて',
                    '本アプリは基本的に第三者サービスを使用しませんが、以下の場合があります：\n\n'
                    '• App Storeでのアプリ配布\n'
                    '• クラッシュレポートの送信（匿名化された情報のみ）',
                  ),
                  
                  _buildSection(
                    '7. お問い合わせ',
                    'プライバシーポリシーに関するご質問は、アプリ内の「お問い合わせ」機能よりご連絡ください。',
                  ),
                  
                  _buildSection(
                    '8. プライバシーポリシーの変更',
                    '本プライバシーポリシーは、法令の変更やアプリの機能追加に伴い更新される場合があります。\n\n'
                    '重要な変更がある場合は、アプリ内で通知いたします。',
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black87,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}