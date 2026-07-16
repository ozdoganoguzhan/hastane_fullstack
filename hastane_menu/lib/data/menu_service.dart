import 'package:hastane_menu/core/cache/sliding_cache.dart';
import 'package:hastane_menu/core/network/hbys_client.dart';
import 'package:hastane_menu/core/utils/date_utils.dart';
import 'package:hastane_menu/data/dto/hbys_menu_dto.dart';
import 'package:hastane_menu/models/menu_models.dart';

/// Menü erişiminde tek giriş noktası — UI buradan veri ister.
///
/// Veri **doğrudan Turkcell HBYS**'den gelir (araya bizim API'miz girmez).
/// Ay bazında 10 dakikalık **kayan süreli bellek önbelleği** tutar; böylece
/// her ekran açılışında HBYS'ye istek atılmaz (bkz. [SlidingCache]).
class MenuService {
  MenuService({required HbysClient client, SlidingCache<String, List<DailyMenu>>? cache})
    : _client = client,
      _cache = cache ?? SlidingCache<String, List<DailyMenu>>();

  final HbysClient _client;
  final SlidingCache<String, List<DailyMenu>> _cache;

  /// Belirli ayın menüleri (önbellekli).
  Future<List<DailyMenu>> month(int year, int month) {
    return _cache.getOrLoad('$year-$month', () async {
      final json = await _client.monthlyMenu(year, month);
      return HbysMenuDto.listFromResponse(json);
    });
  }

  /// Tek bir günün menüsü (kayıt yoksa boş gün).
  Future<DailyMenu> day(DateTime date) async {
    final list = await month(date.year, date.month);
    for (final menu in list) {
      if (AppDateUtils.isSameDay(menu.date, date)) return menu;
    }
    return DailyMenu.empty(date);
  }

  /// [monday]'den itibaren Pazartesi..Cuma haftası. Hafta iki aya yayılıyorsa
  /// her iki ay da (önbellek üzerinden) yüklenir. Eksik günler boş döner.
  Future<List<DailyMenu>> week(DateTime monday) async {
    final days = List.generate(
      5,
      (i) => DateTime(monday.year, monday.month, monday.day + i),
    );
    final months = <String, List<DailyMenu>>{};
    for (final d in days) {
      months['${d.year}-${d.month}'] ??= await month(d.year, d.month);
    }
    return days.map((d) {
      final list = months['${d.year}-${d.month}']!;
      for (final menu in list) {
        if (AppDateUtils.isSameDay(menu.date, d)) return menu;
      }
      return DailyMenu.empty(d);
    }).toList(growable: false);
  }

  /// Önbelleği temizler (örn. oturum değişiminde / manuel yenilemede).
  void clearCache() => _cache.clear();
}
