/// ─────────────────────────────────────────────────────────────────────────
/// UYGULAMA YAPILANDIRMASI — TEK MERKEZ
/// ─────────────────────────────────────────────────────────────────────────
///
/// Bu uygulama BAŞKA BİR HASTANEYE kurulurken SADECE bu dosya düzenlenir.
/// Hastane adı, logosu, WiFi ağ adları ve intranet adresleri buradadır.
///
/// ⚠️  En kritik kısım [allowedSsids] ve [intranetHealthUrl]: uygulamanın
///     "yalnızca hastane WiFi'ında çalışma" kuralı bu değerlere bakar.
sealed class AppConfig {
  // === KURUM BİLGİLERİ ===
  static const String hospitalName = 'Eskişehir Şehir Hastanesi';
  static const String appSubtitle = 'Yemekhane Menü Sistemi';

  // === WiFi ERİŞİM KISITI ===
  static const List<String> allowedSsids = <String>[
    'ESH-Personel',
    'EskisehirSehirHastanesi',
  ];

  /// SSID kontrolü zorunlu olsun mu? (Android'de konum izni + konum servisi
  /// gerektirir; iOS'ta ücretli geliştirici hesabı gerekir.) false yapılırsa
  /// yalnızca [enableReachabilityCheck] / WiFi bağlantı tipi baz alınır.
  static const bool enforceSsid = false;

  /// Engelleme ekranında kullanıcıya gösterilecek ağ adı.
  static String get displayNetworkName =>
      allowedSsids.isNotEmpty ? allowedSsids.first : hospitalName;

  /// Opsiyonel ucuz ön-filtre: cihaz IP'sinin başlaması beklenen önek
  /// (ör. '10.20.'). null ise atlanır. Tek başına güvenilmez.
  static const String? expectedSubnetPrefix = null;

  // === INTRANET ERİŞİLEBİLİRLİK KONTROLÜ (ikinci katman / opsiyonel) ===

  /// Yalnızca hastane LAN'ından erişilebilen bir iç sunucu/health endpoint.
  /// Kısa timeout ile istek atılır; cevap dönerse cihaz gerçekten ağdadır.
  /// SSID sahteciliğine karşı en güçlü kanıt budur.
  static const String intranetHealthUrl = 'http://10.0.0.1/health';

  /// Intranet erişilebilirlik kontrolü aktif mi?
  static const bool enableReachabilityCheck = false;

  static const Duration reachabilityTimeout = Duration(seconds: 3);

  // === KENDİ REST API'MİZ (HBYS'ye bağlanan kendi backend'imiz) ===

  /// Uygulamanın bağlanacağı **KENDİ** REST API'mizin (Ozi HBYS API) taban adresi.
  ///
  /// ⚠️ Bu, Turkcell HBYS'nin adresi DEĞİLDİR. Bizim backend'imiz HBYS'ye
  /// bağlanır; uygulama yalnızca bu API'yi tanır (bkz. AGENTS.md §15).
  /// Hastane intranet'inde servis edilmelidir (§4 — veri ağ dışından alınamaz).
  ///
  /// Ortama göre değer:
  ///  • Android emülatör → `http://10.0.2.2:5080` (host makineye köprü)
  ///  • Gerçek cihaz (aynı WiFi) → `http://192.168.1.106:5080` (geliştirme PC IP'si)
  ///  • Canlı (hastane intranet) → `https://api.hastane.yerel`
  static const String apiBaseUrl = 'http://10.0.2.2:5080';

  /// `true` → menü/duyuru/hastane-bilgisi verisi gerçek API'den çekilir.
  /// `false` → dummy veri kullanılır (backend hazır değilken).
  /// Demo (kullanıcı adı/şifre) oturumda her hâlükârda dummy kullanılır.
  static const bool useRemoteApi = true;

  /// API istekleri için zaman aşımı.
  static const Duration apiTimeout = Duration(seconds: 10);

  // === YEMEKHANE BİLGİLERİ (Bilgi sayfası) ===
  static const String workingHours = 'Pzt-Cum: 11:30 - 13:30 | 17:30 - 19:00';
  static const String location = 'B Blok, Zemin Kat, Yemekhane Salonu';
  static const String contact = 'Dahili: 4500 | Mutfak Şefi: 4501';
}
