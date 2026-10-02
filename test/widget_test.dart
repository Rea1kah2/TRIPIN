import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tugas_kelompok/main.dart';
import 'package:tugas_kelompok/widgets/glass_button.dart';

void main() {
  testWidgets('TRIPIN membuka layar Login', (WidgetTester tester) async {
    // Beri nilai awal palsu supaya SharedPreferences.getInstance() bisa
    // resolve di lingkungan test (tidak ada platform asli di sini).
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const TripinApp());
    await tester.pumpAndSettle(); // tunggu AppGate selesai memuat data lokal

    expect(find.text('TRIPIN'), findsOneWidget);
    expect(find.text('Selamat Datang 👋'), findsOneWidget);
    expect(find.widgetWithText(GlassButton, 'Masuk'), findsOneWidget);
  });
}
