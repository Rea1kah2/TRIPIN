import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tugas_kelompok/models/chat_message.dart';
import 'package:tugas_kelompok/providers/chat_provider.dart';
import 'package:tugas_kelompok/providers/destinasi_provider.dart';
import 'package:tugas_kelompok/providers/rencana_provider.dart';
import 'package:tugas_kelompok/services/chat_service.dart';
import 'package:tugas_kelompok/utils/mini_markdown.dart';

/// API palsu: isi `events` diputar ulang setiap kirim(); `riwayatDikirim` merekam argumen.
class FakeChatApi implements ChatApi {
  List<ChatEvent> events;
  final riwayatDikirim = <List<ChatMessage>>[];
  final konteksDikirim = <Map<String, dynamic>>[];
  Completer<void>? tahan; // bila diisi, stream menunggu sebelum event pertama

  FakeChatApi([this.events = const []]);

  @override
  Stream<ChatEvent> kirim({
    required List<ChatMessage> riwayat,
    required Map<String, dynamic> konteks,
  }) async* {
    riwayatDikirim.add(List.of(riwayat));
    konteksDikirim.add(konteks);
    if (tahan != null) await tahan!.future;
    for (final e in events) {
      yield e;
    }
  }
}

Future<void> selesai() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('parseSseLine', () {
    test('mengurai semua jenis event', () {
      expect(parseSseLine('data: {"type":"delta","text":"Halo"}'), isA<ChatDelta>());
      expect((parseSseLine('data: {"type":"destinasi","ids":["d01","d02"]}') as ChatDestinasi).ids, ['d01', 'd02']);
      final r = parseSseLine(
              'data: {"type":"rencana","draft":{"judul":"Toba","tanggalMulai":"2026-10-10","jumlahHari":2,"destinasiIds":["d01"],"catatan":"c"}}')
          as ChatRencana;
      expect(r.draft.judul, 'Toba');
      expect(r.draft.tanggalMulai, DateTime(2026, 10, 10));
      expect(r.draft.jumlahHari, 2);
      expect(parseSseLine('data: {"type":"done"}'), isA<ChatDone>());
      expect((parseSseLine('data: {"type":"error","message":"sibuk"}') as ChatError).message, 'sibuk');
    });

    test('status: diurai dan dipangkas; status kosong diabaikan', () {
      expect((parseSseLine('data: {"type":"status","text":" Nyusun rencana… "}') as ChatStatus).text, 'Nyusun rencana…');
      expect(parseSseLine('data: {"type":"status","text":"  "}'), isNull);
      expect(parseSseLine('data: {"type":"status"}'), isNull);
    });

    test('mengabaikan ping, baris kosong, JSON rusak, dan tipe tak dikenal', () {
      expect(parseSseLine(': ping'), isNull);
      expect(parseSseLine(''), isNull);
      expect(parseSseLine('data: {rusak'), isNull);
      expect(parseSseLine('data: {"type":"aneh"}'), isNull);
      expect(parseSseLine('data: [1,2]'), isNull);
      expect(parseSseLine('data: {"type":"delta","text":""}'), isNull);
    });

    test('jumlahHari draf dibatasi 1..14 dan judul kosong diberi default', () {
      final r = parseSseLine('data: {"type":"rencana","draft":{"judul":"  ","jumlahHari":99,"destinasiIds":[]}}') as ChatRencana;
      expect(r.draft.jumlahHari, 14);
      expect(r.draft.judul, 'Rencana Perjalanan');
    });
  });

  group('pesanDariBodyError', () {
    test('memakai field error dari server, atau pesan default per status', () {
      expect(pesanDariBodyError(429, '{"error":"Terlalu banyak permintaan."}'), 'Terlalu banyak permintaan.');
      expect(pesanDariBodyError(429, 'bukan json'), contains('Terlalu banyak'));
      expect(pesanDariBodyError(401, ''), contains('tidak diizinkan'));
      expect(pesanDariBodyError(502, '<html>'), contains('502'));
    });
  });

  group('miniMarkdown', () {
    String teks(TextSpan s) => s.toPlainText();

    test('**tebal** menjadi span bold, tanda bintang hilang', () {
      final span = miniMarkdown('Coba **Danau Toba** ya', const TextStyle());
      expect(teks(span), 'Coba Danau Toba ya');
      final tebal = span.children!.whereType<TextSpan>().firstWhere((s) => s.text == 'Danau Toba');
      expect(tebal.style?.fontWeight, FontWeight.bold);
    });

    test('daftar "- " dan "* " menjadi bullet', () {
      expect(teks(miniMarkdown('- satu\n* dua', const TextStyle())), '•  satu\n•  dua');
    });

    test('** tanpa penutup tetap tampil apa adanya, bukan hilang', () {
      expect(teks(miniMarkdown('harga **murah', const TextStyle())), 'harga **murah');
    });
  });

  group('ChatProvider', () {
    late DestinasiProvider destinasi;
    late RencanaProvider rencana;

    setUp(() async {
      destinasi = DestinasiProvider();
      await destinasi.muatData();
      rencana = RencanaProvider();
      await rencana.muatData();
    });

    test('streaming: delta digabung, destinasi tanpa duplikat, draft terpasang', () async {
      final api = FakeChatApi([
        const ChatDelta('Coba '),
        const ChatDelta('Toba.'),
        const ChatDestinasi(['d01', 'd02']),
        const ChatDestinasi(['d02', 'd03']),
        ChatRencana(const DraftRencana(judul: 'Toba', jumlahHari: 2, destinasiIds: ['d01'])),
        const ChatDone(),
      ]);
      final chat = ChatProvider(api: api)..gantiUser('u1');
      await selesai();

      await chat.kirim('  rekomendasi?  ', konteks: bangunKonteks(destinasi, rencana));
      await selesai();

      expect(chat.isStreaming, isFalse);
      expect(chat.messages.map((m) => m.role), [ChatRole.user, ChatRole.model]);
      expect(chat.messages[0].text, 'rekomendasi?');
      final balasan = chat.messages[1];
      expect(balasan.text, 'Coba Toba.');
      expect(balasan.destinasiIds, ['d01', 'd02', 'd03']);
      expect(balasan.draft?.judul, 'Toba');
      expect(balasan.error, isNull);
    });

    test('status Tripy: awal lokal, diganti status backend, hilang saat teks mengalir dan saat selesai', () async {
      final api = FakeChatApi([
        const ChatStatus('Nyusun rencana…'),
        const ChatDelta('Ini rencananya.'),
        const ChatDone(),
      ]);
      final chat = ChatProvider(api: api)..gantiUser('u1');
      await selesai();

      final dilihat = <String?>[];
      chat.addListener(() {
        if (chat.messages.isNotEmpty && chat.messages.last.role == ChatRole.model) {
          dilihat.add(chat.messages.last.status);
        }
      });
      await chat.kirim('buatkan rencana', konteks: const {});
      await selesai();

      expect(dilihat.first, statusAwal);
      expect(dilihat, contains('Nyusun rencana…'));
      expect(dilihat.last, isNull);
      expect(chat.messages.last.status, isNull);
      expect(chat.messages.last.text, 'Ini rencananya.');
      // Status bersifat sementara: tidak ikut tersimpan.
      expect(chat.messages.last.toJson().containsKey('status'), isFalse);
    });

    test('konteks tidak memuat data pribadi dan berisi favorit + rencana', () async {
      destinasi.toggleFavorit('d05');
      final api = FakeChatApi([const ChatDone()]);
      final chat = ChatProvider(api: api)..gantiUser('u1');
      await selesai();
      await chat.kirim('hai', konteks: bangunKonteks(destinasi, rencana));
      await selesai();

      final k = api.konteksDikirim.single;
      expect(k['favoritIds'], ['d05']);
      expect((k['rencana'] as List).length, rencana.daftarRencana.length);
      expect(k['hariIni'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
      expect(k.keys.toSet(), {'hariIni', 'favoritIds', 'rencana'});
    });

    test('riwayat yang dikirim tidak menyertakan placeholder balasan', () async {
      final api = FakeChatApi([const ChatDelta('a'), const ChatDone()]);
      final chat = ChatProvider(api: api)..gantiUser('u1');
      await selesai();
      await chat.kirim('satu', konteks: const {});
      await selesai();
      await chat.kirim('dua', konteks: const {});
      await selesai();

      expect(api.riwayatDikirim[1].map((m) => m.text), ['satu', 'a', 'dua']);
    });

    test('error: pesan tersimpan di balasan, ulangi() mengirim ulang dan sukses', () async {
      final api = FakeChatApi([const ChatError('Asisten sedang sibuk')]);
      final chat = ChatProvider(api: api)..gantiUser('u1');
      await selesai();
      await chat.kirim('halo', konteks: const {});
      await selesai();

      expect(chat.isStreaming, isFalse);
      expect(chat.messages.last.error, 'Asisten sedang sibuk');

      api.events = [const ChatDelta('Berhasil'), const ChatDone()];
      chat.ulangi(konteks: const {});
      await selesai();

      expect(chat.messages, hasLength(2)); // tidak menggandakan balasan
      expect(chat.messages.last.text, 'Berhasil');
      expect(chat.messages.last.error, isNull);
      expect(api.riwayatDikirim.last.map((m) => m.text), ['halo']);
    });

    test('stream berakhir tanpa event done dan tanpa isi -> error "terputus"', () async {
      final chat = ChatProvider(api: FakeChatApi([]))..gantiUser('u1');
      await selesai();
      await chat.kirim('halo', konteks: const {});
      await selesai();
      expect(chat.isStreaming, isFalse);
      expect(chat.messages.last.error, contains('terputus'));
    });

    test('tidak bisa mengirim saat masih streaming, dan kirim kosong diabaikan', () async {
      final api = FakeChatApi([const ChatDelta('x'), const ChatDone()])..tahan = Completer<void>();
      final chat = ChatProvider(api: api)..gantiUser('u1');
      await selesai();

      await chat.kirim('pertama', konteks: const {});
      await chat.kirim('kedua', konteks: const {});
      await chat.kirim('   ', konteks: const {});
      expect(chat.messages.where((m) => m.role == ChatRole.user), hasLength(1));
      expect(chat.isStreaming, isTrue);

      api.tahan!.complete();
      await selesai();
      expect(chat.isStreaming, isFalse);
    });

    test('batal(): berhenti, placeholder kosong dibuang, pesan user tetap', () async {
      final api = FakeChatApi([const ChatDelta('x')])..tahan = Completer<void>();
      final chat = ChatProvider(api: api)..gantiUser('u1');
      await selesai();
      await chat.kirim('halo', konteks: const {});
      chat.batal();

      expect(chat.isStreaming, isFalse);
      expect(chat.messages.map((m) => m.role), [ChatRole.user]);

      api.tahan!.complete(); // event telat setelah batal tidak boleh masuk
      await selesai();
      expect(chat.messages, hasLength(1));
    });

    test('riwayat tersimpan per user dan dimuat ulang; pindah user memisahkan', () async {
      final api = FakeChatApi([const ChatDelta('jawaban'), const ChatDone()]);
      final a = ChatProvider(api: api)..gantiUser('u1');
      await selesai();
      await a.kirim('pertanyaan u1', konteks: const {});
      await selesai();

      final b = ChatProvider(api: api)..gantiUser('u1'); // "restart app"
      await selesai();
      expect(b.messages.map((m) => m.text), ['pertanyaan u1', 'jawaban']);

      b.gantiUser('u2');
      await selesai();
      expect(b.messages, isEmpty);

      b.gantiUser(null); // logout
      await selesai();
      expect(b.messages, isEmpty);

      b.gantiUser('u1');
      await selesai();
      expect(b.messages, hasLength(2));
    });

    test('hapusRiwayat mengosongkan dan menyimpan', () async {
      final api = FakeChatApi([const ChatDelta('x'), const ChatDone()]);
      final chat = ChatProvider(api: api)..gantiUser('u1');
      await selesai();
      await chat.kirim('halo', konteks: const {});
      await selesai();
      chat.hapusRiwayat();
      await selesai();

      final baru = ChatProvider(api: api)..gantiUser('u1');
      await selesai();
      expect(baru.messages, isEmpty);
    });

    test('simpanDraft membuat rencana sungguhan sekali saja', () async {
      final api = FakeChatApi([
        ChatRencana(const DraftRencana(
          judul: 'Toba 2 Hari',
          jumlahHari: 2,
          destinasiIds: ['d01', 'd08', 'tidak-ada'],
          catatan: 'Berangkat pagi',
        )),
        const ChatDone(),
      ]);
      final chat = ChatProvider(api: api)..gantiUser('u1');
      await selesai();
      await chat.kirim('buatkan rencana', konteks: const {});
      await selesai();

      final sebelum = rencana.daftarRencana.length;
      final id = chat.messages.last.id;
      final baru = chat.simpanDraft(id, rencana: rencana, destinasi: destinasi)!;

      expect(rencana.daftarRencana.length, sebelum + 1);
      expect(baru.judul, 'Toba 2 Hari');
      expect(baru.daftarDestinasiId, ['d01', 'd08']); // id tak dikenal disaring
      expect(baru.tanggalSelesai.difference(baru.tanggalMulai).inDays, 1);
      expect(baru.tanggalMulai.isAfter(DateTime.now()), isTrue); // default: besok
      expect(chat.messages.last.draft!.rencanaId, baru.id);

      // Menekan dua kali tidak menggandakan.
      expect(chat.simpanDraft(id, rencana: rencana, destinasi: destinasi), isNull);
      expect(rencana.daftarRencana.length, sebelum + 1);
    });
  });
}
