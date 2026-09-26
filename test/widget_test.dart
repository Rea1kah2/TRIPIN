import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tugas_kelompok/main.dart';

void main() {
  testWidgets('TRIPIN membuka layar Login', (WidgetTester tester) async {
    await tester.pumpWidget(const TripinApp());

    expect(find.text('TRIPIN'), findsOneWidget);
    expect(find.text('Selamat Datang 👋'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Masuk'), findsOneWidget);
  });
}
