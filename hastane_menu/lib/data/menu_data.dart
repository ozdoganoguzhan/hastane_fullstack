import 'package:hastane_menu/models/menu_models.dart';

/// Backend bağlanana kadar kullanılan örnek (dummy) menü içeriği.
///
/// Hafta içi 5 günlük sabit bir rotasyon üretir; hafta sonu (Cmt/Paz) menü
/// yoktur. Her gün 3 öğün (kahvaltı/öğle/akşam) × 4 yemek içerir — gerçek
/// veride bu içerik kendi REST API'mizden (HBYS proxy) gelecektir (§15).
sealed class DummyMenuData {
  static MenuDish _d(String name, int kcal) =>
      MenuDish(name: name, calories: kcal);

  static List<Meal> _meals({
    required List<MenuDish> kahvalti,
    required List<MenuDish> ogle,
    required List<MenuDish> aksam,
  }) => [
    Meal(type: MealType.kahvalti, dishes: kahvalti),
    Meal(type: MealType.ogle, dishes: ogle),
    Meal(type: MealType.aksam, dishes: aksam),
  ];

  /// index 0 = Pazartesi ... 4 = Cuma
  static final List<List<Meal>> _weekdayTemplates = [
    // Pazartesi
    _meals(
      kahvalti: [_d('Beyaz Peynir', 95), _d('Siyah Zeytin', 85), _d('Bal & Tereyağı', 173), _d('Çay', 77)],
      ogle: [_d('Mercimek Çorbası', 145), _d('Tavuk Izgara', 280), _d('Bulgur Pilavı', 210), _d('Ayran', 60)],
      aksam: [_d('Domates Çorbası', 120), _d('Etli Nohut', 290), _d('Pirinç Pilavı', 220), _d('Cacık', 80)],
    ),
    // Salı
    _meals(
      kahvalti: [_d('Kaşar Peyniri', 110), _d('Yeşil Zeytin', 88), _d('Domates & Salatalık', 35), _d('Çay', 77)],
      ogle: [_d('Ezogelin Çorbası', 155), _d('Karnıyarık', 320), _d('Şehriyeli Pilav', 230), _d('Komposto', 90)],
      aksam: [_d('Yayla Çorbası', 130), _d('İzmir Köfte', 340), _d('Patates Püresi', 180), _d('Mevsim Salata', 65)],
    ),
    // Çarşamba
    _meals(
      kahvalti: [_d('Beyaz Peynir', 95), _d('Haşlanmış Yumurta', 78), _d('Reçel', 120), _d('Çay', 77)],
      ogle: [_d('Tarhana Çorbası', 140), _d('Etli Türlü', 290), _d('Makarna', 250), _d('Çoban Salata', 55)],
      aksam: [_d('Mercimek Çorbası', 145), _d('Fırın Tavuk', 300), _d('Bulgur Pilavı', 210), _d('Muhallebi', 170)],
    ),
    // Perşembe
    _meals(
      kahvalti: [_d('Sucuklu Yumurta', 210), _d('Siyah Zeytin', 85), _d('Bal & Tereyağı', 173), _d('Çay', 77)],
      ogle: [_d('Domates Çorbası', 120), _d('Köfte', 340), _d('Pirinç Pilavı', 220), _d('Havuç Tarator', 95)],
      aksam: [_d('Brokoli Çorba', 147), _d('Mantı', 354), _d('Börülce Salatası', 270), _d('Portakal', 98)],
    ),
    // Cuma
    _meals(
      kahvalti: [_d('Kaşar Peyniri', 110), _d('Yeşil Zeytin', 88), _d('Menemen', 230), _d('Çay', 77)],
      ogle: [_d('Yayla Çorbası', 130), _d('Balık Izgara', 260), _d('Pilav', 220), _d('Roka Salata', 70)],
      aksam: [_d('Tavuk Çorba', 120), _d('Etli Kuru Fasulye', 310), _d('Bulgur Pilavı', 210), _d('Kazandibi', 200)],
    ),
  ];

  /// Verilen ayın tüm hafta içi günleri için menü üretir.
  static List<DailyMenu> month(int year, int month) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final result = <DailyMenu>[];
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      if (date.weekday >= DateTime.saturday) continue; // hafta sonu menü yok
      result.add(
        DailyMenu(
          id: year * 10000 + month * 100 + day,
          date: date,
          meals: _weekdayTemplates[date.weekday - 1],
        ),
      );
    }
    return result;
  }
}
