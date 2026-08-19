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

  /// SSID doğru ama bağlı olunan erişim noktası (AP/BSSID) hastaneye ait değil.
  wrongAccessPoint,

  /// Mobil veri / kablolu / hiç bağlantı yok.
  notWifi,

  /// SSID okuma izni reddedildi (Android: konum / nearbyWifi).
  permissionDenied,

  /// İzin var ama cihazın konum servisleri kapalı (Android).
  locationOff,

  /// İzin VAR, konum servisi AÇIK — ama işletim sistemi ağ adını yine de
  /// vermiyor (iOS entitlement eksik, üretici kısıtı, VPN vb.).
  ///
  /// ⚠️ Bunu [permissionDenied] ile birleştirmeyin: izin vermiş kullanıcıya
  /// "konum izni gerekiyor" demek çıkışı olmayan bir döngüdür.
  ssidUnavailable,
}

class WifiGuard implements IDisposable {
  final Connectivity _connectivity = Connectivity();
  final NetworkInfo _netInfo = NetworkInfo();

  StreamSubscription<List<ConnectivityResult>>? _sub;

  /// Kapı durumunu yayan reaktif state. UI bunu dinler.
  final ReactiveState<WifiGuardStatus> status =
      ReactiveState<WifiGuardStatus>(WifiGuardStatus.checking);

  /// Son değerlendirmede okunabilen ağ adı — engelleme ekranı "şu an X
  /// ağındasınız" diyebilsin diye tutulur. Okunamadıysa `null`.
  String? currentSsid;

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
  ///
  /// ⭐ Kapı **FAIL-CLOSED**'dır: bir kontrol yapıl*a*mıyorsa (izin verilmedi,
  /// konum servisi kapalı, OS değeri maskeledi) kullanıcı İÇERİ ALINMAZ; ne
  /// eksikse onu söyleyen ekran gösterilir. İzin vermeyen erişemez.
  ///
  /// Gerekçe: SSID taklit edilebilir (telefon hotspot'u). BSSID okunamadığında
  /// "SSID doğruydu, geçsin" demek kapıyı tamamen anlamsızlaştırır.
  Future<WifiGuardStatus> evaluate() async {
    currentSsid = null;

    // 1) Bağlantı tipi — ucuz ve anlık. WiFi yoksa hemen reddet.
    final conn = await _connectivity.checkConnectivity();
    if (!conn.contains(ConnectivityResult.wifi)) {
      return WifiGuardStatus.notWifi;
    }

    // 2) SSID izinli mi? Okunamıyorsa sebebini DOĞRU söyle ve ENGELLE.
    if (AppConfig.enforceSsid) {
      final ssid = _stripQuotes(await _safe(() => _netInfo.getWifiName()));

      if (_isUnknownSsid(ssid)) return _diagnoseUnreadable();

      currentSsid = ssid;
      if (!_isAllowed(ssid!)) return WifiGuardStatus.wrongWifi;
    }

    // 3) Bağlı AP'nin MAC (BSSID) öneki hastaneye ait mi?
    //    Okunamıyor/maskeli ise (izin veya konum servisi eksik) → ENGELLE.
    if (AppConfig.enforceBssid && AppConfig.allowedBssidPrefixes.isNotEmpty) {
      final bssid = _normalizeMac(await _safe(() => _netInfo.getWifiBSSID()));

      if (bssid == null || bssid.length < 12 || _isMaskedMac(bssid)) {
        return _diagnoseUnreadable();
      }

      final allowed = AppConfig.allowedBssidPrefixes
          .map(_normalizeMac)
          .whereType<String>()
          .any(bssid.startsWith);

      if (!allowed) return WifiGuardStatus.wrongAccessPoint;
    }

    // 4) Opsiyonel ek kanıt: yalnızca intranet'ten erişilebilen host.
    if (AppConfig.enableReachabilityCheck && !await _internalHostReachable()) {
      return WifiGuardStatus.wrongWifi;
    }

    return WifiGuardStatus.onAllowedWifi;
  }

  // ── Yardımcılar ──────────────────────────────────────────────────────────

  bool _isAllowed(String ssid) {
    final target = ssid.toLowerCase().trim();
    return AppConfig.allowedSsids
        .map((s) => s.toLowerCase().trim())
        .contains(target);
  }

  /// "04:ca:ed:11:22:33" · "04-CA-ED-11-22-33" · "04caed" → "04caed112233"
  String? _normalizeMac(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.toLowerCase().replaceAll(RegExp('[^0-9a-f]'), '');
    return cleaned.isEmpty ? null : cleaned;
  }

