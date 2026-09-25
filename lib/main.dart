import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const TripinApp());
}

class TripinApp extends StatelessWidget {
  const TripinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TRIPIN',
      theme: buildAppTheme(),
      home: const LoginPage(),
    );
  }
}
