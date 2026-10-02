import 'package:flutter/material.dart';

/// Warna penanda peta per kategori (selaras palet mint; terang/gelap).
Color warnaKategori(String kategoriId, Brightness b) {
  final gelap = b == Brightness.dark;
  return switch (kategoriId) {
    'k1' => gelap ? const Color(0xFF7CCBB5) : const Color(0xFF2E7D6B), // Alam
    'k2' => gelap ? const Color(0xFF6CB8E8) : const Color(0xFF1E7FB8), // Pantai
    'k3' => gelap ? const Color(0xFFE0B35A) : const Color(0xFFA8731A), // Budaya
    'k4' => gelap ? const Color(0xFFF29B7A) : const Color(0xFFC4532D), // Kuliner
    'k5' => gelap ? const Color(0xFFB39DDB) : const Color(0xFF6A4BB0), // Adventure
    _ => gelap ? const Color(0xFF7CCBB5) : const Color(0xFF2E7D6B),
  };
}
