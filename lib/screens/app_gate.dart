import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/destinasi_provider.dart';
import '../providers/rencana_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/bottom_nav_shell.dart';
import 'auth/login_screen.dart';
import '../widgets/glass_scaffold.dart';

class AppGate extends StatelessWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final destinasi = context.watch<DestinasiProvider>();
    final rencana = context.watch<RencanaProvider>();

    final theme = context.watch<ThemeProvider>();

    if (auth.isLoading ||
        destinasi.isLoading ||
        rencana.isLoading ||
        theme.isLoading) {
      return const GlassScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return auth.isLoggedIn ? const BottomNavShell() : const LoginPage();
  }
}
