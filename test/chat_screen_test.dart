import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tugas_kelompok/models/chat_message.dart';
import 'package:tugas_kelompok/providers/chat_provider.dart';
import 'package:tugas_kelompok/providers/destinasi_provider.dart';
import 'package:tugas_kelompok/providers/lokasi_provider.dart';
import 'package:tugas_kelompok/providers/rencana_provider.dart';
import 'package:tugas_kelompok/routes/app_routes.dart';
import 'package:tugas_kelompok/screens/chat/chat_screen.dart';
import 'package:tugas_kelompok/services/chat_service.dart';
import 'package:tugas_kelompok/theme/app_theme.dart';
import 'package:tugas_kelompok/widgets/chat/assistant_status.dart';

class FakeApi implements ChatApi {
  List<ChatEvent> events;
  int panggilan = 0;

  /// Bila diisi, stream menahan diri setelah event terakhir sampai diselesaikan.
  final Completer<void>? tahan;
  FakeApi(this.events, {this.tahan});

  @override
  Stream<ChatEvent> kirim({required List<ChatMessage> riwayat, required Map<String, dynamic> konteks}) async* {
    panggilan++;
    for (final e in events) {
      yield e;
    }
    if (tahan != null) await tahan!.future;
  }
}

/// Pengganti pumpAndSettle: placeholder gambar jaringan (spinner) tidak pernah "settle" di tes.
Future<void> tunggu(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

Future<ChatProvider> pasang(WidgetTester tester, FakeApi api, {bool gelap = false, String? prompt}) async {
  SharedPreferences.setMockInitialValues({});
  final destinasi = DestinasiProvider();
  await destinasi.muatData();
  final rencana = RencanaProvider();
  await rencana.muatData();
  final chat = ChatProvider(api: api)..gantiUser('u1');
  await tester.pump(const Duration(milliseconds: 50));

  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: destinasi),
      ChangeNotifierProvider.value(value: rencana),
      ChangeNotifierProvider.value(value: chat),
      ChangeNotifierProvider(create: (_) => LokasiProvider()),
    ],
    child: MaterialApp(
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: gelap ? ThemeMode.dark : ThemeMode.light,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      home: ChatScreen(promptAwal: prompt),
    ),
  ));
  await tester.pump();
  return chat;
}

