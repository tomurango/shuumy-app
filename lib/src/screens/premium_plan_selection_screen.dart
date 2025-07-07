import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../services/premium_service.dart';
import '../providers/premium_provider.dart';

class PremiumPlanSelectionScreen extends ConsumerStatefulWidget {
  const PremiumPlanSelectionScreen({super.key});

  @override
  ConsumerState<PremiumPlanSelectionScreen> createState() => _PremiumPlanSelectionScreenState();
}

class _PremiumPlanSelectionScreenState extends ConsumerState<PremiumPlanSelectionScreen> {
  List<ProductDetails> _products = [];
  bool _isLoading = true;
  PremiumPlan _selectedPlan = PremiumPlan.yearly; // デフォルトは年額プラン
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await PremiumService.getAllProductDetails();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('商品情報の読み込みエラー: $e');
    }
  }

  ProductDetails? _getProductForPlan(PremiumPlan plan) {
    final productId = _getProductIdForPlan(plan);
    final matchingProducts = _products.where((p) => p.id == productId).toList();
    return matchingProducts.isNotEmpty ? matchingProducts.first : null;
  }

  String _getProductIdForPlan(PremiumPlan plan) {
    switch (plan) {
      case PremiumPlan.monthly:
        return PremiumService.monthlyProductId;
      case PremiumPlan.yearly:
        return PremiumService.yearlyProductId;
      case PremiumPlan.lifetime:
        return PremiumService.lifetimeProductId;
      case PremiumPlan.free:
        return '';
    }
  }

  String _getPlanDisplayName(PremiumPlan plan) {
    switch (plan) {
      case PremiumPlan.monthly:
        return '月額プラン';
      case PremiumPlan.yearly:
        return '年額プラン';
      case PremiumPlan.lifetime:
        return '買い切りプラン';
      case PremiumPlan.free:
        return '無料プラン';
    }
  }

  String _getPlanDescription(PremiumPlan plan) {
    switch (plan) {
      case PremiumPlan.monthly:
        return '毎月自動更新';
      case PremiumPlan.yearly:
        return '毎年自動更新・月額より1,100円お得';
      case PremiumPlan.lifetime:
        return '一度の購入で永続利用';
      case PremiumPlan.free:
        return '';
    }
  }

  Color _getPlanColor(PremiumPlan plan) {
    switch (plan) {
      case PremiumPlan.monthly:
        return Colors.blue[600]!;
      case PremiumPlan.yearly:
        return Colors.green[600]!;
      case PremiumPlan.lifetime:
        return Colors.amber[600]!;
      case PremiumPlan.free:
        return Colors.grey[600]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
            // ヘッダー（シンプルに）
            Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Column(
                children: [
                  Text(
                    'プレミアム版',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '追加機能をご利用いただけます',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

            Flexible(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // 機能一覧（簡潔に）
                            _buildFeaturesListSimple(),
                            
                            const SizedBox(height: 24),
                            
                            // プラン選択
                            const Text(
                              'プランを選択',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // プランオプション
                            _buildPlanOptions(),
                            
                            const SizedBox(height: 24),
                            
                            // 購入ボタン
                            _buildPurchaseButton(),
                            
                            const SizedBox(height: 12),
                            
                            // キャンセルボタン
                            TextButton(
                              onPressed: _isPurchasing ? null : () => Navigator.pop(context),
                              child: const Text(
                                'キャンセル',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '✨ プレミアム機能',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildFeatureItem('無制限のカテゴリー作成'),
          _buildFeatureItem('カテゴリー別背景画像設定'),
          _buildFeatureItem('カテゴリーの並び替え・管理'),
          _buildFeatureItem('将来追加される新機能'),
        ],
      ),
    );
  }
  
  Widget _buildFeaturesListSimple() {
    return Column(
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
        _buildFeatureItemSimple('無制限のカテゴリー作成'),
        _buildFeatureItemSimple('カテゴリー別背景画像設定'),
        _buildFeatureItemSimple('カテゴリーの並び替え・管理'),
      ],
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green[500],
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            feature,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeatureItemSimple(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.amber[600],
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

  Widget _buildPlanOptions() {
    return Column(
      children: [
        _buildPlanOption(PremiumPlan.yearly, isRecommended: true),
        const SizedBox(height: 8),
        _buildPlanOption(PremiumPlan.monthly),
        const SizedBox(height: 8),
        _buildPlanOption(PremiumPlan.lifetime),
      ],
    );
  }

  Widget _buildPlanOption(PremiumPlan plan, {bool isRecommended = false}) {
    final product = _getProductForPlan(plan);
    final isSelected = _selectedPlan == plan;
    final planColor = _getPlanColor(plan);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlan = plan;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? planColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? planColor.withOpacity(0.05) : Colors.white,
        ),
        child: Column(
          children: [
            if (isRecommended)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[600],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'おすすめ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isSelected ? planColor : Colors.grey[400],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getPlanDisplayName(plan),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? planColor : Colors.black87,
                        ),
                      ),
                      Text(
                        _getPlanDescription(plan),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (product != null)
                  Text(
                    product.price,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? planColor : Colors.black87,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseButton() {
    final product = _getProductForPlan(_selectedPlan);
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_isPurchasing || product == null) ? null : _handlePurchase,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getPlanColor(_selectedPlan),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isPurchasing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                '${_getPlanDisplayName(_selectedPlan)}を購入',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _handlePurchase() async {
    setState(() {
      _isPurchasing = true;
    });

    try {
      final success = await ref.read(premiumProvider.notifier).purchasePremium(_selectedPlan);
      
      if (success) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_getPlanDisplayName(_selectedPlan)}の購入が完了しました！'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('購入に失敗しました。再度お試しください。'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
    } finally {
      if (mounted) {
        setState(() {
          _isPurchasing = false;
        });
      }
    }
  }
}