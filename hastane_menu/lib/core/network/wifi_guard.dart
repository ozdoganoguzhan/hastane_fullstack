import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:hastane_menu/core/constants/app_config.dart';
import 'package:hastane_menu/core/state/state_manager.dart';

/// Ağ kapısının (network gate) sonucu.
enum WifiGuardStatus {
  /// İlk değerlendirme / devam eden kontrol.
  checking,

  /// İzinli ağdayız → uygulama içeriği gösterilir.
  onAllowedWifi,

  /// WiFi var ama SSID izinli değil ve intranet host'a ulaşılamıyor.
  wrongWifi,

  /// Mobil veri / kablolu / hiç bağlantı yok.
  notWifi,

  /// SSID okuma izni reddedildi (Android: nearbyWifi / location).
  permissionDenied,

  /// İzin var ama cihazın konum servisleri kapalı (Android).
  locationOff,
}


class WifiGuard implements IDisposable {
  final Connectivity _connectivity = Connectivity();
  final NetworkInfo _netInfo = NetworkInfo();

  StreamSubscription<List<ConnectivityResult>>? _sub;

  /// Kapı durumunu yayan reaktif state. UI bunu dinler.
  final ReactiveState<WifiGuardStatus> status =
      ReactiveState<WifiGuardStatus>(WifiGuardStatus.checking);

  /// Connectivity değişimlerini dinlemeye başla + ilk kontrolü yap.
  void start() {
    _sub ??= _connectivity.onConnectivityChanged.listen((_) {
      // Android 14'te ağ tam oturmadan transient değerler gelebilir; kısa
      // bir gecikme ile yeniden değerlendir.
      Future<void>.delayed(const Duration(milliseconds: 400), refresh);
    });
    refresh();
  }

  /// Kapıyı yeniden değerlendir ([status] güncellenir).
  Future<void> refresh() async {
    status.value = WifiGuardStatus.checking;
    status.value = await evaluate();
  }

  /// Tek seferlik tam değerlendirme.
  Future<WifiGuardStatus> evaluate() async {
    // 1) Bağlantı tipi — ucuz ve anlık. WiFi yoksa hemen reddet.
    final conn = await _connectivity.checkConnectivity();
    if (!conn.contains(ConnectivityResult.wifi)) {
      return WifiGuardStatus.notWifi;
    }

    // 2) Hızlı yol: SSID allowlist (best-effort; iOS'ta entitlement yoksa null).
    if (AppConfig.enforceSsid) {
      final ssid = _stripQuotes(await _safe(() => _netInfo.getWifiName()));
      if (!_isUnknownSsid(ssid) && _isAllowed(ssid!)) {
        return WifiGuardStatus.onAllowedWifi;
      }

      // 3) SSID okunamadıysa nedenini ayırt et (Android UX için).
      if (_isUnknownSsid(ssid)) {
        final reason = await _diagnoseSsidFailure();
        if (reason != null) {
          // İzin/konum sorunu olsa bile reachability açıksa son sözü o söyler.
          if (AppConfig.enableReachabilityCheck &&
              await _internalHostReachable()) {
            return WifiGuardStatus.onAllowedWifi;
          }
          return reason;
        }
      }
    }

    // 4) Otoritatif yol: yalnızca intranet'ten erişilebilen host'a ulaş.
    if (AppConfig.enableReachabilityCheck && await _internalHostReachable()) {
      return WifiGuardStatus.onAllowedWifi;
    }

    // 5) SSID zorunlu değilse ve reachability kapalıysa: WiFi'da olmak yeter.
    if (!AppConfig.enforceSsid && !AppConfig.enableReachabilityCheck) {
      return WifiGuardStatus.onAllowedWifi;
    }

    return WifiGuardStatus.wrongWifi;
  }

  // ── Yardımcılar ──────────────────────────────────────────────────────────

  bool _isAllowed(String ssid) {
    final target = ssid.toLowerCase().trim();
    return AppConfig.allowedSsids
        .map((s) => s.toLowerCase().trim())
        .contains(target);
  }

  /// Android'de SSID OS tarafından çift tırnakla sarılabilir; eşleşen çifti soy.
  String? _stripQuotes(String? ssid) {
    if (ssid == null) return null;
    if (ssid.length >= 2 && ssid.startsWith('"') && ssid.endsWith('"')) {
      return ssid.substring(1, ssid.length - 1);
    }
    return ssid;
  }

  bool _isUnknownSsid(String? ssid) =>
      ssid == null || ssid.isEmpty || ssid == '<unknown ssid>';

  /// SSID neden okunamadı? İzin reddi mi, konum servisi kapalı mı?
  /// Android dışında (iOS entitlement vb.) ayırt edemeyiz → null.
  Future<WifiGuardStatus?> _diagnoseSsidFailure() async {
    if (!Platform.isAndroid) return null;
    try {
      final sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
      final permission = sdkInt >= 33
          ? Permission.nearbyWifiDevices
          : Permission.locationWhenInUse;
      final permStatus = await permission.status;
      if (!permStatus.isGranted) return WifiGuardStatus.permissionDenied;

      final service = await Permission.location.serviceStatus;
      if (service == ServiceStatus.disabled) {
        return WifiGuardStatus.locationOff;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  /// SSID okumak için gereken izni iste (Android). Engelleme ekranından çağrılır.
  Future<void> requestPermission() async {
    if (!Platform.isAndroid) return;
    try {
      final sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
      if (sdkInt >= 33) {
        await Permission.nearbyWifiDevices.request();
      } else {
        await Permission.locationWhenInUse.request();
      }
    } catch (_) {
      // sessizce yut — kullanıcı ayarlardan da verebilir.
    }
  }

  /// LAN varlığını kanıtlar: yalnızca hastane içinde route edilebilen host
  /// kısa timeout içinde cevap verirse ağdayız demektir.
  Future<bool> _internalHostReachable() async {
    final client = HttpClient()..connectionTimeout = AppConfig.reachabilityTimeout;
    try {
      final request = await client
          .headUrl(Uri.parse(AppConfig.intranetHealthUrl))
          .timeout(AppConfig.reachabilityTimeout);
      final response = await request.close().timeout(
        AppConfig.reachabilityTimeout,
      );
      return response.statusCode >= 200 && response.statusCode < 400;
    } catch (_) {
      return false; // timeout / SocketException → host'a route yok → ağda değiliz.
    } finally {
      client.close(force: true);
    }
  }

  Future<T?> _safe<T>(Future<T?> Function() fn) async {
    try {
      return await fn();
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _sub = null;
    status.dispose();
  }
}
