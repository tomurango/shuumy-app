import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// プレミアムプランの種類
enum PremiumPlan {
  free,
  monthly,
  yearly,
  lifetime,
}

class PremiumService {
  // 商品ID定義
  static const String monthlyProductId = 'shuumy_premium_monthly';
  static const String yearlyProductId = 'shuumy_premium_yearly';
  static const String lifetimeProductId = 'shuumy_premium_lifetime';
  
  static const String _premiumStatusFile = 'premium_status.json';
  
  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  static bool _isPremium = false;
  static PremiumPlan _currentPlan = PremiumPlan.free;
  static DateTime? _subscriptionExpiry;
  static DateTime? _purchaseDate;
  static String? _originalTransactionId;
  
  static bool get isPremium => _isPremium;
  static PremiumPlan get currentPlan => _currentPlan;
  static DateTime? get subscriptionExpiry => _subscriptionExpiry;
  static DateTime? get purchaseDate => _purchaseDate;
  static String? get originalTransactionId => _originalTransactionId;
  
  /// プレミアム機能が利用可能かチェック
  static bool canUsePremiumFeatures() {
    // サブスクリプションの場合は有効期限をチェック
    if (_currentPlan == PremiumPlan.monthly || _currentPlan == PremiumPlan.yearly) {
      if (_subscriptionExpiry != null && DateTime.now().isAfter(_subscriptionExpiry!)) {
        return false;
      }
    }
    return _isPremium;
  }
  
  /// サブスクリプションが有効かチェック
  static bool isSubscriptionActive() {
    if (_currentPlan == PremiumPlan.lifetime) {
      return _isPremium;
    }
    if (_subscriptionExpiry == null) {
      return false;
    }
    return DateTime.now().isBefore(_subscriptionExpiry!);
  }
  
  /// サブスクリプションの残り日数を取得
  static int? getDaysUntilExpiry() {
    if (_subscriptionExpiry == null) return null;
    if (_currentPlan == PremiumPlan.lifetime) return null;
    
    final now = DateTime.now();
    if (now.isAfter(_subscriptionExpiry!)) return 0;
    
    return _subscriptionExpiry!.difference(now).inDays;
  }
  
  /// サブスクリプションの更新日を取得
  static DateTime? getNextRenewalDate() {
    if (_currentPlan == PremiumPlan.lifetime) return null;
    return _subscriptionExpiry;
  }
  
  /// プレミアムサービスを初期化
  static Future<void> initialize() async {
    // 保存されたプレミアム状態を読み込み
    await _loadPremiumStatus();
    
    // In-App Purchase の利用可能性をチェック
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      debugPrint('In-App Purchase is not available');
      return;
    }
    
