// Pratinjau visual: merender komponen kaca ke PNG supaya bisa diperiksa mata.
// Jalankan: PRATINJAU_DIR=/tmp/pratinjau flutter test test/visual/pratinjau_test.dart
// Tanpa PRATINJAU_DIR tes ini dilewati.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tugas_kelompok/models/chat_message.dart';
import 'package:tugas_kelompok/models/rencana_perjalanan.dart';
import 'package:tugas_kelompok/providers/destinasi_provider.dart';
import 'package:tugas_kelompok/theme/app_theme.dart';
import 'package:tugas_kelompok/providers/auth_provider.dart';
import 'package:tugas_kelompok/providers/rencana_provider.dart';
import 'package:tugas_kelompok/providers/lokasi_provider.dart';
import 'package:tugas_kelompok/providers/review_provider.dart';
import 'package:tugas_kelompok/providers/theme_provider.dart';
import 'package:tugas_kelompok/routes/app_routes.dart';
import 'package:tugas_kelompok/screens/auth/login_screen.dart';
import 'package:tugas_kelompok/screens/destinasi/detail_destinasi_screen.dart';
import 'package:tugas_kelompok/screens/destinasi/favorit_screen.dart';
import 'package:tugas_kelompok/screens/home/home_screen.dart';
import 'package:tugas_kelompok/screens/profil/profil_screen.dart';
import 'package:tugas_kelompok/widgets/glass_insets.dart';
import 'package:tugas_kelompok/screens/peta/peta_screen.dart';
import 'package:tugas_kelompok/services/location_service.dart';
import '../lokasi_test.dart' show FakeLokasi;
import 'package:tugas_kelompok/widgets/app_snackbar.dart';
import 'package:tugas_kelompok/widgets/glass_alert.dart';
import 'package:tugas_kelompok/widgets/glass_app_bar.dart';
import 'package:tugas_kelompok/widgets/glass_button.dart';
import 'package:tugas_kelompok/widgets/glass_tab_bar.dart';
import 'package:tugas_kelompok/widgets/kategori_chip.dart';
import 'package:tugas_kelompok/widgets/chat/assistant_status.dart';
import 'package:tugas_kelompok/widgets/chat/chat_bubble.dart';
import 'package:tugas_kelompok/widgets/destinasi_card.dart';
import 'package:tugas_kelompok/widgets/glass_scaffold.dart';
import 'package:tugas_kelompok/widgets/rencana_card.dart';

final _dir = Platform.environment['PRATINJAU_DIR'];

class _TileKosongPratinjau extends TileProvider {
  static final _png = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) => MemoryImage(_png);
}

/// Tes memakai font kotak (Ahem); muat Inter + ikon asli supaya pratinjau mirip HP.
Future<void> _muatFont() async {
  final inter = FontLoader('Inter');
  for (final f in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    final bytes = File('assets/fonts/Inter-$f.ttf').readAsBytesSync();
    inter.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await inter.load();
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    final ikon = File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (ikon.existsSync()) {
      final l = FontLoader('MaterialIcons')
        ..addFont(Future.value(ByteData.sublistView(ikon.readAsBytesSync())));
      await l.load();
    }
  }
}

