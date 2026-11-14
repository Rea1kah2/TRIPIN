/// Item perlengkapan perjalanan pada layar Checklist.
class ChecklistItem {
  final String id;
  final String nama;
  final bool selesai;

  const ChecklistItem({
    required this.id,
    required this.nama,
    this.selesai = false,
  });

  ChecklistItem copyWith({
    String? id,
    String? nama,
    bool? selesai,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      selesai: selesai ?? this.selesai,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'selesai': selesai,
      };

  static ChecklistItem? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final nama = raw['nama'];
    final selesai = raw['selesai'];
    if (id is! String || nama is! String) return null;
    return ChecklistItem(
      id: id,
      nama: nama,
      selesai: selesai is bool ? selesai : false,
    );
  }

  /// Daftar perlengkapan awal saat pengguna membuka checklist untuk pertama kali.
  static List<ChecklistItem> bawaanAwal() => const [
        ChecklistItem(id: 'c1', nama: 'Pakaian ganti & jaket tipis'),
        ChecklistItem(id: 'c2', nama: 'Kartu identitas (KTP) & tiket'),
        ChecklistItem(id: 'c3', nama: 'Obat-obatan pribadi'),
        ChecklistItem(id: 'c4', nama: 'Pengisi daya & powerbank'),
        ChecklistItem(id: 'c5', nama: 'Uang tunai secukupnya'),
      ];
}
