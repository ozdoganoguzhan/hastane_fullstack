/// ─────────────────────────────────────────────────────────────────────────
/// UYGULAMA YAPILANDIRMASI — TEK MERKEZ
/// ─────────────────────────────────────────────────────────────────────────
///
/// Bu uygulama BAŞKA BİR HASTANEYE kurulurken SADECE bu dosya düzenlenir.
///
/// ⚠️  Mimari: Uygulama **doğrudan Turkcell HBYS** servislerine bağlanır.
///     Araya bizim bir API'miz GİRMEZ. Turkcell entegrasyon dokümanındaki
///     protokolün aynısı konuşulur (entegre-login → Bearer → servisler).
///
/// ⭐ [useMockHbys] tek anahtardır:
///     true  → yerel mock sunucu (doküman ile BİREBİR, geliştirme içindir)
///     false → GERÇEK Turkcell HBYS host'ları (canlı) — hiçbir dummy kalmaz
sealed class AppConfig {
  // ══════════════════════════════════════════════════════════════════════
  // KURUM BİLGİLERİ
  // ══════════════════════════════════════════════════════════════════════
  static const String hospitalName = 'Eskişehir Şehir Hastanesi';
  static const String appSubtitle = 'Yemekhane Menü Sistemi';

  // ══════════════════════════════════════════════════════════════════════
  // ⭐ TURKCELL HBYS — TEK ANAHTAR
  // ══════════════════════════════════════════════════════════════════════

  /// `true`  → yerel mock sunucu (Turkcell dokümanı ile birebir).
  /// `false` → GERÇEK Turkcell HBYS. Canlıya çıkarken bunu `false` yapın.
  static const bool useMockHbys = true;

  /// Mock sunucunun adresi (geliştirme).
  ///  • Android emülatör → `http://10.0.2.2:5080`
  ///  • Gerçek cihaz (aynı WiFi) → `http://192.168.1.106:5080`
  static const String mockBaseUrl = 'http://10.0.2.2:5080';

  // Gerçek Turkcell HBYS host'ları (doküman v1.0 — CANLI).
  static const String hbysAuthBaseUrl =
      'https://api-legacy.app.external.eskisehir.yerel';
  static const String hbysMenuBaseUrl =
      'https://api-thirdparty.app.external.eskisehir.yerel';
  static const String hbysPersonnelBaseUrl =
      'https://api-quality.app.external.eskisehir.yerel';

  /// Aktif host'lar — [useMockHbys] anahtarına göre otomatik seçilir.
  static String get authBaseUrl => useMockHbys ? mockBaseUrl : hbysAuthBaseUrl;
  static String get menuBaseUrl => useMockHbys ? mockBaseUrl : hbysMenuBaseUrl;
  static String get personnelBaseUrl =>
      useMockHbys ? mockBaseUrl : hbysPersonnelBaseUrl;

  /// HBYS kimlik bilgileri — Turkcell teknik personelinden alınır (doküman §1).
  static const String hbysUsername = 'KAPARI';
  static const String hbysPassword = 'Eskisehir26.';
  static const int hbysOrganizationId = 106;

  /// HBYS istekleri için zaman aşımı.
  static const Duration apiTimeout = Duration(seconds: 15);

  // ══════════════════════════════════════════════════════════════════════
  // SMS / OTP — KENDİ BACKEND'İMİZ
  // ══════════════════════════════════════════════════════════════════════
  // ⚠️ Turkcell HBYS dokümanında SMS/OTP servisi YOKTUR. Bu yüzden doğrulama
  // kodu üretimi/gönderimi (3G Bilişim) yalnızca bu uçlar için kendi
  // backend'imizde durur. Menü ve personel kartı DOĞRUDAN Turkcell'dendir.

  /// Canlıda OTP backend'imizin (hastane intranet'i) adresi.
  static const String otpProdBaseUrl = 'https://api.hastane.yerel';

  /// Aktif OTP backend adresi — mock modda yerel sunucu.
  static String get otpBaseUrl => useMockHbys ? mockBaseUrl : otpProdBaseUrl;

  // ══════════════════════════════════════════════════════════════════════
  // ÖNBELLEK (sliding expiration)
  // ══════════════════════════════════════════════════════════════════════

  /// Her erişimde süre sıfırlanır; bu süre boyunca dokunulmayan kayıt düşer.
  /// Amaç: her açılışta HBYS'ye istek atmamak.
  /// Not: önbellek yalnızca BELLEKTEDİR (diske yazılmaz) — uygulama kapanınca
  /// sıfırlanır, böylece ağ dışında veri gösterilmez (bkz. AGENTS.md §4.0).
  static const Duration cacheSlidingExpiration = Duration(minutes: 10);

  // ══════════════════════════════════════════════════════════════════════
  // ⭐ WiFi ERİŞİM KISITI — "yalnızca hastane ağında çalış"
  // ══════════════════════════════════════════════════════════════════════

  /// İzinli WiFi ağ adları. ESKH, HBYS ile network bağlantısı olan SSID'dir.
  static const List<String> allowedSsids = <String>['ESKH'];

  /// SSID kontrolü zorunlu mu? (Android'de konum izni + konum servisi gerekir.)
  static const bool enforceSsid = false;

  /// İzinli erişim noktalarının (AP) MAC/BSSID **ilk 6 hanesi** (OUI).
  /// Cihaz değişiminde tekrar MAC tanımlama derdi olmasın diye önek eşleşmesi.
  /// Boş bırakılırsa BSSID kontrolü atlanır.
  static const List<String> allowedBssidPrefixes = <String>[
    '04caed',
    '18e91d',
    '48706f',
    '74342b',
    'ec819c',
  ];

  /// BSSID (AP MAC) kontrolü zorunlu mu? SSID taklit edilebilir; BSSID öneki
  /// gerçek hastane AP'lerinde olduğumuzun çok daha güçlü kanıtıdır.
  static const bool enforceBssid = true;

  /// Engelleme ekranında kullanıcıya gösterilecek ağ adı.
  static String get displayNetworkName =>
      allowedSsids.isNotEmpty ? allowedSsids.first : hospitalName;

  // === INTRANET ERİŞİLEBİLİRLİK KONTROLÜ (opsiyonel ek katman) ===

  /// Yalnızca hastane LAN'ından erişilebilen bir iç host.
  static const String intranetHealthUrl = 'http://10.0.0.1/health';

  static const bool enableReachabilityCheck = false;

  static const Duration reachabilityTimeout = Duration(seconds: 3);

  // ══════════════════════════════════════════════════════════════════════
  // YEMEKHANE BİLGİLERİ (Bilgi sayfası)
  // ══════════════════════════════════════════════════════════════════════
  // Not: Turkcell HBYS dokümanında hastane/yemekhane bilgisi ucu YOKTUR ve
  // yönetici paneli de kaldırılmıştır → bu değerler yalnızca buradan gelir.

  static const String workingHours = 'Pzt-Cum: 11:30 - 13:30 | 17:30 - 19:00';
  static const String location = 'B Blok, Zemin Kat, Yemekhane Salonu';
  static const String contact = 'Dahili: 4500 | Mutfak Şefi: 4501';
  static const String cafeteriaDescription =
      'Yemekhanemiz hafta içi her gün personelimize hijyenik ve dengeli '
      'beslenme imkânı sunar. Menüler diyetisyen kontrolünde hazırlanmaktadır.';
}
