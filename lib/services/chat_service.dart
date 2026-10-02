import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/chat_message.dart';

sealed class ChatEvent {
  const ChatEvent();
}

class ChatDelta extends ChatEvent {
  final String text;
  const ChatDelta(this.text);
}

class ChatDestinasi extends ChatEvent {
  final List<String> ids;
  const ChatDestinasi(this.ids);
}

class ChatRencana extends ChatEvent {
  final DraftRencana draft;
  const ChatRencana(this.draft);
}

class ChatDone extends ChatEvent {
  const ChatDone();
}

class ChatError extends ChatEvent {
  final String message;
  const ChatError(this.message);
}

/// Kontrak ke backend; dipisah supaya provider bisa diuji dengan versi palsu.
abstract class ChatApi {
  Stream<ChatEvent> kirim({
    required List<ChatMessage> riwayat,
    required Map<String, dynamic> konteks,
  });
}

const pesanTidakTerhubung =
    'Tidak bisa terhubung ke asisten. Periksa koneksi internetmu lalu coba lagi.';

class ChatService implements ChatApi {
  final String? _baseUrl;
  final String? _appKey;
  final Duration timeoutSambung;
  final Duration timeoutDiam;

  /// [baseUrl]/[appKey] hanya perlu diisi di test; default dari [AppConfig].
  ChatService({
    String? baseUrl,
    String? appKey,
    this.timeoutSambung = const Duration(seconds: 30),
    this.timeoutDiam = const Duration(seconds: 60),
  })  : _baseUrl = baseUrl,
        _appKey = appKey;

  @override
  Stream<ChatEvent> kirim({
    required List<ChatMessage> riwayat,
    required Map<String, dynamic> konteks,
  }) async* {
    // Satu client per permintaan: membatalkan subscription menutup koneksi.
    final client = http.Client();
    try {
      final req = http.Request('POST', Uri.parse('${_baseUrl ?? AppConfig.apiBaseUrl}/api/chat'))
        ..headers['content-type'] = 'application/json'
        ..headers['accept'] = 'text/event-stream'
        ..body = jsonEncode({
          'pesan': [
            for (final m in riwayat)
              if (m.text.trim().isNotEmpty)
                {'role': m.role.name, 'text': m.text},
          ],
          'konteks': konteks,
        });
      final kunci = _appKey ?? AppConfig.appKey;
      if (kunci.isNotEmpty) req.headers['x-app-key'] = kunci;

      final res = await client.send(req).timeout(timeoutSambung);

      if (res.statusCode != 200) {
        final body = await res.stream.bytesToString();
        yield ChatError(pesanDariBodyError(res.statusCode, body));
        return;
      }

      final baris = res.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .timeout(timeoutDiam);

      await for (final line in baris) {
        final event = parseSseLine(line);
        if (event != null) yield event;
      }
    } on TimeoutException {
      yield const ChatError('Asisten terlalu lama merespons. Coba lagi ya.');
    } on http.ClientException catch (e) {
      debugPrint('ChatService: $e');
      yield const ChatError(pesanTidakTerhubung);
    } catch (e) {
      debugPrint('ChatService: $e');
      yield const ChatError(pesanTidakTerhubung);
    } finally {
      client.close();
    }
  }
}

/// Mengurai satu baris SSE (`data: {...}`). Komentar/ping dan baris kosong diabaikan.
@visibleForTesting
ChatEvent? parseSseLine(String line) {
  if (!line.startsWith('data:')) return null;
  final Object? json;
  try {
    json = jsonDecode(line.substring(5).trim());
  } catch (_) {
    return null;
  }
  if (json is! Map<String, dynamic>) return null;

  switch (json['type']) {
    case 'delta':
      final text = json['text'];
      return text is String && text.isNotEmpty ? ChatDelta(text) : null;
    case 'destinasi':
      final ids = json['ids'];
      return ids is List ? ChatDestinasi(ids.whereType<String>().toList()) : null;
    case 'rencana':
      final draft = json['draft'];
      return draft is Map<String, dynamic> ? ChatRencana(_parseDraft(draft)) : null;
    case 'done':
      return const ChatDone();
    case 'error':
      final msg = json['message'];
      return ChatError(msg is String && msg.isNotEmpty ? msg : 'Asisten sedang bermasalah.');
  }
  return null;
}

DraftRencana _parseDraft(Map<String, dynamic> d) {
  final mulai = d['tanggalMulai'];
  return DraftRencana(
    judul: (d['judul'] as String?)?.trim().isNotEmpty == true
        ? (d['judul'] as String).trim()
        : 'Rencana Perjalanan',
    tanggalMulai: mulai is String ? DateTime.tryParse(mulai) : null,
    jumlahHari: ((d['jumlahHari'] as num?)?.toInt() ?? 1).clamp(1, 14),
    destinasiIds: List<String>.from(d['destinasiIds'] as List? ?? const []),
    catatan: d['catatan'] as String? ?? '',
  );
}

@visibleForTesting
String pesanDariBodyError(int status, String body) {
  try {
    final json = jsonDecode(body);
    if (json is Map && json['error'] is String) return json['error'] as String;
  } catch (_) {}
  if (status == 429) return 'Terlalu banyak permintaan. Coba lagi sebentar ya.';
  if (status == 401) return 'Aplikasi tidak diizinkan mengakses asisten.';
  return 'Asisten sedang bermasalah (kode $status). Coba lagi nanti.';
}
