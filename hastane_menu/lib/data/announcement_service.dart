import 'package:hastane_menu/core/constants/app_config.dart';
import 'package:hastane_menu/core/state/session_state.dart';
import 'package:hastane_menu/core/state/state_manager.dart';
import 'package:hastane_menu/data/announcement_repository.dart';
import 'package:hastane_menu/models/announcement.dart';

/// Duyuru erişiminde tek giriş noktası — UI buradan veri ister.
///
/// Kaynağı oturuma + config'e göre seçer (menü deseniyle birebir):
///  - demo oturum (`isDemo`) **veya** [AppConfig.useRemoteApi] kapalı → dummy,
///  - aksi hâlde → kendi REST API'miz (remote).
class AnnouncementService {
  AnnouncementService({required this.dummy, required this.remote});

  final AnnouncementRepository dummy;
  final AnnouncementRepository remote;

  List<Announcement>? _cache;

  bool get _useDummy {
    final isDemo = $get<SessionState>().current?.isDemo ?? true;
    return isDemo || !AppConfig.useRemoteApi;
  }

  Future<List<Announcement>> all({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache != null) return _cache!;
    final list = await (_useDummy ? dummy : remote).all();
    _cache = list;
    return list;
  }

  void clearCache() => _cache = null;
}