void main() {
  setUpAll(() async {
    if (_dir != null) await _muatFont();
  });

  for (final gelap in [false, true]) {
    for (final intensitas in [0.5]) {
      testWidgets('pratinjau ${gelap ? 'gelap' : 'terang'} $intensitas', (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = const Size(800, 1900);
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);

        final destinasi = DestinasiProvider();
        await destinasi.muatData();
        final key = GlobalKey();
        final d1 = destinasi.daftarDestinasi[5];
        final d2 = destinasi.daftarDestinasi[3];
        final rencana = RencanaPerjalanan(
          id: 'r1',
          judul: 'Jalan Santai 1 Hari di Medan',
          tanggalMulai: DateTime(2026, 10, 3),
          tanggalSelesai: DateTime(2026, 10, 3),
          daftarDestinasiId: const ['d05', 'd09'],
        );
        final tema = gelap
            ? buildDarkTheme(glassIntensity: intensitas)
            : buildLightTheme(glassIntensity: intensitas);

        await tester.pumpWidget(MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: destinasi),
            ChangeNotifierProvider(create: (_) => ReviewProvider()),
            ChangeNotifierProvider(create: (_) => LokasiProvider()),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: tema,
            home: RepaintBoundary(
              key: key,
              child: GlassScaffold(
                body: SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 220,
                          child: DestinasiCard(destinasi: d1, onTap: () {}, onFavoriteTap: () {}),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DestinasiCard(destinasi: d2, dense: true, onTap: () {}, onFavoriteTap: () {}),
                      const SizedBox(height: 12),
                      RencanaCard(rencana: rencana, jumlahDestinasi: 2, onTap: () {}),
                      const SizedBox(height: 12),
                      const AssistantStatus(teks: 'Tripy lagi mikir…'),
                      const SizedBox(height: 12),
                      ChatBubble(message: ChatMessage.user('Aku mau jalan-jalan di Medan')),
                      const SizedBox(height: 12),
                      ChatBubble(
                        message: const ChatMessage(
                          id: 'm',
                          role: ChatRole.model,
                          text: 'Berikut pilihan menarik di **Medan** untuk kamu.',
                          destinasiIds: ['d05'],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ));
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 80));
        }
        await tester.runAsync(() async {
          final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final f = File('$_dir/${gelap ? 'gelap' : 'terang'}_$intensitas.png');
          f.parent.createSync(recursive: true);
          f.writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      }, skip: _dir == null);
    }
  }

  // --- Lapisan melayang: bar atas, chip, tombol, tab bar, dialog, toast, sheet ---
  for (final gelap in [false, true]) {
    testWidgets('pratinjau chrome ${gelap ? 'gelap' : 'terang'}', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(800, 1700);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      final destinasi = DestinasiProvider();
      await destinasi.muatData();
      final key = GlobalKey();
      final tema = gelap ? buildDarkTheme() : buildLightTheme();
      var tab = 2;

      await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: destinasi),
            ChangeNotifierProvider(create: (_) => ReviewProvider()),
            ChangeNotifierProvider(create: (_) => LokasiProvider()),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: tema,
            home: StatefulBuilder(
              builder: (context, setState) => GlassScaffold(
                appBar: const GlassAppBar(judul: 'Jelajah'),
                body: Stack(
                  children: [
                    ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                      children: [
                        Row(children: [
                          SemuaChip(selected: true, onTap: () {}),
                          const SizedBox(width: 8),
                          KategoriChip(kategori: destinasi.daftarKategori[0], selected: false, onTap: () {}),
                          const SizedBox(width: 8),
                          KategoriChip(kategori: destinasi.daftarKategori[1], selected: false, onTap: () {}),
                        ]),
                        const SizedBox(height: 8),
                        for (var i = 0; i < 6; i++) ...[
                          DestinasiCard(
                              destinasi: destinasi.daftarDestinasi[i], dense: true, onTap: () {}, onFavoriteTap: () {}),
                          const SizedBox(height: 12),
                        ],
                        GlassButton(label: 'Tambah ke Rencana', icon: Icons.map_outlined, variant: GlassButtonVariant.prominent, besar: true, melebar: true, onPressed: () {}),
                        const SizedBox(height: 10),
                        GlassButton(label: 'Tanya Tripy tentang tempat ini', icon: Icons.auto_awesome, melebar: true, onPressed: () {}),
                      ],
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: GlassTabBar(
                        index: tab,
                        onSelect: (i) => setState(() => tab = i),
                        items: const [
                          GlassTabItem(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Beranda'),
                          GlassTabItem(icon: Icons.explore_outlined, selectedIcon: Icons.explore, label: 'Jelajah'),
                          GlassTabItem(icon: Icons.auto_awesome_outlined, selectedIcon: Icons.auto_awesome, label: 'Tripy'),
                          GlassTabItem(icon: Icons.favorite_border, selectedIcon: Icons.favorite, label: 'Favorit'),
                          GlassTabItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profil'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      Future<void> simpan(String nama) => tester.runAsync(() async {
            final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 1);
            final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
            final f = File('$_dir/${nama}_${gelap ? 'gelap' : 'terang'}.png');
            f.parent.createSync(recursive: true);
            f.writeAsBytesSync(bytes!.buffer.asUint8List());
          });
      await simpan('chrome');

      final ctx = tester.element(find.byType(GlassTabBar));
      showGlassAlert<bool>(ctx,
          judul: 'Hapus?',
          pesan: '"Jalan Santai 1 Hari di Medan" akan dihapus permanen.',
          aksi: const [
            GlassAlertAksi(label: 'Batal', nilai: false, utama: true),
            GlassAlertAksi(label: 'Hapus', nilai: true, destruktif: true),
          ]);
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      await simpan('alert');
      Navigator.of(ctx, rootNavigator: true).pop();
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }

      showAppSnackbar(ctx, 'Rencana dihapus');
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      await simpan('toast');
    }, skip: _dir == null);
  }

  // --- Layar penuh (dengan provider) ---
  final layar = <String, Widget Function()>{
    'home': () => const HomePage(),
    'profil': () => const ProfilScreen(),
    'detail': () => const DetailDestinasiScreen(destinasiId: 'd05'),
    'login': () => const LoginPage(),
    'favorit': () => const FavoritScreen(),
  };
  for (final gelap in [false, true]) {
    layar.forEach((nama, bangun) {
      testWidgets('layar $nama ${gelap ? 'gelap' : 'terang'}', (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = Size(800, nama == 'detail' ? 3000 : 1700);
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        final destinasi = DestinasiProvider();
        await destinasi.muatData();
        final rencana = RencanaProvider();
        await rencana.muatData();
        final tema = ThemeProvider();
        await tema.muatData();
        final ulasan = ReviewProvider();
        await ulasan.muatData();
        await ulasan.simpan(destinasiId: 'd05', userId: 'x1', namaPenulis: 'Sari', rating: 5, komentar: 'Megah banget, wajib dikunjungi!');
        await ulasan.simpan(destinasiId: 'd05', userId: 'x2', namaPenulis: 'Budi', rating: 4, komentar: 'Bagus, tapi cukup ramai saat akhir pekan.');
        await ulasan.simpan(destinasiId: 'd05', userId: 'x3', namaPenulis: 'Dewi', rating: 3);
        final key = GlobalKey();
        await tester.pumpWidget(MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: destinasi),
            ChangeNotifierProvider.value(value: rencana),
            ChangeNotifierProvider.value(value: tema),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider.value(value: ulasan),
            ChangeNotifierProvider(create: (_) => LokasiProvider()),
          ],
          child: RepaintBoundary(
            key: key,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: gelap ? buildDarkTheme() : buildLightTheme(),
              onGenerateRoute: AppRoutes.onGenerateRoute,
              home: GlassInsets(bawah: 76, child: bangun()),
            ),
          ),
        ));
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 80));
        }
        await tester.runAsync(() async {
          final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final f = File('$_dir/layar_${nama}_${gelap ? 'gelap' : 'terang'}.png');
          f.parent.createSync(recursive: true);
          f.writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      }, skip: _dir == null);
    });
  }

  // --- Peta (ubin kosong; hanya untuk memeriksa tata letak lapisan kaca) ---
  for (final gelap in [false, true]) {
    testWidgets('peta ${gelap ? 'gelap' : 'terang'}', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(800, 1700);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final destinasi = DestinasiProvider();
      await destinasi.muatData();
      final lokasi = LokasiProvider(
        service: FakeLokasi(cek: IzinLokasi.diizinkan, posisi: const Posisi(3.5952, 98.6722, akurasiMeter: 400)),
      );
      final key = GlobalKey();
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: destinasi),
          ChangeNotifierProvider.value(value: lokasi),
          ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ],
        child: RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: gelap ? buildDarkTheme() : buildLightTheme(),
            home: GlassInsets(bawah: 76, child: PetaScreen(tileProvider: _TileKosongPratinjau())),
          ),
        ),
      ));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      Future<void> simpan(String nama) => tester.runAsync(() async {
            final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 1);
            final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
            final f = File('$_dir/${nama}_${gelap ? 'gelap' : 'terang'}.png');
            f.parent.createSync(recursive: true);
            f.writeAsBytesSync(bytes!.buffer.asUint8List());
          });
      await simpan('peta');
      await tester.tap(find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'Istana Maimun' && w.properties.button == true));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await simpan('peta_pratinjau');
    }, skip: _dir == null);
  }
}
