enum ChatRole { user, model }

/// Draf rencana yang diusulkan asisten. Baru disimpan setelah pengguna setuju.
class DraftRencana {
  final String judul;
  final DateTime? tanggalMulai;
  final int jumlahHari;
  final List<String> destinasiIds;
  final String catatan;

  /// Terisi setelah pengguna menekan "Simpan"; dipakai untuk tombol "Lihat".
  final String? rencanaId;

  const DraftRencana({
    required this.judul,
    this.tanggalMulai,
    required this.jumlahHari,
    required this.destinasiIds,
    this.catatan = '',
    this.rencanaId,
  });

  bool get tersimpan => rencanaId != null;

  DraftRencana copyWith({String? rencanaId}) => DraftRencana(
        judul: judul,
        tanggalMulai: tanggalMulai,
        jumlahHari: jumlahHari,
        destinasiIds: destinasiIds,
        catatan: catatan,
        rencanaId: rencanaId ?? this.rencanaId,
      );

  Map<String, dynamic> toJson() => {
        'judul': judul,
        'tanggalMulai': tanggalMulai?.toIso8601String(),
        'jumlahHari': jumlahHari,
        'destinasiIds': destinasiIds,
        'catatan': catatan,
        'rencanaId': rencanaId,
      };

  factory DraftRencana.fromJson(Map<String, dynamic> json) {
    final mulai = json['tanggalMulai'] as String?;
    return DraftRencana(
      judul: json['judul'] as String? ?? 'Rencana Perjalanan',
      tanggalMulai: mulai == null ? null : DateTime.tryParse(mulai),
      jumlahHari: (json['jumlahHari'] as num?)?.toInt() ?? 1,
      destinasiIds: List<String>.from(json['destinasiIds'] as List? ?? const []),
      catatan: json['catatan'] as String? ?? '',
      rencanaId: json['rencanaId'] as String?,
    );
  }
}

class ChatMessage {
  final String id;
  final ChatRole role;
  final String text;
  final List<String> destinasiIds;
  final DraftRencana? draft;

  /// Pesan error ramah bila balasan gagal; bila ada, UI menampilkan tombol ulangi.
  final String? error;

  /// Status langkah yang sedang dikerjakan Tripy. Hanya ada selama balasan diterima
  /// (tidak disimpan ke penyimpanan).
  final String? status;

  const ChatMessage({
    required this.id,
    required this.role,
    this.text = '',
    this.destinasiIds = const [],
    this.draft,
    this.error,
    this.status,
  });

  factory ChatMessage.user(String text) => ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        role: ChatRole.user,
        text: text,
      );

  factory ChatMessage.model({String? status}) => ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        role: ChatRole.model,
        status: status,
      );

  bool get kosong => text.isEmpty && destinasiIds.isEmpty && draft == null;

  ChatMessage copyWith({
    String? text,
    List<String>? destinasiIds,
    DraftRencana? draft,
    String? error,
    bool hapusError = false,
    String? status,
    bool hapusStatus = false,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      text: text ?? this.text,
      destinasiIds: destinasiIds ?? this.destinasiIds,
      draft: draft ?? this.draft,
      error: hapusError ? null : (error ?? this.error),
      status: hapusStatus ? null : (status ?? this.status),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'text': text,
        'destinasiIds': destinasiIds,
        'draft': draft?.toJson(),
        'error': error,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final draft = json['draft'];
    return ChatMessage(
      id: json['id'] as String,
      role: ChatRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => ChatRole.model,
      ),
      text: json['text'] as String? ?? '',
      destinasiIds: List<String>.from(json['destinasiIds'] as List? ?? const []),
      draft: draft is Map<String, dynamic> ? DraftRencana.fromJson(draft) : null,
      error: json['error'] as String?,
    );
  }
}