  /// Android, izin verilmemişse **veya konum servisleri kapalıysa** BSSID'i
  /// maskeler: `02:00:00:00:00:00`. Bu değer "okuyamadım" demektir → engelle.
  /// Kaynak: developer.android.com/reference/android/net/wifi/WifiInfo
  bool _isMaskedMac(String mac) =>
      mac == '020000000000' || mac == '000000000000';

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

  /// SSID/BSSID neden okunamadı? İzin mi yok, konum servisi mi kapalı, yoksa
  /// ikisi de tamam da OS mu vermiyor?
  ///
  /// **Android** (kaynak: developer.android.com/develop/connectivity/wifi/wifi-permissions):
  ///  • Bağlı ağın SSID/BSSID'i (`WifiManager.getConnectionInfo`) HER sürümde
  ///    ACCESS_FINE_LOCATION ister; API ≥ 33'te ek olarak NEARBY_WIFI_DEVICES.
  ///  • Ayrıca **konum servisleri AÇIK** olmalı; kapalıysa izin verilmiş olsa
  ///    bile SSID `<unknown ssid>`, BSSID `02:00:00:00:00:00` döner.
  ///
  /// **iOS** (kaynak: developer.apple.com — Access Wi-Fi Information Entitlement):
  ///  • `com.apple.developer.networking.wifi-info` entitlement (ÜCRETLİ hesap) +
  ///  • konum izni (When In Use, precise) + konum servisleri açık.
  ///
  /// Sebep saptanamazsa [WifiGuardStatus.ssidUnavailable] döner — asla
  /// "izin yok" diye yanlış teşhis koymaz.
  Future<WifiGuardStatus> _diagnoseUnreadable() async {
    try {
      if (Platform.isAndroid) {
        final sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;

        if (!(await Permission.locationWhenInUse.status).isGranted) {
          return WifiGuardStatus.permissionDenied;
        }
        if (sdkInt >= 33 &&
            !(await Permission.nearbyWifiDevices.status).isGranted) {
          return WifiGuardStatus.permissionDenied;
        }
        if (await Permission.location.serviceStatus == ServiceStatus.disabled) {
          return WifiGuardStatus.locationOff;
        }
        return WifiGuardStatus.ssidUnavailable;
      }

      if (Platform.isIOS) {
        if (!(await Permission.locationWhenInUse.status).isGranted) {
          return WifiGuardStatus.permissionDenied;
        }
        if (await Permission.location.serviceStatus == ServiceStatus.disabled) {
          return WifiGuardStatus.locationOff;
        }
        // İzin/servis tamam ama okunamıyorsa entitlement eksiktir (ücretli hesap).
        return WifiGuardStatus.ssidUnavailable;
      }
    } catch (_) {
      return WifiGuardStatus.ssidUnavailable;
    }
    return WifiGuardStatus.ssidUnavailable;
  }

  /// SSID/BSSID okumak için gereken izinleri ister, ardından kapıyı **yeniden
  /// değerlendirir** (izin verildiği anda ekran kendiliğinden geçsin diye).
  ///
  /// Bağlı ağın adı her Android sürümünde konum iznine bağlıdır; 13+ ayrıca
  /// NEARBY_WIFI_DEVICES ister → **ikisi birden** istenir. Kullanıcı daha önce
  /// "bir daha sorma" dediyse `request()` sessizce geri döner; bu durumda tek
  /// çıkış uygulama ayarlarıdır, oraya yönlendirilir.
  Future<void> requestPermission() async {
    try {
      if (Platform.isAndroid) {
        final sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
        final results = await <Permission>[
          Permission.locationWhenInUse,
          if (sdkInt >= 33) Permission.nearbyWifiDevices,
        ].request();

        if (results.values.any((s) => s.isPermanentlyDenied)) {
          await openAppSettings();
        }
      } else if (Platform.isIOS) {
        final result = await Permission.locationWhenInUse.request();
        if (result.isPermanentlyDenied) await openAppSettings();
      }
    } catch (_) {
      // sessizce yut — kullanıcı ayarlardan da verebilir.
    }
    await refresh();
  }

  /// LAN varlığını kanıtlar: yalnızca hastane içinde route edilebilen host
  /// kısa timeout içinde cevap verirse ağdayız demektir.
  Future<bool> _internalHostReachable() async {
    final client = HttpClient()
      ..connectionTimeout = AppConfig.reachabilityTimeout;
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
