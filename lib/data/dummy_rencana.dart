import '../models/rencana_perjalanan.dart';

final List<RencanaPerjalanan> dummyRencanaList = [
  RencanaPerjalanan(
    id: 'r1',
    judul: 'Liburan Akhir Pekan ke Danau Toba',
    tanggalMulai: DateTime(2026, 10, 3),
    tanggalSelesai: DateTime(2026, 10, 5),
    daftarDestinasiId: ['d01', 'd08', 'd15'],
    catatan: 'Trip bareng 2 teman, fokus alam & budaya Batak.',
  ),
  RencanaPerjalanan(
    id: 'r2',
    judul: 'Eksplor Karo 3 Hari',
    tanggalMulai: DateTime(2026, 11, 20),
    tanggalSelesai: DateTime(2026, 11, 22),
    daftarDestinasiId: ['d03', 'd06', 'd11', 'd13'],
  ),
  RencanaPerjalanan(
    id: 'r3',
    judul: 'Wisata Kuliner & Sejarah Medan',
    tanggalMulai: DateTime(2026, 12, 1),
    tanggalSelesai: DateTime(2026, 12, 1),
    daftarDestinasiId: ['d05', 'd09', 'd19'],
    catatan: 'One-day trip keliling kota Medan.',
  ),
  RencanaPerjalanan(
    id: 'r4',
    judul: 'Petualangan Adventure Langkat',
    tanggalMulai: DateTime(2027, 1, 10),
    tanggalSelesai: DateTime(2027, 1, 12),
    daftarDestinasiId: ['d02', 'd07'],
    catatan: 'Ajak trekking + gajah di Tangkahan.',
  ),
];