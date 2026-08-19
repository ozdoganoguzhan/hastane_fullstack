// Basit smoke test: ana sayfa veriyle birlikte sorunsuz render oluyor mu?
// (Tam uygulama NetworkGate ile sarılı olduğu için doğrudan HomePage test
// edilir; menü servisi ağa çıkmayan bir sahte ile değiştirilir.)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hastane_menu/core/network/hbys_client.dart';
import 'package:hastane_menu/core/state/session_state.dart';
import 'package:hastane_menu/core/state/state_manager.dart';
import 'package:hastane_menu/data/menu_service.dart';
import 'package:hastane_menu/models/menu_models.dart';
import 'package:hastane_menu/pages/home_page.dart';

/// Ağa çıkmadan sabit bir günlük menü dönen sahte servis.
class _FakeMenuService extends MenuService {
  _FakeMenuService() : super(client: HbysClient());

  @override
  Future<DailyMenu> day(DateTime date) async => DailyMenu(
    date: DateTime(date.year, date.month, date.day),
    meals: const [
      Meal(
        type: MealType.ogle,
        dishes: [MenuDish(name: 'Mercimek Çorbası', calories: 95)],
      ),
    ],
  );
}

void main() {
  setUp(() {
    SM.reset();
    SM.register<SessionState>(SessionState());
    SM.register<MenuService>(_FakeMenuService());
  });

  testWidgets('HomePage bölümleri ve bugünün menüsünü gösterir', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: HomePage(onNavigate: (_) {})),
      ),
    );

    // Sahte menü future'ı çözülsün + giriş animasyonları tamamlansın.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Bugünün Menüsü'), findsOneWidget);
    expect(find.text('Hızlı Erişim'), findsOneWidget);
    expect(find.text('Mercimek Çorbası'), findsOneWidget);
  });
}
