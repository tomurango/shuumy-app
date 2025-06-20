import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'about_screen.dart';
import 'privacy_policy_screen.dart';
import '../services/data_reset_service.dart';
import 'background_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
    });
  }

  Future<void> _sendEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'shuumyapp@gmail.com',
      queryParameters: {
        'subject': 'シューマイアプリについて',
        'body': 'アプリバージョン: $_version\n\n',
      },
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('メールアプリを開けませんでした'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _launchAppStore() async {
    // 実際のApp Store URLに変更してください
    const url = 'https://apps.apple.com/app/id1234567890';
    final Uri uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _showResetConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('データを初期化'),
        content: const Text(
          'すべての趣味とメモが削除されます。\nこの操作は取り消せません。\n\n本当に実行しますか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DataResetService.resetAllData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('データを初期化しました'),
              backgroundColor: Colors.green,
            ),
          );
          // ホーム画面に戻る
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('エラーが発生しました: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

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
          '設定',
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
            child: ListView(
              children: [
                // 背景画像
                _buildSettingItem(
                  icon: Icons.wallpaper,
                  title: '背景画像',
                  subtitle: 'ホーム画面の背景を変更',
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BackgroundSettingsScreen(),
                      ),
                    );
                    
                    // 背景が変更された場合は、設定画面の結果として通知
                    if (result == true && mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                ),
                
                _buildDivider(),
                
                // アプリについて
                _buildSettingItem(
                  icon: Icons.info_outline,
                  title: 'アプリについて',
                  subtitle: 'バージョン $_version',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AboutScreen(),
                      ),
                    );
                  },
                ),
                
                _buildDivider(),
                
                // プライバシーポリシー
                _buildSettingItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'プライバシーポリシー',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyScreen(),
                      ),
                    );
                  },
                ),
                
                _buildDivider(),
                
                // お問い合わせ
                _buildSettingItem(
                  icon: Icons.email_outlined,
                  title: 'お問い合わせ',
                  subtitle: 'ご質問・ご要望はこちら',
                  onTap: _sendEmail,
                ),
                
                _buildDivider(),
                
                // レビューを書く
                _buildSettingItem(
                  icon: Icons.star_outline,
                  title: 'レビューを書く',
                  subtitle: 'App Storeでレビューする',
                  onTap: _launchAppStore,
                ),
                
                const SizedBox(height: 30),
                
                // 危険な操作
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Text(
                    '危険な操作',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // データを初期化
                _buildSettingItem(
                  icon: Icons.delete_forever_outlined,
                  title: 'データを初期化',
                  subtitle: 'すべてのデータを削除',
                  textColor: Colors.red,
                  onTap: _showResetConfirmation,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: textColor ?? Colors.black,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor ?? Colors.black,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            )
          : null,
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 56),
      color: Colors.grey[200],
    );
  }
}