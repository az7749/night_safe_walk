import 'package:flutter/material.dart';
import 'package:night_safe_walk/features/main/main_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '야간 안심 보행',
      theme: ThemeData(useMaterial3: true),
      home: const MainScreen(),
    );
  }
}
