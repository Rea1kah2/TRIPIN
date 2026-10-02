import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/destinasi_provider.dart';
import 'providers/rencana_provider.dart';
import 'providers/theme_provider.dart';
import 'routes/app_routes.dart';
import 'screens/app_gate.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/rencana/daftar_rencana_screen.dart';
import 'screens/rencana/tambah_rencana_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/bottom_nav_shell.dart';
import 'screens/destinasi/daftar_destinasi_screen.dart';

void main() {
  runApp(const TripinApp());
}

class TripinApp extends StatelessWidget {
  const TripinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..muatData()),
        ChangeNotifierProvider(create: (_) => DestinasiProvider()..muatData()),
        ChangeNotifierProvider(create: (_) => RencanaProvider()..muatData()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..muatData()),
        ChangeNotifierProxyProvider<AuthProvider, ChatProvider>(
          create: (_) => ChatProvider(),
          update: (_, auth, chat) => chat!..gantiUser(auth.currentUser?.id),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'TRIPIN',
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: themeProvider.themeMode,
          home: const AppGate(),
          routes: {
            AppRoutes.login: (_) => const LoginPage(),
            AppRoutes.register: (_) => const RegisterPage(),
            AppRoutes.home: (_) => const BottomNavShell(),
            AppRoutes.rencanaList: (_) => const DaftarRencanaScreen(),
            AppRoutes.rencanaTambah: (_) => const TambahRencanaScreen(),
            AppRoutes.destinasiList: (_) => const DaftarDestinasiScreen(),
          },
          onGenerateRoute: AppRoutes.onGenerateRoute,
        ),
      ),
    );
  }
}