    // 購入状態の監視を開始
    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) => debugPrint('Purchase stream error: $error'),
    );
    
    // 過去の購入を復元
    await _restorePurchases();
  }
  
  /// プレミアム機能を購入
  static Future<bool> purchasePremium(PremiumPlan plan) async {
    try {
      final productId = _getProductId(plan);
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails({productId});
      
      if (response.error != null) {
        debugPrint('Product query error: ${response.error}');
        return false;
      }
      
      if (response.productDetails.isEmpty) {
        debugPrint('No products found');
        return false;
      }
      
      final ProductDetails productDetails = response.productDetails.first;
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
      
      // サブスクリプションか買い切りかで分岐
      if (plan == PremiumPlan.lifetime) {
        return await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        // 月額・年額はサブスクリプション
        // 注意: 本来はApp Store Connectでサブスクリプション商品として設定する必要があります
        return await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      }
    } catch (e) {
      debugPrint('Purchase error: $e');
      return false;
    }
  }
  
  /// プランに対応する商品IDを取得
  static String _getProductId(PremiumPlan plan) {
    switch (plan) {
      case PremiumPlan.monthly:
        return monthlyProductId;
      case PremiumPlan.yearly:
        return yearlyProductId;
      case PremiumPlan.lifetime:
        return lifetimeProductId;
      case PremiumPlan.free:
        throw ArgumentError('Free plan has no product ID');
    }
  }
  
  /// 購入を復元
  static Future<void> _restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      debugPrint('Restore purchases error: $e');
    }
  }
  
  /// 手動で購入を復元
  static Future<bool> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
      
      // 復元後にサブスクリプション状態をチェック
      await _checkSubscriptionStatus();
      
      return true;
    } catch (e) {
      debugPrint('Manual restore purchases error: $e');
      return false;
    }
  }
  
  /// サブスクリプション状態をチェック
  static Future<void> _checkSubscriptionStatus() async {
    try {
      // アクティブなサブスクリプションをチェック
      if (_currentPlan == PremiumPlan.monthly || _currentPlan == PremiumPlan.yearly) {
        if (_subscriptionExpiry != null && DateTime.now().isAfter(_subscriptionExpiry!)) {
          // 期限切れの場合、ステータスを更新
          await _setPremiumStatus(false, PremiumPlan.free);
          debugPrint('サブスクリプションが期限切れです');
        }
      }
    } catch (e) {
      debugPrint('Check subscription status error: $e');
    }
  }
  
  /// サブスクリプション情報を取得
  static Map<String, dynamic> getSubscriptionInfo() {
    return {
      'isPremium': _isPremium,
      'currentPlan': _currentPlan.name,
      'subscriptionExpiry': _subscriptionExpiry?.toIso8601String(),
      'purchaseDate': _purchaseDate?.toIso8601String(),
      'originalTransactionId': _originalTransactionId,
      'isActive': isSubscriptionActive(),
      'daysUntilExpiry': getDaysUntilExpiry(),
      'nextRenewalDate': getNextRenewalDate()?.toIso8601String(),
    };
  }
  
  /// 購入状態の更新を処理
  static void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        
        // 購入された商品IDに応じてプランを設定
        PremiumPlan plan = PremiumPlan.free;
        DateTime? expiry;
        
        if (purchaseDetails.productID == monthlyProductId) {
          plan = PremiumPlan.monthly;
          // 月額は30日後に期限切れ
          expiry = DateTime.now().add(const Duration(days: 30));
        } else if (purchaseDetails.productID == yearlyProductId) {
          plan = PremiumPlan.yearly;
          // 年額は365日後に期限切れ
          expiry = DateTime.now().add(const Duration(days: 365));
        } else if (purchaseDetails.productID == lifetimeProductId) {
          plan = PremiumPlan.lifetime;
          // 買い切りは期限なし
          expiry = null;
        }
        
        if (plan != PremiumPlan.free) {
          _setPremiumStatusWithSubscription(
            true, 
            plan, 
            purchaseDetails.transactionDate,
            expiry,
            purchaseDetails.purchaseID,
          );
        }
        
        // 購入完了をマーク
        if (purchaseDetails.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(purchaseDetails);
        }
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        debugPrint('Purchase error: ${purchaseDetails.error}');
      }
    }
  }
  
  /// プレミアム状態を設定
  static Future<void> _setPremiumStatus(bool isPremium, [PremiumPlan? plan]) async {
    _isPremium = isPremium;
    if (plan != null) {
      _currentPlan = plan;
    } else if (!isPremium) {
      _currentPlan = PremiumPlan.free;
    }
    await _savePremiumStatus();
  }
  
  /// サブスクリプション情報と共にプレミアム状態を設定
  static Future<void> _setPremiumStatusWithSubscription(
    bool isPremium,
    PremiumPlan plan,
    String? purchaseDate,
    DateTime? expiry,
    String? transactionId,
  ) async {
    _isPremium = isPremium;
    _currentPlan = plan;
    _subscriptionExpiry = expiry;
    _originalTransactionId = transactionId;
    
    if (purchaseDate != null) {
      try {
        _purchaseDate = DateTime.parse(purchaseDate);
      } catch (e) {
        _purchaseDate = DateTime.now();
      }
    } else {
      _purchaseDate = DateTime.now();
    }
    
    await _savePremiumStatus();
  }
  
  /// プレミアム状態を保存
  static Future<void> _savePremiumStatus() async {
    try {
      final file = await _getPremiumStatusFile();
      final data = {
        'isPremium': _isPremium,
        'currentPlan': _currentPlan.name,
        'subscriptionExpiry': _subscriptionExpiry?.toIso8601String(),
        'purchaseDate': _purchaseDate?.toIso8601String(),
        'originalTransactionId': _originalTransactionId,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('Save premium status error: $e');
    }
  }
  
  /// プレミアム状態を読み込み
  static Future<void> _loadPremiumStatus() async {
    try {
      final file = await _getPremiumStatusFile();
      if (await file.exists()) {
        final contents = await file.readAsString();
        final data = jsonDecode(contents);
        _isPremium = data['isPremium'] ?? false;
        
        // プランを読み込み
        final planName = data['currentPlan'] as String?;
        if (planName != null) {
          _currentPlan = PremiumPlan.values.firstWhere(
            (plan) => plan.name == planName,
            orElse: () => PremiumPlan.free,
          );
        }
        
        // サブスクリプション情報を読み込み
        final expiryString = data['subscriptionExpiry'] as String?;
        if (expiryString != null) {
          try {
            _subscriptionExpiry = DateTime.parse(expiryString);
          } catch (e) {
            _subscriptionExpiry = null;
          }
        }
        
        final purchaseDateString = data['purchaseDate'] as String?;
        if (purchaseDateString != null) {
          try {
            _purchaseDate = DateTime.parse(purchaseDateString);
          } catch (e) {
            _purchaseDate = null;
          }
        }
        
        _originalTransactionId = data['originalTransactionId'] as String?;
        
        // サブスクリプションの有効期限をチェック
        if (_currentPlan == PremiumPlan.monthly || _currentPlan == PremiumPlan.yearly) {
          if (_subscriptionExpiry != null && DateTime.now().isAfter(_subscriptionExpiry!)) {
            // 期限切れの場合、無料プランに戻す
            _isPremium = false;
            _currentPlan = PremiumPlan.free;
            await _savePremiumStatus();
          }
        }
      }
    } catch (e) {
      debugPrint('Load premium status error: $e');
      _isPremium = false;
      _currentPlan = PremiumPlan.free;
      _subscriptionExpiry = null;
      _purchaseDate = null;
      _originalTransactionId = null;
    }
  }
  
  /// プレミアム状態ファイルを取得
  static Future<File> _getPremiumStatusFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(path.join(dir.path, _premiumStatusFile));
  }
  
  /// 商品情報を取得
  static Future<List<ProductDetails>> getAllProductDetails() async {
    try {
      final productIds = {monthlyProductId, yearlyProductId, lifetimeProductId};
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(productIds);
      
      if (response.error != null) {
        debugPrint('Product query error: ${response.error}');
        return [];
      }
      
      return response.productDetails;
    } catch (e) {
      debugPrint('Get product details error: $e');
      return [];
    }
  }
  
  /// 特定プランの商品情報を取得
  static Future<ProductDetails?> getProductDetails(PremiumPlan plan) async {
    try {
      final productId = _getProductId(plan);
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails({productId});
      
      if (response.error != null || response.productDetails.isEmpty) {
        return null;
      }
      
      return response.productDetails.first;
    } catch (e) {
      debugPrint('Get product details error: $e');
      return null;
    }
  }
  
  /// カテゴリー作成が可能かチェック
  static bool canCreateCategory() {
    return _isPremium;
  }
  
  /// カテゴリー背景設定が可能かチェック
  static bool canSetCategoryBackground() {
    return _isPremium;
  }
  
  /// プレミアム機能のエラーメッセージ
  static String getPremiumRequiredMessage() {
    return 'この機能を利用するにはプレミアム版が必要です。設定画面からアップグレードしてください。';
  }
  
  /// サービスを終了
  static void dispose() {
    _subscription?.cancel();
  }
  
  /// デバッグ用：プレミアム状態を手動設定（テスト用）
  static Future<void> debugSetPremiumStatus(bool isPremium, [PremiumPlan? plan]) async {
    await _setPremiumStatus(isPremium, plan);
  }
  
  /// デバッグ用：サブスクリプションをシミュレート（テスト用）
  static Future<void> debugSetSubscription(PremiumPlan plan, int daysFromNow) async {
    final expiry = plan == PremiumPlan.lifetime 
        ? null 
        : DateTime.now().add(Duration(days: daysFromNow));
    
    await _setPremiumStatusWithSubscription(
      true,
      plan,
      DateTime.now().toIso8601String(),
      expiry,
      'debug_transaction_${DateTime.now().millisecondsSinceEpoch}',
    );
  }
}