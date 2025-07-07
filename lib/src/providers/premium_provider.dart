import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/premium_service.dart';

/// プレミアム状態を管理するProvider
final premiumProvider = StateNotifierProvider<PremiumNotifier, bool>((ref) {
  return PremiumNotifier();
});

class PremiumNotifier extends StateNotifier<bool> {
  PremiumNotifier() : super(false) {
    _initialize();
  }

  /// プレミアムサービスを初期化
  Future<void> _initialize() async {
    await PremiumService.initialize();
    state = PremiumService.isPremium;
  }

  /// プレミアム機能を購入
  Future<bool> purchasePremium([PremiumPlan plan = PremiumPlan.lifetime]) async {
    final success = await PremiumService.purchasePremium(plan);
    if (success) {
      state = PremiumService.isPremium;
    }
    return success;
  }

  /// プレミアム状態を手動で更新（購入完了後など）
  void updatePremiumStatus() {
    state = PremiumService.isPremium;
  }

  /// デバッグ用：プレミアム状態を手動設定
  Future<void> debugSetPremiumStatus(bool isPremium, [PremiumPlan? plan]) async {
    await PremiumService.debugSetPremiumStatus(isPremium, plan);
    state = isPremium;
  }
  
  /// デバッグ用：サブスクリプションをシミュレート
  Future<void> debugSetSubscription(PremiumPlan plan, int daysFromNow) async {
    await PremiumService.debugSetSubscription(plan, daysFromNow);
    state = PremiumService.isPremium;
  }
  
  /// 現在のプランを取得
  PremiumPlan get currentPlan => PremiumService.currentPlan;
  
  /// サブスクリプション情報を取得
  Map<String, dynamic> get subscriptionInfo => PremiumService.getSubscriptionInfo();
  
  /// サブスクリプションがアクティブかチェック
  bool get isSubscriptionActive => PremiumService.isSubscriptionActive();
  
  /// サブスクリプションの残り日数
  int? get daysUntilExpiry => PremiumService.getDaysUntilExpiry();
  
  /// 次の更新日
  DateTime? get nextRenewalDate => PremiumService.getNextRenewalDate();
  
  /// 購入を復元
  Future<bool> restorePurchases() async {
    final success = await PremiumService.restorePurchases();
    if (success) {
      state = PremiumService.isPremium;
    }
    return success;
  }
}

/// プレミアム機能が利用可能かチェックするProvider
final canUsePremiumFeaturesProvider = Provider<bool>((ref) {
  return ref.watch(premiumProvider);
});

/// カテゴリー作成が可能かチェックするProvider
final canCreateCategoryProvider = Provider<bool>((ref) {
  final isPremium = ref.watch(premiumProvider);
  return PremiumService.canCreateCategory() || isPremium;
});

/// カテゴリー背景設定が可能かチェックするProvider
final canSetCategoryBackgroundProvider = Provider<bool>((ref) {
  final isPremium = ref.watch(premiumProvider);
  return PremiumService.canSetCategoryBackground() || isPremium;
});