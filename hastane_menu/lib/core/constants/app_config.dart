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
  // MARKA BİLGİLERİ
  // ══════════════════════════════════════════════════════════════════════
  static const String brandName = 'Kapari Hazır Yemek';
  static const String appSubtitle = 'Yemekhane Menü Sistemi';

  // ══════════════════════════════════════════════════════════════════════
  // ⭐ TURKCELL HBYS — TEK ANAHTAR
  // ══════════════════════════════════════════════════════════════════════

  /// `true`  → yerel mock sunucu (Turkcell dokümanı ile birebir).
  /// `false` → GERÇEK Turkcell HBYS. Canlıya çıkarken bunu `false` yapın.
  static const bool useMockHbys = true;

  /// Mock sunucunun adresi (geliştirme).
  ///
  /// ⚠️ `10.0.2.2` YALNIZCA Android emülatöründe çalışır (host makineye köprü).
  ///    GERÇEK CİHAZDA geliştirme PC'sinin LAN IP'si yazılmalıdır; ayrıca:
  ///      • telefon ile PC aynı WiFi'da olmalı,
  ///      • API 0.0.0.0'a bind edilmeli (`--urls http://0.0.0.0:5080`),
  ///      • Windows Firewall'da 5080 inbound açık olmalı.
  ///
  /// ⚠️ PC'nin IP'si DHCP ile dağıtılıyor ve DEĞİŞEBİLİR (106 → 100 oldu).
  ///    Bağlantı kesilirse `ipconfig` ile IP'yi kontrol edin.
  ///
  ///  • Gerçek cihaz (aynı WiFi) → `http://192.168.1.100:5080`
  ///  • Android emülatör        → `http://10.0.2.2:5080`
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
  // SMS / OTP — 3G BİLİŞİM (uygulamadan doğrudan)
  // ══════════════════════════════════════════════════════════════════════
  // ⚠️ Turkcell HBYS dokümanında SMS/OTP servisi YOKTUR ve canlıda aracı bir
  // API'miz olmayacaktır → doğrulama kodu uygulamada üretilir ve SMS doğrudan
  // 3G Bilişim gateway'ine gönderilir.
  //
  // ⚠️ GÜVENLİK: Aşağıdaki kimlik bilgileri APK içine gömülüdür ve decompile
  //    ile okunabilir. Gerçek (ücretli) SMS hesabına geçerken bunu göz önünde
  //    bulundurun; mümkünse kısıtlı/kotalı bir alt hesap kullanın.

  /// false → SMS gönderilmez; kod yalnızca debug konsoluna yazılır.
  static const bool smsEnabled = true;

  static const String smsBaseUrl = 'https://gateway.3gbilisim.com';
  static const String smsUsername = '3g061896_otp';
  static const String smsPassword = 't6G7Yjp';
  static const String smsOriginator = 'KAPARIYEMEK';

  /// Gateway `compncode` (firma kodu) parametresi.
  static const String smsCompanyCode = '2';

  /// Doğrulama kodu geçerlilik süresi.
  static const Duration otpLifetime = Duration(minutes: 3);

  /// Aynı numaraya tekrar kod göndermeden önce beklenecek süre.
  static const Duration otpResendCooldown = Duration(seconds: 60);

  /// Bir kod için izin verilen hatalı deneme sayısı.
  static const int otpMaxAttempts = 5;

  // ══════════════════════════════════════════════════════════════════════
  // ÖNBELLEK (sliding expiration)
  // ══════════════════════════════════════════════════════════════════════

  /// Her erişimde süre sıfırlanır; bu süre boyunca dokunulmayan kayıt düşer.
  /// Amaç: her açılışta HBYS'ye istek atmamak.
  /// Not: önbellek yalnızca BELLEKTEDİR (diske yazılmaz) — uygulama kapanınca
  /// sıfırlanır, böylece ağ dışında veri gösterilmez (bkz. AGENTS.md §4.0).
  static const Duration cacheSlidingExpiration = Duration(minutes: 10);

  // ══════════════════════════════════════════════════════════════════════
  // DEMO / TEST GİRİŞİ (kullanıcı adı + şifre)
  // ══════════════════════════════════════════════════════════════════════
  // Play Store sürümünde de açık kalacaktır → tahmin edilebilir bir şifre
  // (eski: "12345") gerçek personel akışının yanında bir arka kapı olurdu.
  //
  // ⚠️ Değerler APK içine gömülüdür ve decompile ile okunabilir; bu yüzden
  //    demo oturumu YALNIZCA dummy data görür (bkz. StaffSession.isDemo) ve
  //    HBYS'ye hiçbir istek atmaz. Şifreyi build sırasında değiştirmek için:
  //    flutter build appbundle --dart-define=DEMO_PASSWORD=...

  /// Demo girişi tamamen kapatılabilir: --dart-define=DEMO_LOGIN_ENABLED=false
  static const bool demoLoginEnabled =
      bool.fromEnvironment('DEMO_LOGIN_ENABLED', defaultValue: true);

  static const String demoUsername =
      String.fromEnvironment('DEMO_USERNAME', defaultValue: 'test');

  static const String demoPassword =
      String.fromEnvironment('DEMO_PASSWORD', defaultValue: 'Kpr!Ymk-2026#7fQz');

  /// Demo oturumu ağ kapısını (WiFi kısıtı) atlar mı?
  ///
  /// Amaç: hastane ağı dışındayken de uygulamanın gezilebilmesi (test, demo,
  /// Play Store incelemesi). Güvenlik açığı DEĞİLDİR: demo oturumu HBYS'ye
  /// hiç bağlanmaz, yalnızca dummy içerik görür (bkz. AGENTS.md §4.0 — asıl
  /// kapı intranet-only API'dir, SSID yalnızca UX içindir).
  /// Kapatmak için: --dart-define=DEMO_BYPASSES_NETWORK_GATE=false
  static const bool demoBypassesNetworkGate =
      bool.fromEnvironment('DEMO_BYPASSES_NETWORK_GATE', defaultValue: true);

  // ══════════════════════════════════════════════════════════════════════
  // ⭐ WiFi ERİŞİM KISITI — "yalnızca hastane ağında çalış"
  // ══════════════════════════════════════════════════════════════════════

  /// İzinli WiFi ağ adları. ESKH, HBYS ile network bağlantısı olan SSID'dir.
  static const List<String> allowedSsids = <String>['ESKH', 'AndroidWifi'];

  /// SSID kontrolü zorunlu mu? (Android'de konum izni + konum servisi gerekir.)
  static const bool enforceSsid = true;

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
      allowedSsids.isNotEmpty ? allowedSsids.first : brandName;

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