void main() {
  testWidgets('indikator Tripy: status backend tampil saat belum ada teks', (tester) async {
    final tahan = Completer<void>();
    final api = FakeApi([const ChatStatus('Nyusun rencana…')], tahan: tahan);
    await pasang(tester, api, prompt: 'halo');
    await tunggu(tester);

    expect(find.text('Nyusun rencana…'), findsOneWidget);
    expect(find.text('Menulis…'), findsNothing);
    tahan.complete();
    await tunggu(tester);
  });

  testWidgets('indikator Tripy: "Menulis…" muncul saat teks mengalir dan hilang saat selesai', (tester) async {
    final tahan = Completer<void>();
    final api = FakeApi([const ChatDelta('Hai, ini jawabannya')], tahan: tahan);
    await pasang(tester, api, prompt: 'halo');
    await tunggu(tester);

    expect(find.textContaining('Hai, ini jawabannya'), findsOneWidget);
    expect(find.text('Menulis…'), findsOneWidget);

    tahan.complete();
    await tunggu(tester);
    expect(find.text('Menulis…'), findsNothing);
    expect(find.textContaining('Hai, ini jawabannya'), findsOneWidget);
  });

  testWidgets('indikator Tripy: Reduce Motion tanpa gerak, tetapi titik tetap berkedip (opacity)', (tester) async {
    final tahan = Completer<void>();
    final api = FakeApi([const ChatStatus('Nyari tempat…')], tahan: tahan);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pasang(tester, api, prompt: 'halo');
    await tunggu(tester);
    expect(find.text('Nyari tempat…'), findsOneWidget);

    List<double> opacity() => tester
        .widgetList<Opacity>(find.descendant(of: find.byType(AssistantStatus), matching: find.byType(Opacity)))
        .map((o) => o.opacity)
        .toList();

    final awal = opacity();
    await tester.pump(const Duration(milliseconds: 350));
    expect(opacity(), isNot(awal), reason: 'titik harus tetap berubah supaya pengguna tahu Tripy bekerja');

    // Tidak ada gerak naik-turun: semua titik berada pada offset vertikal 0.
    final geser = tester
        .widgetList<Transform>(find.descendant(of: find.byType(AssistantStatus), matching: find.byType(Transform)))
        .where((t) => t.transform.getTranslation().y != 0);
    expect(geser, isEmpty);

    tahan.complete();
    await tunggu(tester);
  });

  testWidgets('indikator Tripy: gerak normal menggeser titik naik-turun', (tester) async {
    final tahan = Completer<void>();
    final api = FakeApi([const ChatStatus('Nyari tempat…')], tahan: tahan);
    await pasang(tester, api, prompt: 'halo');
    await tunggu(tester);

    var adaGeser = false;
    for (var i = 0; i < 12 && !adaGeser; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      adaGeser = tester
          .widgetList<Transform>(find.descendant(of: find.byType(AssistantStatus), matching: find.byType(Transform)))
          .any((t) => t.transform.getTranslation().y != 0);
    }
    expect(adaGeser, isTrue);

    tahan.complete();
    await tunggu(tester);
  });

  testWidgets('layar kosong menampilkan sapaan dan saran; mengetuk saran mengirim pesan', (tester) async {
    final api = FakeApi([const ChatDelta('Ini jawabannya.'), const ChatDone()]);
    await pasang(tester, api);

    expect(find.text('Halo, aku Tripy 👋 Mau healing ke mana nih?'), findsOneWidget);
    await tester.tap(find.text('Wisata gratis apa saja?'));
    await tunggu(tester);

    expect(api.panggilan, 1);
    expect(find.text('Wisata gratis apa saja?'), findsOneWidget); // gelembung user
    expect(find.text('Ini jawabannya.'), findsOneWidget);
    expect(find.text('Halo, aku Tripy 👋 Mau healing ke mana nih?'), findsNothing);
  });

  testWidgets('mengetik lalu menekan Kirim; tombol Kirim nonaktif saat input kosong', (tester) async {
    final api = FakeApi([const ChatDelta('ok'), const ChatDone()]);
    await pasang(tester, api);

    IconButton tombol() => tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.arrow_upward_rounded));
    expect(tombol().onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'halo asisten');
    await tester.pump();
    expect(tombol().onPressed, isNotNull);

    await tester.tap(find.byTooltip('Kirim'));
    await tunggu(tester);
    expect(api.panggilan, 1);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
  });

  testWidgets('kartu destinasi nyata dan draf rencana muncul; Simpan membuat rencana', (tester) async {
    final api = FakeApi([
      const ChatDelta('Coba ini:'),
      const ChatDestinasi(['d03', 'd13']),
      ChatRencana(const DraftRencana(judul: 'Karo 2 Hari', jumlahHari: 2, destinasiIds: ['d03', 'd13'])),
      const ChatDone(),
    ]);
    await pasang(tester, api, prompt: 'rencana Karo');
    await tunggu(tester);

    expect(find.text('Berastagi'), findsWidgets); // kartu destinasi + daftar di draf
    expect(find.text('Karo 2 Hari'), findsOneWidget);

    final context = tester.element(find.byType(ChatScreen));
    final sebelum = context.read<RencanaProvider>().daftarRencana.length;

    await tester.ensureVisible(find.text('Simpan sebagai rencana'));
    await tester.tap(find.text('Simpan sebagai rencana'));
    await tunggu(tester);

    expect(context.read<RencanaProvider>().daftarRencana.length, sebelum + 1);
    expect(find.text('Tersimpan · Lihat rencana'), findsOneWidget);
    expect(find.text('Simpan sebagai rencana'), findsNothing);
  });

  testWidgets('error menampilkan pesan ramah dan tombol Ulangi yang berfungsi', (tester) async {
    final api = FakeApi([const ChatError('Asisten sedang sibuk')]);
    await pasang(tester, api, prompt: 'halo');
    await tunggu(tester);

    expect(find.text('Asisten sedang sibuk'), findsOneWidget);
    expect(find.text('Ulangi'), findsOneWidget);

    api.events = [const ChatDelta('Sekarang berhasil'), const ChatDone()];
    await tester.tap(find.text('Ulangi'));
    await tunggu(tester);

    expect(find.text('Sekarang berhasil'), findsOneWidget);
    expect(find.text('Asisten sedang sibuk'), findsNothing);
    expect(api.panggilan, 2);
  });

  testWidgets('markdown **tebal** dirender tanpa tanda bintang', (tester) async {
    await pasang(tester, FakeApi([const ChatDelta('Coba **Danau Toba** dulu'), const ChatDone()]), prompt: 'x');
    await tunggu(tester);
    expect(find.textContaining('Danau Toba', findRichText: true), findsOneWidget);
    expect(find.textContaining('**', findRichText: true), findsNothing);
  });

  testWidgets('berfungsi di mode gelap tanpa error render', (tester) async {
    final api = FakeApi([
      const ChatDelta('Halo **gelap**'),
      const ChatDestinasi(['d01']),
      ChatRencana(const DraftRencana(judul: 'Rencana Gelap', jumlahHari: 1, destinasiIds: ['d01'])),
      const ChatDone(),
    ]);
    await pasang(tester, api, gelap: true, prompt: 'halo');
    await tunggu(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Rencana Gelap'), findsOneWidget);
  });
}
