// Basit smoke test: ana sayfa veriyle birlikte sorunsuz render oluyor mu?
// (Tam uygulama NetworkGate ile sarılı olduğu için doğrudan HomePage test edilir.)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hastane_menu/pages/home_page.dart';

void main() {
  testWidgets('HomePage bölüm başlıklarını gösterir', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: HomePage(onNavigate: (_) {})),
      ),
    );

    expect(find.text('🍴 Bugünün Menüsü'), findsOneWidget);
    expect(find.text('📢 Duyurular'), findsOneWidget);
  });
}
