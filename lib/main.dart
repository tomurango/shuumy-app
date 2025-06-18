import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/screens/home_screen.dart';

void main() {
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
