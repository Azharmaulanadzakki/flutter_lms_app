import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smk_tkj_lms/app.dart';

void main() {
  testWidgets('App menampilkan pesan error jika Firebase gagal diinisialisasi',
      (WidgetTester tester) async {
    await tester.pumpWidget(const App(initError: 'error simulasi'));

    expect(find.text('Firebase gagal terhubung'), findsOneWidget);
    expect(find.text('error simulasi'), findsOneWidget);
    expect(find.byIcon(Icons.error), findsOneWidget);
  });
}