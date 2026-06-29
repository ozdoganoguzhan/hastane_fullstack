import 'package:hastane_menu/core/constants/app_config.dart';
import 'package:hastane_menu/core/state/session_state.dart';
import 'package:hastane_menu/core/state/state_manager.dart';
import 'package:hastane_menu/data/hospital_info_repository.dart';
import 'package:hastane_menu/models/hospital_info.dart';

/// Hastane bilgisi erişiminde tek giriş noktası (menü/duyuru deseniyle birebir).
class HospitalInfoService {
  HospitalInfoService({required this.dummy, required this.remote});

  final HospitalInfoRepository dummy;
  final HospitalInfoRepository remote;

  HospitalInfo? _cache;

  bool get _useDummy {
    final isDemo = $get<SessionState>().current?.isDemo ?? true;
    return isDemo || !AppConfig.useRemoteApi;
  }

  Future<HospitalInfo> get({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache != null) return _cache!;
    final info = await (_useDummy ? dummy : remote).get();
    _cache = info;
    return info;
  }

  void clearCache() => _cache = null;
}
