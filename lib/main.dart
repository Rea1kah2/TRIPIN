import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/destinasi_provider.dart';
import 'providers/rencana_provider.dart';
import 'screens/auth/login_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const TripinApp());
}

class TripinApp extends StatelessWidget {
  const TripinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => DestinasiProvider()),
          ChangeNotifierProvider(create: (_) => RencanaProvider()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'TRIPIN',
          theme: buildAppTheme(),
          home: const LoginPage(),
        ),
    );
  }
}
