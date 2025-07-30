import 'package:flutter/material.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

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
          '利用規約',
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
                    'シューマイ アプリ利用規約',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '最終更新日: 2025年7月30日',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  _buildSection(
                    '第1条（適用）',
                    'この利用規約（以下「本規約」）は、シューマイ（以下「本アプリ」）の利用条件を定めるものです。ユーザーの皆様（以下「ユーザー」）には、本規約に従って本アプリをご利用いただきます。',
                  ),
                  
                  _buildSection(
                    '第2条（利用登録）',
                    '本アプリの利用にあたり、特別な登録手続きは必要ありません。本アプリをダウンロードし、使用を開始した時点で、本規約に同意したものとみなします。',
                  ),
                  
                  _buildSection(
                    '第3条（サービス内容）',
                    '本アプリは、ユーザーが趣味や活動を記録・管理するためのツールを提供します。趣味の記録、メモの作成、カテゴリー管理、活動記録の閲覧などの機能をご利用いただけます。',
                  ),
                  
                  _buildSection(
                    '第4条（プレミアム機能）',
                    '本アプリでは、一部の機能をプレミアム機能として提供しています。プレミアム機能をご利用いただくには、所定の料金をお支払いいただく必要があります。プレミアム機能の内容および料金については、アプリ内に表示される内容に従います。',
                  ),
                  
                  _buildSection(
                    '第5条（サブスクリプション）',
                    '月額・年額プランをご購入いただいた場合、自動更新サブスクリプションが適用されます。サブスクリプションは、ユーザーがキャンセルするまで自動的に更新されます。キャンセルは、App Storeの設定から行うことができます。',
                  ),
                  
                  _buildSection(
                    '第6条（料金）',
                    'プレミアム機能の料金は以下の通りです：\n・月額プラン: ¥300\n・年額プラン: ¥2,500\n・買い切りプラン: ¥5,000\n\n料金は変更される場合があります。変更が生じる場合は、事前にアプリ内で通知いたします。',
                  ),
                  
                  _buildSection(
                    '第7条（返金）',
                    'App内課金による支払いについては、Appleの返金ポリシーに従います。返金に関するお問い合わせは、App Storeまでお願いいたします。',
                  ),
                  
                  _buildSection(
                    '第8条（禁止事項）',
                    'ユーザーは、本アプリの利用にあたり、以下の行為をしてはなりません：\n・本アプリの逆コンパイル、逆アセンブル、リバースエンジニアリング\n・本アプリの複製、改変、配布\n・本アプリを商用目的で使用すること\n・法令に違反する行為',
                  ),
                  
                  _buildSection(
                    '第9条（免責事項）',
                    '本アプリの利用により生じた損害について、当方は一切の責任を負いません。本アプリは現状有姿で提供され、完全性、正確性、信頼性について保証するものではありません。',
                  ),
                  
                  _buildSection(
                    '第10条（データの保護）',
                    'ユーザーのデータは、ユーザーのデバイス内にのみ保存され、外部サーバーには送信されません。ただし、デバイスの故障、紛失、アプリの削除等により、データが失われる可能性があります。重要なデータは別途バックアップを取ることをお勧めします。',
                  ),
                  
                  _buildSection(
                    '第11条（規約の変更）',
                    '本規約は、必要に応じて変更される場合があります。変更後の規約は、アプリ内に掲示された時点で効力を生じるものとします。',
                  ),
                  
                  _buildSection(
                    '第12条（準拠法・管轄裁判所）',
                    '本規約の解釈にあたっては、日本法を準拠法とします。本アプリに関して紛争が生じた場合には、日本の裁判所を専属的合意管轄とします。',
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    'お問い合わせ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '本規約に関するお問い合わせは、以下のメールアドレスまでお願いいたします。',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'shuumyapp@gmail.com',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF009977),
                      fontWeight: FontWeight.w500,
                    ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}