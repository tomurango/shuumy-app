import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'about_screen.dart';
import 'privacy_policy_screen.dart';
import '../services/data_reset_service.dart';
import 'background_settings_screen.dart';
import 'category_management_screen.dart';
import 'premium_plan_selection_screen.dart';
import '../providers/premium_provider.dart';
import '../services/premium_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
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
                
                // カテゴリー管理
                _buildCategoryManagementItem(),
                
                _buildDivider(),
                
                // プレミアム機能案内
                _buildPremiumSection(),
                
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

  /// カテゴリー管理項目を構築
  Widget _buildCategoryManagementItem() {
    final isPremium = ref.watch(premiumProvider);
    
    return _buildSettingItem(
      icon: Icons.folder_outlined,
      title: 'カテゴリー管理',
      subtitle: isPremium ? 'カテゴリーの追加・編集・並び替え' : 'プレミアム機能',
      onTap: () {
        if (isPremium) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CategoryManagementScreen(),
            ),
          );
        } else {
          _showPremiumRequiredDialog();
        }
      },
      trailing: isPremium ? null : Icon(
        Icons.lock_outline,
        color: Colors.grey[500],
        size: 20,
      ),
    );
  }

  /// プレミアム機能が必要な場合のダイアログを表示
  void _showPremiumRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 400, 
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ヘッダー（統一）
              Container(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: Column(
                  children: [
                    Text(
                      'プレミアム機能',
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'カテゴリー管理をご利用いただけます',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              
              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // 機能一覧（統一）
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'プレミアム機能',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildFeatureItemForDialog('無制限のカテゴリー作成'),
                            _buildFeatureItemForDialog('カテゴリー別背景画像設定'),
                            _buildFeatureItemForDialog('カテゴリーの並び替え・管理'),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // ボタン（縦並び）
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showPremiumPurchaseScreen();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF009977),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text(
                                  'プレミアムを見る',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'キャンセル',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeatureItemForDialog(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFF009977),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            feature,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  /// プレミアム機能セクションを構築
  Widget _buildPremiumSection() {
    final isPremium = ref.watch(premiumProvider);
    
    if (isPremium) {
      final currentPlan = ref.read(premiumProvider.notifier).currentPlan;
      String planName = 'プレミアム';
      switch (currentPlan) {
        case PremiumPlan.monthly:
          planName = '月額プラン';
          break;
        case PremiumPlan.yearly:
          planName = '年額プラン';
          break;
        case PremiumPlan.lifetime:
          planName = '買い切りプラン';
          break;
        default:
          planName = 'プレミアム';
      }
      
      // プレミアム版の場合は「プレミアム版利用中」を表示
      return Column(
        children: [
          _buildSettingItem(
            icon: Icons.star,
            title: 'プレミアム版',
            subtitle: '${planName}でご利用中',
            onTap: () => _showSubscriptionDetails(),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber[600],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Premium',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // サブスクリプション情報表示
          if (currentPlan == PremiumPlan.monthly || currentPlan == PremiumPlan.yearly)
            _buildSubscriptionInfo(currentPlan),
        ],
      );
    } else {
      // 無料版の場合はプレミアム機能の案内（控えめに）
      return _buildSettingItem(
        icon: Icons.star_outline,
        title: 'プレミアム版',
        subtitle: 'カテゴリー管理などの追加機能',
        onTap: () => _showPremiumPurchaseScreen(),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber[300]!),
              ),
              child: Text(
                'Premium',
                style: TextStyle(
                  color: Colors.amber[700],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      );
    }
  }

  /// プレミアム購入画面を表示
  void _showPremiumPurchaseScreen() {
    showDialog(
      context: context,
      builder: (context) => const PremiumPlanSelectionScreen(),
    );
  }
  
  /// サブスクリプション詳細を表示
  void _showSubscriptionDetails() {
    final subscriptionInfo = ref.read(premiumProvider.notifier).subscriptionInfo;
    
    showDialog(
      context: context,
      builder: (context) => _SubscriptionDetailsDialog(subscriptionInfo: subscriptionInfo),
    );
  }
  
  /// サブスクリプション情報ウィジェットを構築
  Widget _buildSubscriptionInfo(PremiumPlan plan) {
    final notifier = ref.read(premiumProvider.notifier);
    final daysUntilExpiry = notifier.daysUntilExpiry;
    final nextRenewalDate = notifier.nextRenewalDate;
    
    String statusText = '';
    Color statusColor = Colors.green;
    
    if (plan == PremiumPlan.monthly || plan == PremiumPlan.yearly) {
      if (daysUntilExpiry != null) {
        if (daysUntilExpiry > 7) {
          statusText = '次回更新: ${_formatDate(nextRenewalDate!)}';
          statusColor = Colors.green;
        } else if (daysUntilExpiry > 0) {
          statusText = 'あと${daysUntilExpiry}日で期限切れ';
          statusColor = Colors.orange;
        } else {
          statusText = '期限切れ';
          statusColor = Colors.red;
        }
      }
    }
    
    if (statusText.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            color: statusColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (plan == PremiumPlan.monthly || plan == PremiumPlan.yearly)
            TextButton(
              onPressed: () => _showRestorePurchases(),
              child: Text(
                '復元',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  /// 日付をフォーマット
  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }
  
  /// 購入復元を実行
  void _showRestorePurchases() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      final success = await ref.read(premiumProvider.notifier).restorePurchases();
      
      if (mounted) {
        Navigator.pop(context); // ローディングを閉じる
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '購入を復元しました' : '復元できる購入がありませんでした'),
            backgroundColor: success ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? textColor,
    required VoidCallback onTap,
    Widget? trailing,
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
      trailing: trailing ?? Icon(
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

/// サブスクリプション詳細ダイアログ
class _SubscriptionDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> subscriptionInfo;

  const _SubscriptionDetailsDialog({required this.subscriptionInfo});

  @override
  Widget build(BuildContext context) {
    final isPremium = subscriptionInfo['isPremium'] as bool? ?? false;
    final currentPlan = subscriptionInfo['currentPlan'] as String? ?? 'free';
    final isActive = subscriptionInfo['isActive'] as bool? ?? false;
    final daysUntilExpiry = subscriptionInfo['daysUntilExpiry'] as int?;
    final purchaseDate = subscriptionInfo['purchaseDate'] as String?;
    final nextRenewalDate = subscriptionInfo['nextRenewalDate'] as String?;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // タイトル
            Row(
              children: [
                Icon(
                  Icons.star,
                  color: Colors.amber[600],
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'サブスクリプション情報',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // プラン情報
            _buildInfoItem('現在のプラン', _getPlanDisplayName(currentPlan)),
            
            if (isPremium) ...[
              _buildInfoItem('ステータス', isActive ? 'アクティブ' : '非アクティブ'),
              
              if (purchaseDate != null)
                _buildInfoItem('購入日', _formatDateString(purchaseDate)),
              
              if (daysUntilExpiry != null && (currentPlan == 'monthly' || currentPlan == 'yearly')) ...[
                if (daysUntilExpiry > 0)
                  _buildInfoItem('次回更新まで', '$daysUntilExpiry日')
                else
                  _buildInfoItem('ステータス', '期限切れ'),
                
                if (nextRenewalDate != null && daysUntilExpiry > 0)
                  _buildInfoItem('次回更新日', _formatDateString(nextRenewalDate)),
              ],
              
              if (currentPlan == 'lifetime')
                _buildInfoItem('有効期限', '無制限'),
            ],
            
            const SizedBox(height: 24),
            
            // ボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('閉じる'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _getPlanDisplayName(String planName) {
    switch (planName) {
      case 'monthly':
        return '月額プラン';
      case 'yearly':
        return '年額プラン';
      case 'lifetime':
        return '買い切りプラン';
      case 'free':
      default:
        return '無料プラン';
    }
  }
  
  String _formatDateString(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}/${date.month}/${date.day}';
    } catch (e) {
      return dateString;
    }
  }
}