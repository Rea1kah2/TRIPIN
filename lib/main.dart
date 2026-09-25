import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/destinasi_provider.dart';
import 'providers/rencana_provider.dart';
import 'screens/auth/login_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/destinasi_card.dart';

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
        home: Scaffold(
          backgroundColor: const Color(0xFFF7FAF8),
          body: SafeArea(
            child: Center(
              child: Consumer<DestinasiProvider>(
                builder: (context, provider, _) {
                  final contoh = provider.daftarDestinasi.first;
                  return DestinasiCard(
                    destinasi: contoh,
                    onTap: () {},
                    onFavoriteTap: () => provider.toggleFavorit(contoh.id),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
