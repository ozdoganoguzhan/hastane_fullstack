import 'package:hastane_menu/core/constants/app_config.dart';
import 'package:hastane_menu/core/state/session_state.dart';
import 'package:hastane_menu/core/state/state_manager.dart';
import 'package:hastane_menu/core/utils/date_utils.dart';
import 'package:hastane_menu/data/menu_repository.dart';
import 'package:hastane_menu/models/menu_models.dart';

/// Menü erişiminde tek giriş noktası — UI buradan veri ister.
///
/// Ay bazında **cache** tutar (aynı ay tekrar tekrar ağdan çekilmez) ve aktif
/// kaynağı oturuma + config'e göre seçer:
///  - demo oturum (`isDemo`) **veya** [AppConfig.useRemoteApi] kapalı → dummy,
///  - aksi hâlde → kendi REST API'miz (remote).
class MenuService {
  MenuService({required this.dummy, required this.remote});

  final MenuRepository dummy;
  final MenuRepository remote;

  final Map<String, List<DailyMenu>> _cache = {};

  bool get _useDummy {
    final isDemo = $get<SessionState>().current?.isDemo ?? true;
    return isDemo || !AppConfig.useRemoteApi;
  }

  MenuRepository get _repo => _useDummy ? dummy : remote;

  /// Belirli ayın menüleri (cache'li).
  Future<List<DailyMenu>> month(int year, int month) async {
    final key = '${_useDummy ? 'd' : 'r'}-$year-$month';
    final cached = _cache[key];
    if (cached != null) return cached;
    final list = await _repo.monthlyMenu(year, month);
    _cache[key] = list;
    return list;
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
  /// her iki ay da (cache üzerinden) yüklenir. Eksik günler boş döner.
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

  /// Önbelleği temizler (örn. oturum değişiminde).
  void clearCache() => _cache.clear();
}
