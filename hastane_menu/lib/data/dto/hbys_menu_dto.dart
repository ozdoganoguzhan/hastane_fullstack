import 'package:hastane_menu/core/utils/turkish_text.dart';
import 'package:hastane_menu/models/menu_models.dart';

/// HBYS "aylık-yemek-listesi" yanıtını ([DailyMenu]) uygulama modeline çevirir.
///
/// Kendi REST API'miz, HBYS gövdesini **birebir** (proxy) döner. Bu sınıf o ham
/// JSON kaydını işler:
///  - `kahvaltiY1Adi`, `ogleY2Adi`, `aksamY3Adi` ... → öğün/yemek listesi,
///  - "BEYAZ PEYNİR (95 kcal)" → ad + kalori ayrıştırması,
///  - ALL CAPS adlar → Türkçe başlık biçimi ([TurkishText.titleCase]),
///  - "31.01.2026 00:00:00" → [DateTime].
///
/// HBYS alan adları için bkz. AGENTS.md §15 eşleme tablosu.
sealed class HbysMenuDto {
  /// Tüm yanıtı (`{ "data": [ ... ] }`) günlük menü listesine çevirir.
  static List<DailyMenu> listFromResponse(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(dailyFromJson)
        .toList(growable: false);
  }

  /// `data[]` içindeki tek bir günü çevirir.
  static DailyMenu dailyFromJson(Map<String, dynamic> json) {
    final date =
        _parseDate(json['tarih']) ??
        DateTime(_asInt(json['yil']) ?? 1970, _asInt(json['ay']) ?? 1, 1);

    return DailyMenu(
      id: _asInt(json['id']),
      date: date,
      meals: [
        _meal(json, MealType.kahvalti, 'kahvalti'),
        _meal(json, MealType.ogle, 'ogle'),
        _meal(json, MealType.aksam, 'aksam'),
      ],
    );
  }

  /// Bir öğünün 4 slotunu (`<prefix>Y1..Y4`) toplar.
  static Meal _meal(Map<String, dynamic> json, MealType type, String prefix) {
    final dishes = <MenuDish>[];
    for (var i = 1; i <= 4; i++) {
      final rawName = json['${prefix}Y${i}Adi'];
      if (rawName is! String || rawName.trim().isEmpty) continue;
      final (:name, :calories) = _splitCalories(rawName);
      dishes.add(
        MenuDish(id: _asInt(json['${prefix}Y${i}Id']), name: name, calories: calories),
      );
    }
    return Meal(type: type, dishes: dishes);
  }

  /// "BEYAZ PEYNİR (95 kcal)" → (name: "Beyaz Peynir", calories: 95).
  static ({String name, int? calories}) _splitCalories(String raw) {
    final match = RegExp(
      r'\(\s*(\d+)\s*kcal\s*\)',
      caseSensitive: false,
    ).firstMatch(raw);
    final calories = match == null ? null : int.tryParse(match.group(1)!);
    final cleaned = raw
        .replaceAll(RegExp(r'\(\s*\d+\s*kcal\s*\)', caseSensitive: false), '')
        .trim();
    return (name: TurkishText.titleCase(cleaned), calories: calories);
  }

  /// "31.01.2026 00:00:00" → DateTime(2026, 1, 31). Geçersizse `null`.
  static DateTime? _parseDate(dynamic raw) {
    if (raw is! String || raw.trim().isEmpty) return null;
    final datePart = raw.trim().split(' ').first; // "31.01.2026"
    final parts = datePart.split('.');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  static int? _asInt(dynamic value) => switch (value) {
    final int v => v,
    final num v => v.toInt(),
    final String v => int.tryParse(v),
    _ => null,
  };
}
