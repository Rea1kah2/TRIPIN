
import 'package:flutter/material.dart';

import '../screens/destinasi/detail_destinasi_screen.dart';
import '../screens/rencana/detail_rencana_screen.dart';

// Import halaman baru
import '../screens/maps/maps_screen.dart';
import '../screens/review/review_screen.dart';
import '../screens/chatbot/chatbot_screen.dart';

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

  // Rute baru
  static const destinasiMaps = '/destinasi/maps';
  static const destinasiReview = '/destinasi/review';
  static const chatbot = '/chatbot';

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

    // Halaman peta destinasi
      case destinasiMaps:
        final id = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => MapsScreen(destinasiId: id),
        );

    // Halaman ulasan destinasi
      case destinasiReview:
        final id = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ReviewScreen(destinasiId: id),
        );

    // Halaman chatbot
      case chatbot:
        return MaterialPageRoute(
          builder: (_) => const ChatbotScreen(),
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