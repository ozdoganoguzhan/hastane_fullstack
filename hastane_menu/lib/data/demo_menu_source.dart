import 'package:hastane_menu/models/menu_models.dart';

/// Demo (test) oturumu için örnek menü üretici.
///
/// ⚠️ Yalnızca `StaffSession.isDemo == true` iken kullanılır. Gerçek menü
/// HBYS'den gelir ve HBYS host'ları **yalnızca hastane intranet'inden**
/// çözülür; ağ dışında test girişi yapan kullanıcı aksi hâlde boş ekran
/// görürdü (bkz. AGENTS.md §4.0, §14).
///
/// Üretim **deterministiktir**: aynı tarih her zaman aynı menüyü verir, böylece
/// ekranlar arası (bugün / hafta / ay) tutarlı görünür ve rastgelelik yüzünden
/// veri "oynamaz".
sealed class DemoMenuSource {
  /// Hafta içi günler için örnek menü; hafta sonu boş gün döner.
  static List<DailyMenu> month(int year, int month) {
    final dayCount = DateTime(year, month + 1, 0).day;
    return List<DailyMenu>.generate(dayCount, (i) {
      final date = DateTime(year, month, i + 1);
      return day(date);
    }, growable: false);
  }

  /// Tek günün örnek menüsü. Hafta sonu → boş gün (yemekhane kapalı).
  static DailyMenu day(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    if (normalized.weekday == DateTime.saturday ||
        normalized.weekday == DateTime.sunday) {
      return DailyMenu.empty(normalized);
    }

    // Gün sırasına göre sabit rotasyon — rastgelelik yok.
    final slot = (normalized.difference(DateTime(2026, 1, 1)).inDays % 5).abs();

    return DailyMenu(
      date: normalized,
      meals: [
        Meal(type: MealType.kahvalti, dishes: _dishes(_breakfast[slot])),
        Meal(type: MealType.ogle, dishes: _dishes(_lunch[slot])),
        Meal(type: MealType.aksam, dishes: _dishes(_dinner[slot])),
      ],
    );
  }

  static List<MenuDish> _dishes(List<(String, int)> raw) => raw
      .map((e) => MenuDish(name: e.$1, calories: e.$2))
      .toList(growable: false);

  // ── Örnek yemekler (5 günlük rotasyon, HBYS'deki gibi öğün başına 4 slot) ──

  static const List<List<(String, int)>> _breakfast = [
    [('Beyaz Peynir', 90), ('Siyah Zeytin', 60), ('Haşlanmış Yumurta', 78), ('Bal & Tereyağı', 120)],
    [('Kaşar Peyniri', 110), ('Yeşil Zeytin', 55), ('Domates & Salatalık', 30), ('Reçel', 100)],
    [('Menemen', 210), ('Beyaz Peynir', 90), ('Siyah Zeytin', 60), ('Tahin & Pekmez', 140)],
    [('Sucuklu Yumurta', 260), ('Kaşar Peyniri', 110), ('Yeşil Zeytin', 55), ('Bal', 90)],
    [('Peynirli Poğaça', 230), ('Beyaz Peynir', 90), ('Domates & Salatalık', 30), ('Reçel', 100)],
  ];

  static const List<List<(String, int)>> _lunch = [
    [('Mercimek Çorbası', 150), ('Etli Kuru Fasulye', 380), ('Pirinç Pilavı', 250), ('Cacık', 80)],
    [('Ezogelin Çorbası', 160), ('Tavuk Sote', 320), ('Bulgur Pilavı', 220), ('Mevsim Salata', 60)],
    [('Domates Çorbası', 140), ('İzmir Köfte', 400), ('Makarna', 260), ('Ayran', 60)],
    [('Yayla Çorbası', 155), ('Karnıyarık', 350), ('Pirinç Pilavı', 250), ('Yoğurt', 90)],
    [('Tarhana Çorbası', 145), ('Fırın Tavuk', 340), ('Şehriyeli Pilav', 240), ('Mevsim Salata', 60)],
  ];

  static const List<List<(String, int)>> _dinner = [
    [('Sebze Çorbası', 130), ('Etli Nohut', 360), ('Bulgur Pilavı', 220), ('Sütlaç', 210)],
    [('Şehriye Çorbası', 140), ('Fırın Makarna', 380), ('Yoğurt', 90), ('Meyve', 70)],
    [('Mercimek Çorbası', 150), ('Kıymalı Ispanak', 280), ('Pirinç Pilavı', 250), ('Kemalpaşa Tatlısı', 290)],
    [('Brokoli Çorbası', 135), ('Tavuk Şiş', 330), ('Bulgur Pilavı', 220), ('Cacık', 80)],
    [('Ezogelin Çorbası', 160), ('Etli Türlü', 340), ('Makarna', 260), ('Meyve', 70)],
  ];
}
