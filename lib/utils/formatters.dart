String formatRupiah(int value) {
  if (value == 0) return 'Gratis';
  final str = value.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    final posFromEnd = str.length - i;
    buffer.write(str[i]);
    if (posFromEnd > 1 && posFromEnd % 3 == 1) {
      buffer.write('.');
    }
  }
  return 'Rp $buffer';
}

String formatTanggal(DateTime tanggal) {
  const namaBulan = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des'
  ];
  return '${tanggal.day} ${namaBulan[tanggal.month - 1]} ${tanggal.year}';
}

/// Format YYYY-MM-DD (dipakai untuk bertukar tanggal dengan backend).
String formatTanggalIso(DateTime tanggal) {
  final bulan = tanggal.month.toString().padLeft(2, '0');
  final hari = tanggal.day.toString().padLeft(2, '0');
  return '${tanggal.year}-$bulan-$hari';
}
