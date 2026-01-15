import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const IKOApp());
}

class IKOApp extends StatelessWidget {
  const IKOApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IKO Mobile Sales',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
