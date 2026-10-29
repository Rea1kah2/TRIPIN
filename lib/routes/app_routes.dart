
import 'package:flutter/material.dart';

import '../screens/chat/chat_screen.dart';
import '../screens/checklist/checklist_screen.dart';
import '../screens/destinasi/detail_destinasi_screen.dart';
import '../screens/destinasi/pencarian_rekomendasi_screen.dart';
import '../screens/rencana/detail_rencana_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const destinasiList = '/destinasi';
  static const rencanaList = '/rencana';
  static const rencanaTambah = '/rencana/tambah';
  static const rencanaDetail = '/rencana/detail';
  static const destinasiDetail = '/destinasi/detail';
  static const chat = '/chat';
  static const pencarianRekomendasi = '/destinasi/rekomendasi';

  // Route baru untuk Checklist Perjalanan
  static const checklist = '/checklist';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case destinasiDetail:
        final id = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => DetailDestinasiScreen(destinasiId: id),
        );

      case rencanaDetail:
        final id = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => DetailRencanaScreen(rencanaId: id),
        );

      case pencarianRekomendasi:
        return MaterialPageRoute(
          builder: (_) => const PencarianRekomendasiScreen(),
        );

      case chat:
      // Arguments opsional: prompt awal untuk asisten.
        final prompt = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => ChatScreen(promptAwal: prompt),
        );

    // Route baru untuk membuka Checklist Perjalanan
      case checklist:
        return MaterialPageRoute(
          builder: (_) => const ChecklistScreen(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text(
                'Rute tidak ditemukan: ${settings.name}',
              ),
            ),
          ),
        );
    }
  }
}
