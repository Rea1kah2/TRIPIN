import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/glass_card.dart';

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
      home: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://images.unsplash.com/photo-1604999333679-b86d54738315?auto=format&fit=crop&w=700&q=80',
              fit: BoxFit.cover,
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: GlassCard(
                  child: const Text(
                    'TRIPIN',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
