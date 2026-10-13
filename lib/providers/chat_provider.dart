import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/rencana_perjalanan.dart';
import '../services/chat_service.dart';
import '../services/local_storage_service.dart';
import '../utils/formatters.dart';
import 'destinasi_provider.dart';
import 'rencana_provider.dart';
import '../services/location_service.dart';

const _maksRiwayatTersimpan = 50;

/// Status yang tampil sejak pesan dikirim, sebelum backend mengirim status pertama.
const statusAwal = 'Tripy lagi mikir…';

/// Konteks ringan untuk personalisasi. Sengaja TIDAK memuat nama/email user.
Map<String, dynamic> bangunKonteks(
  DestinasiProvider destinasi,
  RencanaProvider rencana, {
  Posisi? posisi,
}) {
  return {
    'hariIni': formatTanggalIso(DateTime.now()),
    // Posisi kasar (dibulatkan 2 desimal, sekitar 1 km) dan hanya bila lokasi diizinkan.
    if (posisi != null) 'posisi': {'lat': _bulat2(posisi.lat), 'lng': _bulat2(posisi.lng)},
    'favoritIds': destinasi.daftarFavorit.map((d) => d.id).toList(),
    'rencana': [
      for (final r in rencana.daftarRencana.take(10))
        {
          'judul': r.judul,
          'tanggalMulai': formatTanggalIso(r.tanggalMulai),
          'tanggalSelesai': formatTanggalIso(r.tanggalSelesai),
          'destinasiIds': r.daftarDestinasiId,
        },
    ],
  };
}

double _bulat2(double v) => (v * 100).round() / 100;

class ChatProvider extends ChangeNotifier {
  final ChatApi _api;
  final LocalStorageService _storage;

  List<ChatMessage> _messages = [];
  String? _userId;
  StreamSubscription<ChatEvent>? _sub;
  bool isStreaming = false;
  int _generasi = 0; // membuang hasil async milik sesi/user yang sudah berganti
  bool _disposed = false;

  ChatProvider({ChatApi? api, LocalStorageService? storage})
      : _api = api ?? ChatService(),
        _storage = storage ?? LocalStorageService();

  List<ChatMessage> get messages => List.unmodifiable(_messages);

  /// Dipanggil saat user login/logout. Riwayat dipisah per user.
  void gantiUser(String? userId) {
    if (userId == _userId) return;
    _userId = userId;
    _sub?.cancel();
    _sub = null;
    isStreaming = false;
    _messages = [];
    final generasi = ++_generasi;

    // Jangan notify sinkron: metode ini dipanggil dari fase build (ProxyProvider).
    Future<void>(() async {
      final dimuat = userId == null ? <ChatMessage>[] : await _storage.muatChat(userId);
      if (_disposed || generasi != _generasi) return;
      _messages = dimuat;
      notifyListeners();
    });
  }

  Future<void> kirim(String teks, {required Map<String, dynamic> konteks}) async {
    final t = teks.trim();
    if (t.isEmpty || isStreaming) return;
    _messages = [..._messages, ChatMessage.user(t), ChatMessage.model(status: statusAwal)];
    isStreaming = true;
    notifyListeners();
    _mulaiStream(konteks);
  }

  /// Mengulang balasan terakhir yang gagal.
  void ulangi({required Map<String, dynamic> konteks}) {
    if (isStreaming || _messages.isEmpty) return;
    final terakhir = _messages.last;
    if (terakhir.role != ChatRole.model || terakhir.error == null) return;
    _messages = [
      ..._messages.sublist(0, _messages.length - 1),
      ChatMessage.model(status: statusAwal),
    ];
    isStreaming = true;
    notifyListeners();
    _mulaiStream(konteks);
  }

  void batal() {
    if (!isStreaming) return;
    _sub?.cancel();
    _sub = null;
    isStreaming = false;
    // Buang placeholder kosong; balasan parsial tetap disimpan.
    if (_messages.isNotEmpty && _messages.last.kosong) {
      _messages = _messages.sublist(0, _messages.length - 1);
    } else {
      _ubahTerakhir((m) => m.copyWith(hapusStatus: true));
    }
    notifyListeners();
    _simpan();
  }

