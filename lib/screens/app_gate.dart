import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/destinasi_provider.dart';
import '../providers/rencana_provider.dart';
import '../widgets/bottom_nav_shell.dart';
import 'auth/login_screen.dart';

class AppGate extends StatelessWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final destinasi = context.watch<DestinasiProvider>();
    final rencana = context.watch<RencanaProvider>();

    if (auth.isLoading || destinasi.isLoading || rencana.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return auth.isLoggedIn ? const BottomNavShell() : const LoginPage();
  }
}
