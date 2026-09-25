import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/destinasi_provider.dart';
import 'providers/rencana_provider.dart';
import 'routes/app_routes.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/rencana/daftar_rencana_screen.dart';
import 'screens/rencana/tambah_rencana_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/bottom_nav_shell.dart';

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
        initialRoute: AppRoutes.login,
        routes: {
          AppRoutes.login: (_) => const LoginPage(),
          AppRoutes.register: (_) => const RegisterPage(),
          AppRoutes.home: (_) => const BottomNavShell(),
          AppRoutes.rencanaList: (_) => const DaftarRencanaScreen(),
          AppRoutes.rencanaTambah: (_) => const TambahRencanaScreen(),
        },
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