  void hapusRiwayat() {
    _sub?.cancel();
    _sub = null;
    isStreaming = false;
    _messages = [];
    notifyListeners();
    _simpan();
  }

  /// Menyimpan draf asisten sebagai rencana sungguhan (setelah user menekan tombol).
  RencanaPerjalanan? simpanDraft(
    String messageId, {
    required RencanaProvider rencana,
    required DestinasiProvider destinasi,
  }) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return null;
    final draft = _messages[index].draft;
    if (draft == null || draft.tersimpan) return null;

    final ids = draft.destinasiIds.where((id) => destinasi.getById(id) != null).toList();
    if (ids.isEmpty) return null;

    final sekarang = DateTime.now();
    final mulai = draft.tanggalMulai ??
        DateTime(sekarang.year, sekarang.month, sekarang.day).add(const Duration(days: 1));
    final baru = RencanaPerjalanan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      judul: draft.judul.length < 3 ? 'Rencana Perjalanan' : draft.judul,
      tanggalMulai: mulai,
      tanggalSelesai: mulai.add(Duration(days: draft.jumlahHari - 1)),
      daftarDestinasiId: ids,
      catatan: draft.catatan,
    );
    rencana.tambahRencana(baru);

    _messages = [
      for (final m in _messages)
        m.id == messageId ? m.copyWith(draft: draft.copyWith(rencanaId: baru.id)) : m,
    ];
    notifyListeners();
    _simpan();
    return baru;
  }

  void _mulaiStream(Map<String, dynamic> konteks) {
    final riwayat = _messages.sublist(0, _messages.length - 1);
    final generasi = _generasi;

    void saring(void Function() aksi) {
      if (_disposed || generasi != _generasi) return;
      aksi();
    }

    _sub = _api.kirim(riwayat: riwayat, konteks: konteks).listen(
          (e) => saring(() => _terapkan(e)),
          onError: (Object _) => saring(() => _terapkan(const ChatError(pesanTidakTerhubung))),
          onDone: () => saring(() {
            if (isStreaming) _selesai(); // stream ditutup tanpa event done
          }),
        );
  }

  void _ubahTerakhir(ChatMessage Function(ChatMessage) ubah) {
    if (_messages.isEmpty) return;
    _messages = [..._messages.sublist(0, _messages.length - 1), ubah(_messages.last)];
  }

  void _terapkan(ChatEvent e) {
    switch (e) {
      case ChatStatus(:final text):
        _ubahTerakhir((m) => m.copyWith(status: text));
      case ChatDelta(:final text):
        _ubahTerakhir((m) => m.copyWith(text: m.text + text, hapusStatus: true));
      case ChatDestinasi(:final ids):
        _ubahTerakhir((m) => m.copyWith(
              destinasiIds: [
                ...m.destinasiIds,
                ...ids.where((id) => !m.destinasiIds.contains(id)),
              ],
            ));
      case ChatRencana(:final draft):
        _ubahTerakhir((m) => m.copyWith(draft: draft));
      case ChatDone():
        _selesai();
        return;
      case ChatError(:final message):
        _ubahTerakhir((m) => m.copyWith(error: message, hapusStatus: true));
        isStreaming = false;
        _sub?.cancel();
        _sub = null;
        _simpan();
    }
    notifyListeners();
  }

  void _selesai() {
    if (_messages.isNotEmpty && _messages.last.kosong && _messages.last.error == null) {
      _ubahTerakhir((m) => m.copyWith(error: 'Koneksi terputus sebelum balasan selesai.'));
    }
    _ubahTerakhir((m) => m.copyWith(hapusStatus: true));
    isStreaming = false;
    _sub?.cancel();
    _sub = null;
    notifyListeners();
    _simpan();
  }

  void _simpan() {
    final userId = _userId;
    if (userId == null) return;
    final tersimpan = _messages.length > _maksRiwayatTersimpan
        ? _messages.sublist(_messages.length - _maksRiwayatTersimpan)
        : _messages;
    _storage.simpanChat(userId, tersimpan);
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    super.dispose();
  }
}
