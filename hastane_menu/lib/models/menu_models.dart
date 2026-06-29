/// Menü veri modelleri.
///
/// Yapı, HBYS "aylık-yemek-listesi" servisine göre kurulmuştur (bkz. AGENTS.md
/// §15): her gün **3 öğün** (kahvaltı / öğle / akşam) içerir, her öğünde en
/// fazla **4 yemek** (HBYS Y1..Y4) bulunur. Kalori bilgisi yemek adından
/// ayıklanır.
library;

/// Öğün türü — HBYS alan önekleriyle (kahvalti / ogle / aksam) eşleşir.
enum MealType {
  kahvalti('Kahvaltı', '🌅'),
  ogle('Öğle', '☀️'),
  aksam('Akşam', '🌙');

  const MealType(this.label, this.emoji);

  /// UI'da gösterilen Türkçe etiket.
  final String label;

  /// Öğünü temsil eden emoji.
  final String emoji;
}

/// Tek bir yemek (HBYS Y1..Y4 slotlarından biri).
class MenuDish {
  const MenuDish({this.id, required this.name, this.calories});

  /// HBYS yemek kimliği (örn. `ogleY2Id`).
  final int? id;

  /// Okunur yemek adı — kalori bilgisi ayıklanmış hâli.
  final String name;

  /// Yemek adından parse edilen kalori; yoksa `null`.
  final int? calories;

  bool get hasCalories => calories != null && calories! > 0;
}

/// Bir öğün ve içindeki yemekler.
class Meal {
  const Meal({required this.type, required this.dishes});

  final MealType type;
  final List<MenuDish> dishes;

  int get totalCalories =>
      dishes.fold(0, (sum, dish) => sum + (dish.calories ?? 0));

  bool get isEmpty => dishes.isEmpty;
  bool get isNotEmpty => dishes.isNotEmpty;
}

/// Bir günün menüsü — 0..3 dolu öğün.
class DailyMenu {
  const DailyMenu({this.id, required this.date, required this.meals});

  /// Boş (kayıt bulunmayan) gün için kısayol.
  DailyMenu.empty(DateTime date)
    : id = null,
      date = DateTime(date.year, date.month, date.day),
      meals = const [];

  /// HBYS kayıt kimliği (`id`).
  final int? id;

  /// Günün tarihi (saat bileşeni sıfırlanmış).
  final DateTime date;

  /// Öğünler (boş öğünler de listede olabilir).
  final List<Meal> meals;

  /// Yalnızca dolu öğünler.
  List<Meal> get nonEmptyMeals =>
      meals.where((meal) => meal.isNotEmpty).toList(growable: false);

  /// Belirli bir öğünü döner (yoksa / boşsa `null`).
  Meal? mealOf(MealType type) {
    for (final meal in meals) {
      if (meal.type == type && meal.isNotEmpty) return meal;
    }
    return null;
  }

  int get totalCalories =>
      meals.fold(0, (sum, meal) => sum + meal.totalCalories);

  /// O gün için gösterilecek hiçbir öğün yoksa `true`.
  bool get isEmpty => nonEmptyMeals.isEmpty;
}
