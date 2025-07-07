import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/screens/home_screen.dart';
import 'src/services/data_migration_service.dart';
import 'src/services/premium_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // データ移行処理（既存データとの互換性確保）
  await DataMigrationService.migrateIfNeeded();
  
  // プレミアムサービス初期化
  await PremiumService.initialize();
  
  runApp(
    const ProviderScope(child: ShuumyApp()),
  );
}

class ShuumyApp extends StatelessWidget {
  const ShuumyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
