# Hastane Menü — Personel Yemekhane Menü Uygulaması

> Bu dosya, **hastane_menu** projesinde çalışan tüm yapay zeka agentları ve
> geliştiriciler için tek kaynaktır (single source of truth). Projeye yeni
> katılan her agent/geliştirici önce bunu okumalıdır.
>
> Mimari, kardeş proje **`alal_mobile`**'ın konvansiyonlarını (custom
> `StateManager`, `sealed class` sabitler, `core/` katmanı) takip eder; ancak
> uygulama çok küçük olduğu için **feature-first DEĞİL**, sade bir
> **`pages/` + `components/`** yapısı kullanılır.

---

## 1. Proje Vizyonu ve Genel Bakış

**Uygulama Adı:** Hastane Menü
**Platform:** Flutter (öncelik Android, iOS uyumlu)
**Dil:** Dart SDK ^3.11.4 — Arayüz dili **yalnızca Türkçe** (l10n yok)

### Ne Yapıyor?

Bir hastanenin **personel yemekhanesinin** günlük / haftalık / aylık menüsünü ve
duyurularını gösterir. Kalori bilgisi, kategori bazlı yemek listesi, takvim
görünümü içerir.

### ⭐ Kritik Kural — Yalnızca Hastane WiFi'ında Çalışır

> Uygulama **SADECE hastanenin WiFi ağına bağlıyken** içerik gösterir. Cihaz
> mobil veride veya farklı bir ağdaysa tam ekran bir **engelleme ekranı**
> çıkar. Bunun nasıl çalıştığı **§4'te** detaylıca anlatılmıştır — bu, projenin
> en ayırt edici özelliğidir ve değiştirilmeden önce §4 mutlaka okunmalıdır.

### Mevcut Durum

| Alan | Durum |
| ---- | ----- |
| Ağ kapısı (WiFi gate) | ✅ Çalışır — `WifiGuard` + `NetworkGate` + engelleme ekranı |
| Ana Sayfa | ✅ Bugünün menüsü + duyuru önizlemesi (dummy data) |
| Menü (Haftalık) | ✅ Hafta seçici + açılır gün kartları (öğün bölümleri) |
| Menü (Aylık) | ✅ Takvim ızgarası + seçili gün menüsü |
| Duyurular | ✅ Liste (dummy data) |
| Bilgi | ✅ Yemekhane bilgileri (config'ten) |
| Oturum kapısı (Auth gate) | ✅ Giriş yapmadan içeriğe erişilemez — `AuthGate` + tam ekran `LoginPage` |
| Giriş — Telefon (2FA) | ✅ Telefon → 6 haneli kod → oturum — bkz. §14 (dummy `AuthService`) |
| Giriş — Kullanıcı adı/şifre | ✅ Demo girişi `test` / `12345` → `isDemo` oturum, ful dummy data — §14 |
| Personel QR | ✅ Oturum açıkken alt-nav orta butonundan QR kart (`LoginSheet`) |
| Menü veri katmanı | ✅ `MenuRepository` + `MenuService` (cache) — dummy aktif, remote hazır — §7, §15 |
| Kendi REST API'miz (HBYS) | 🟡 İskelet hazır (`RemoteMenuRepository` + `ApiClient`); `AppConfig.useRemoteApi=false` — §15 |
| Duyuru/personel API | ⛔ Henüz remote yok — duyuru dummy, personel kartı modeli hazır (§15) |

---

## 2. Teknoloji Stack

### Core

| Teknoloji | Paket / Sürüm | Açıklama |
| --------- | ------------- | -------- |
| Framework | Flutter / Dart SDK ^3.11.4 | Cross-platform |
| State | Custom `StateManager` | `lib/core/state/state_manager.dart` — `$get` / `$state` / `SM` |
| DI | `setupServiceLocator()` | `lib/app/service_locator.dart` |
| QR | `qr_flutter` ^4.1.0 | Personel QR kodu render (§14) |

### Ağ Kapısı (uygulamanın çekirdeği — §4)

| Paket | Sürüm | Ne için |
| ----- | ----- | ------- |
| `connectivity_plus` | ^7.1.1 | Bağlantı tipi (wifi/mobil/yok) + `onConnectivityChanged` stream |
| `network_info_plus` | ^8.1.0 | WiFi SSID / BSSID / IP okuma |
| `permission_handler` | ^12.0.3 | Runtime izinler (NEARBY_WIFI_DEVICES / location) |
| `device_info_plus` | ^13.1.0 | Android SDK int (izin dallanması) |
| `app_settings` | ^7.0.0 | OS WiFi / konum ayarlarına deep-link |

> **NOT:** 3. parti state kütüphanesi (BLoC, Riverpod, Provider) **kullanılmaz**.
> Intranet reachability probe'u ekstra paket olmadan `dart:io` `HttpClient` ile
> yapılır.

---

## 3. Mimari — Basit `pages/` + `components/`

Feature-first **değildir**. Kabaca:

- **`pages/`** — her sekme/ekran bir sayfadır. Büyük sayfalar (`menu_page`)
  kendi alt klasöründe (`pages/menu/`) parçalanabilir.
- **`components/`** — 2+ sayfada kullanılan paylaşılan widget'lar.
- **`core/`** — feature-agnostik altyapı (sabitler, tema, state, ağ, util).
- **`models/`** — saf veri sınıfları + enum'lar.
- **`data/`** — (şimdilik) dummy veri kaynakları; ileride intranet API.
- **`app/`** — kök widget, tema, servis kaydı.

### Bağımlılık yönü

```
pages → components → core/models/data
        pages → core/models/data
```

`core/` hiçbir `pages/` veya `components/` dosyasına bağımlı olmamalıdır.

---

## 4. ⭐ Ağ Kapısı — "Yalnızca Hastane WiFi'ında Çalış"

> **EN ÖNEMLİ BÖLÜM.** Bu mantığı değiştirecek her agent burayı baştan sona
> okumalıdır.

### 4.0 Önce Bunu Anla: SSID bir güvenlik kontrolü DEĞİLDİR

SSID (WiFi ağ adı) taklit edilebilir (telefon hotspot'u, ucuz router). Bu yüzden:

> **Asıl güvenlik sınırı, menü verisinin yalnızca hastane intranet'inden
> erişilebilen bir API'den servis edilmesidir.** Uygulamaya offline/gömülü menü
> KONULMAZ. Ağ dışındayken veri zaten yüklenemez. Asıl kilit budur.

SSID/reachability kontrolünün tek görevi: kullanıcıya 30 sn timeout beklemek
yerine **anında dostça bir engelleme ekranı** göstermek (UX hızlandırıcı).

**Öncelik:** (1) Intranet-only API = gerçek kapı. (2) SSID = UX. (3) Gerisi cila.

### 4.1 Katmanlı Kapı (Layered Gate) Mantığı

`lib/core/network/wifi_guard.dart` → `WifiGuard.evaluate()`:

```
İZİN VER (onAllowedWifi) ⇔
    connectionType == wifi               // ucuz, anlık; mobil/yok'u hemen reddet
    AND (
          SSID ∈ AppConfig.allowedSsids  // hızlı yol (Android dostu)
          OR intranet host erişilebilir  // otoritatif (opsiyonel, default kapalı)
        )
```

`WifiGuard.status` bir `ReactiveState<WifiGuardStatus>`'tür; `NetworkGate`
widget'ı bunu dinler. `connectivity` değiştikçe kapı otomatik yeniden çalışır.

### 4.2 `WifiGuardStatus` durumları

| Durum | Anlamı | UI |
| ----- | ------ | -- |
| `checking` | İlk/sürən değerlendirme | Spinner |
| `onAllowedWifi` | İzinli ağdayız | **Uygulama içeriği** render edilir |
| `notWifi` | Mobil veri / bağlantı yok | Engelleme + "Wi-Fi ayarlarını aç" |
| `wrongWifi` | WiFi var ama izinli değil | Engelleme |
| `permissionDenied` | SSID izni reddedildi (Android) | Engelleme + "İzin Ver" |
| `locationOff` | Konum servisleri kapalı (Android) | Engelleme + "Konum servislerini aç" |

### 4.3 İlgili Dosyalar

| Dosya | Sorumluluk |
| ----- | ---------- |
| `lib/core/constants/app_config.dart` | **TEK CONFIG** — `allowedSsids`, `intranetHealthUrl`, bayraklar |
| `lib/core/network/wifi_guard.dart` | Kapı servisi + `WifiGuardStatus` enum |
| `lib/components/network_gate.dart` | Uygulamayı saran widget — sadece `onAllowedWifi`'da `child` |
| `lib/components/wifi_blocked_screen.dart` | Tam ekran engelleme ekranı (Türkçe) |
| `lib/app/service_locator.dart` | `WifiGuard` singleton kaydı |
| `lib/app/app.dart` | `NetworkGate(child: AuthGate(child: ShellPage()))` ile sarma |

### 4.4 Android Gereksinimleri

`android/app/src/main/AndroidManifest.xml` (kuruldu) izinleri içerir:
`ACCESS_WIFI_STATE`, `ACCESS_NETWORK_STATE`, `ACCESS_FINE_LOCATION`
(`maxSdkVersion=32`), `NEARBY_WIFI_DEVICES` (`neverForLocation`), `INTERNET`.

> ⚠️ **KRİTİK:** SSID okumak için cihazın **Konum Servisleri AÇIK** olmalıdır
> (izin vermek tek başına yetmez). Kapalıysa SSID `null` / `<unknown ssid>`
> döner → `locationOff` durumu. "getWifiName null dönüyor" sorununun #1 sebebi
> budur.

### 4.5 iOS Gereksinimleri

- `ios/Runner/Info.plist` → `NSLocationWhenInUseUsageDescription` +
  `NSLocalNetworkUsageDescription` (kuruldu).
- `ios/Runner/Runner.entitlements` → `com.apple.developer.networking.wifi-info`
  (oluşturuldu). **Xcode'da bağlanması gerekir:** Runner target → Signing &
  Capabilities → **+ Capability → "Access WiFi Information"**.
- ⚠️ Bu entitlement **ücretli Apple Developer hesabı** gerektirir. Yoksa SSID
  iOS'ta **daima `null`** döner; uygulama nazikçe reachability / bağlantı-tipi
  kontrolüne düşer (`WifiGuard` bunu zaten ele alır).
- Simulator'da SSID asla çalışmaz — gerçek cihazda test edin.

### 4.6 Yapılandırma (deploy başına tek dosya)

Farklı bir hastaneye kurarken **yalnızca** `lib/core/constants/app_config.dart`
düzenlenir:

```dart
static const List<String> allowedSsids = ['ESH-Personel', '...'];
static const bool   enforceSsid = true;                 // SSID kontrolü açık mı
static const String intranetHealthUrl = 'http://10.0.0.1/health';
static const bool   enableReachabilityCheck = false;    // intranet probe açık mı
```

- `allowedSsids` bir **liste**dir (personel + misafir ağı vb.). Karşılaştırma
  trim + lowercase + tırnak-soyma ile normalize edilir.
- iOS'u ciddi destekliyorsanız `enableReachabilityCheck = true` yapın ve
  `intranetHealthUrl`'i gerçek bir intranet-only endpoint'e ayarlayın.

### 4.7 Edge Case'ler

| Senaryo | Davranış |
| ------- | -------- |
| Mobil veri | `notWifi` → "mobil veri kullanıyorsunuz" |
| Uçak modu | `notWifi` → ağ çağrısı yapılmaz |
| Konum izni reddedildi (Android) | `permissionDenied` — **hard-block yok**, "İzin Ver" |
| Konum servisi kapalı (Android) | `locationOff` — "Konum servislerini aç" |
| iOS entitlement yok / Simulator | SSID `null` → reachability / bağlantı-tipine düşer |
| Android 14 transient null | 400ms debounce + connectivity re-check ile çözülür |

### 4.8 Sonraki Sertleştirme (P1/P2 — henüz yapılmadı)

- Intranet reachability probe'u varsayılan aç (iOS için otoritatif kapı).
- TLS certificate pinning + kısa ömürlü token / mTLS.
- `/health` cevabında nonce/header doğrulayarak sahte 200'ü ele.

---

## 5. Klasör Yapısı (Gerçek Mevcut Durum)

```
lib/
├── main.dart                          # Entry: ensureInitialized + setupServiceLocator + runApp
├── app/
│   ├── app.dart                       # Kök: MaterialApp + NetworkGate(child: ShellPage())
│   ├── app_theme.dart                 # HospitalTheme.light() — kırmızı/lacivert tema
│   └── service_locator.dart           # WifiGuard kaydı
│
├── core/
│   ├── constants/
│   │   ├── app_config.dart            # ⭐ TEK CONFIG — hastane + WiFi kapısı ayarları
│   │   ├── app_colors.dart            # Renk paleti (mockup birebir)
│   │   ├── app_spacing.dart           # Boşluk / radius / gölge sabitleri
│   │   └── app_typography.dart        # Metin stilleri
│   ├── network/
│   │   ├── wifi_guard.dart            # ⭐ Ağ kapısı servisi + WifiGuardStatus
│   │   └── api_client.dart            # ⭐ Kendi REST API'mize JSON istemcisi (dart:io) — §15
│   ├── state/
│   │   ├── state_manager.dart         # SM, ReactiveState, $get/$state/$set
│   │   └── session_state.dart         # Giriş yapan personel oturumu (reaktif)
│   └── utils/
│       ├── date_utils.dart            # Türkçe tarih formatlama (intl'siz)
│       └── turkish_text.dart          # Türkçe büyük/küçük + başlık (ALL CAPS → Başlık)
│
├── models/
│   ├── menu_models.dart               # MealType, MenuDish, Meal, DailyMenu (HBYS yapısı — §15)
│   ├── announcement.dart              # AnnouncementType, Announcement
│   └── staff_session.dart             # StaffSession (personnelId, cardNo, isDemo, ...)
│
├── data/
│   ├── dto/
│   │   └── hbys_menu_dto.dart         # ⭐ HBYS ham JSON → DailyMenu (kcal/tarih/başlık parse)
│   ├── menu_repository.dart           # ⭐ MenuRepository + Dummy/Remote impl — §15
│   ├── menu_service.dart              # ⭐ Menü tek giriş noktası — ay cache + kaynak seçimi
│   ├── menu_data.dart                 # DummyMenuData — örnek aylık menü rotasyonu
│   ├── announcement_data.dart         # Dummy duyurular
│   └── auth_service.dart              # 2FA + demo giriş servisi — ⚠️ DUMMY (§14)
│
├── components/
│   ├── network_gate.dart              # ⭐ Uygulamayı saran ağ kapısı widget'ı
│   ├── auth_gate.dart                 # ⭐ Oturum kapısı — giriş yoksa LoginPage
│   ├── wifi_blocked_screen.dart       # ⭐ Tam ekran engelleme ekranı
│   ├── app_header.dart                # Kırmızı degrade üst başlık
│   ├── bottom_nav_bar.dart            # Alt navigasyon (4 sekme + taşan orta QR butonu)
│   ├── login_sheet.dart               # Oturum sonrası QR kart sheet'i (§14)
│   ├── otp_input.dart                 # 6 haneli kod giriş alanı
│   ├── staff_qr_view.dart             # Personel QR kartı (qr_flutter)
│   ├── section_header.dart            # Bölüm başlığı + "tümü" linki
│   ├── empty_state.dart               # Boş durum (emoji + başlık + açıklama)
│   ├── meal_section.dart              # ⭐ Bir öğün bölümü (başlık + yemek satırları)
│   ├── day_menu_card.dart             # ⭐ Bir günün tüm öğünleri (home + aylık seçili gün)
│   ├── async_status.dart             # Menü yükleniyor / hata kartları
│   ├── day_card.dart                  # Açılır gün kartı (haftalık — öğün bölümleri)
│   ├── announcement_card.dart         # Duyuru kartı
│   └── round_nav_button.dart          # Takvim/hafta ok butonu
│
└── pages/
    ├── login_page.dart                # ⭐ Tam ekran giriş kapısı (telefon + kullanıcı adı)
    ├── shell_page.dart                # Bottom-nav iskeleti (IndexedStack)
    ├── home_page.dart                 # Ana sayfa
    ├── announcements_page.dart        # Tüm duyurular
    ├── info_page.dart                 # Yemekhane bilgileri
    ├── menu_page.dart                 # Haftalık/Aylık sekme kabı
    └── menu/
        ├── weekly_view.dart           # Haftalık görünüm
        └── monthly_view.dart          # Aylık takvim görünümü
```

---

## 6. Tema ve Tasarım Sistemi

### Renk Paleti (Kırmızı + Lacivert / T.C. Sağlık Bakanlığı)

`lib/core/constants/app_colors.dart` — `sealed class AppColors`:

```dart
red       = #C8102E   redLight = #E8253F   redDark  = #A00D24
blue      = #1A5CAD   blueLight= #2E7BD6   blueDark = #134A8A
background= #F2F4F7   card     = #FFFFFF
text      = #1E293B   textLight= #64748B   textMuted= #94A3B8
border    = #E2E8F0
// + semantic (success/warning/error/info) + kategori ikon arka planları
// + AppColors.redGradient / redGradientLight
```

### Diğer

- **Spacing/Radius/Shadow:** `AppSpacing` (`gapV16`, `paddingAllBase`,
  `borderRadiusLg`, `shadow`, `shadowLg`).
- **Tipografi:** `AppTypography` (`headingLarge`, `bodyMedium`, `label`...).
- **Tema:** `HospitalTheme.light()` (Material 3, sadece light mode).
- **Font:** Özel font paketlenmedi (sistem fontu). Mockup'taki Inter istenirse
  `pubspec.yaml`'a eklenip `AppTypography`'de `fontFamily` set edilir.

> **Yasaklar:** Hardcoded renk → `AppColors`. Hardcoded boşluk → `AppSpacing`.
> Magic number → `core/constants/`.

---

## 7. Veri Katmanı

Menü verisi **repository deseni** üzerinden akar; UI kaynağı bilmez:

```
UI (FutureBuilder)
   └── MenuService            # tek giriş noktası — ay bazında cache + kaynak seçimi
         ├── DummyMenuRepository   # yerel örnek veri (DummyMenuData)
         └── RemoteMenuRepository  # kendi REST API'miz → ApiClient (dart:io) → HbysMenuDto
```

- **`MenuService`** (`$get<MenuService>()`) ekranların kullandığı tek API'dir:
  `month(yil, ay)`, `day(tarih)`, `week(pazartesi)`. Ayları **cache**'ler.
- **Kaynak seçimi** otomatiktir: oturum `isDemo` ise **veya**
  `AppConfig.useRemoteApi == false` ise → `DummyMenuRepository`; aksi hâlde
  `RemoteMenuRepository` (bizim API). Demo (`test`/`12345`) hep dummy görür.
- **Modeller** (`lib/models/menu_models.dart`) HBYS yapısına göredir:
  `DailyMenu → 3 × Meal (kahvaltı/öğle/akşam) → ≤4 × MenuDish` (§15).
- Duyurular hâlâ dummy (`AnnouncementData`); aynı desenle remote'a taşınabilir.

> Veri **yalnızca** intranet'teki kendi API'mizden gelir; offline/gömülü menü
> KONULMAZ (§4.0). Gerçek API'ye geçiş için tek değişiklik:
> `AppConfig.useRemoteApi = true` + `apiBaseUrl`'i ayarlamak (§15).

---

## 8. State Management

`lib/core/state/state_manager.dart` — `alal_mobile`'ın sade uyarlaması:

```dart
SM.register<T>(instance)      // singleton kayıt
SM.registerLazy<T>(factory)   // lazy
$get<T>()                     // servisi al
$state<T>([initial])          // tip bazlı ReactiveState
$set<T>(value)                // state değeri yaz
state.builder((v) => Widget)  // StreamBuilder kısayolu
```

`WifiGuard` bir singleton servistir ve `status` adlı bir `ReactiveState` yayar;
`NetworkGate` `status.builder(...)` ile dinler. Yeni global servisleri
`service_locator.dart`'a ekleyin. Sayfa-lokal durum için `StatefulWidget`
yeterlidir (örn. `MenuPage`, `WeeklyView`).

---

## 9. Kodlama Standartları

| Tür | Stil | Örnek |
| --- | ---- | ----- |
| Dosya/Klasör | snake_case | `menu_page.dart`, `pages/menu/` |
| Sınıf | PascalCase | `WifiGuard` |
| Değişken | camelCase | `todayMenu` |
| Enum | PascalCase.camelCase | `WifiGuardStatus.onAllowedWifi` |

- Import sırası: `dart:` → `package:` → relative. Proje importları
  `package:hastane_menu/...` (absolute) tercih edilir.
- 1 dosya = 1 public widget/sınıf; ~300 satırı geçerse parçala.
- 2+ sayfada kullanılan widget → `components/`. Tek sayfaya özelse sayfanın
  yanında (`pages/menu/`) veya aynı dosyada private widget.
- **Hardcoded renk/spacing/string-as-config yasak** (UI metni Türkçe sabit
  olabilir; konfigürasyon değerleri `AppConfig`'te).
- `print()` yerine gerçek loglama; production'da sessiz.
- `flutter analyze` **sıfır uyarı** ile geçmeli.

---

## 10. Uygulama Kimliği

| Alan | Değer |
| ---- | ----- |
| Android namespace / applicationId | `com.ozi.hastane_menu` |
| iOS bundle identifier | `com.ozi.hastaneMenu` |
| Görünen ad (Android `android:label`) | **Hastane Menü** |
| Görünen ad (iOS `CFBundleDisplayName`) | **Hastane Menü** |

> Başka bir hastane/marka için: `android/app/build.gradle.kts` (namespace +
> applicationId), `android/.../kotlin/com/ozi/.../MainActivity.kt` (package),
> `ios/Runner.xcodeproj/project.pbxproj` (`PRODUCT_BUNDLE_IDENTIFIER`),
> manifest `android:label` ve Info.plist `CFBundleDisplayName` güncellenir.

---

## 11. Build & Run Komutları

```bash
flutter pub get               # bağımlılıklar
flutter analyze               # statik analiz (sıfır uyarı beklenir)
flutter test                  # widget testleri
flutter run                   # geliştirme
flutter build apk --release   # Android release
flutter build ios --release   # iOS release (entitlement için §4.5)
```

> **WiFi kapısını test ederken:** Emülatör/simülatör SSID okuyamaz. Gerçek
> cihazda, konum servisleri açıkken test edin. Hızlı denemek için geçici olarak
> `AppConfig.allowedSsids`'e kendi test ağınızı ekleyin veya `enforceSsid`'i
> `false` yapın (bağlantı-tipi-only kapı).

---

## 12. Yeni Sayfa / Komponent Ekleme

**Yeni sayfa:**
1. `lib/pages/yeni_page.dart` oluştur (`StatelessWidget`/`StatefulWidget`).
2. Bir sekmeyse `shell_page.dart`'taki `_tabs` + `IndexedStack`'e ekle.
3. Paylaşılan parçaları `components/`'tan kullan; sayfaya özel büyük parçaları
   `pages/yeni/` altına koy.

**Yeni komponent:** `lib/components/` altına ekle, `AppColors`/`AppSpacing`/
`AppTypography` kullan, mümkünse `const` constructor.

**Yeni global servis:** `service_locator.dart`'a `SM.register<T>(...)` ekle.

---

## 13. Bilinen Sınırlamalar / TODO

- [x] Menü veri katmanı repository/service deseni (HBYS yapısı) — §7, §15. ✅
- [ ] Backend `/menu/aylik` proxy'sini bağla + `useRemoteApi=true` (şu an dummy) — §15.
- [ ] Duyuru servisini de remote'a taşı (menüyle aynı desen).
- [ ] Intranet reachability probe'u varsayılan aktif et + sertleştir (§4.8).
- [ ] iOS entitlement'ı Xcode'da bağla (ücretli hesap gerekir).
- [ ] Giriş akışını gerçek SMS/OTP + personel kartı API'sine bağla (`cardNo` → QR) — §14, §15.
- [ ] Demo girişini (`test`/`12345`, `isDemo`) gerçek API gelince kaldır/sınırla (§14).
- [ ] Personel oturumunu güvenli depolamada kalıcı yap (şu an bellek içi).
- [ ] (Opsiyonel) Inter fontunu paketle, dark mode, push bildirim.

---

## 14. Oturum Kapısı + Giriş Akışı

> **Giriş yapmadan uygulamaya erişilemez.** Ağ kapısı (§4) geçildikten sonra
> `AuthGate` devreye girer: oturum yoksa tam ekran `LoginPage` gösterilir,
> oturum açılınca `ShellPage` render edilir.
> Sarma sırası: `NetworkGate → AuthGate → ShellPage`.

### 14.1 İki Giriş Yöntemi (`LoginPage`)

Giriş ekranında bir segmented seçici ile **iki yöntem** sunulur:

**A) Telefon (2FA SMS) — gerçek akış için tasarlanan yol**
1. Personel telefon numarasını girer → `AuthService.requestOtp(phone)`.
2. Telefona gelen **6 haneli** kodu girer → `AuthService.verifyOtp(phone, code)`.
3. Başarılıysa `SessionState`'e oturum yazılır → `AuthGate` uygulamayı açar.

**B) Kullanıcı adı + şifre — DEMO girişi**
- `AuthService.loginWithCredentials(username, password)` çağrılır.
- ⚠️ DUMMY: yalnızca **`test` / `12345`** kabul edilir.
- Başarılıysa `StaffSession.isDemo == true` olan bir oturum döner. Bu oturumda
  **gerçek API'ye gidilmez**; tüm içerik `lib/data/` dummy kaynaklarından gelir.
  Gerçek API entegrasyonunda demo akışını korumak için bu bayrağa bakılır.

### 14.2 Personel QR Kodu (oturum sonrası)

Oturum açıkken alt navigasyonun **ortasındaki buton** ("QR Kod") `LoginSheet`'i
**doğrudan QR adımında** açar: `personnelId` içeren QR kart gösterilir (yemekhane
girişinde okutulur). Sheet içindeki "Çıkış Yap" oturumu kapatır → `AuthGate`
otomatik olarak `LoginPage`'e döner.

### Durum Yönetimi
- `SessionState` (`lib/core/state/session_state.dart`) bir
  `ReactiveState<StaffSession?>` tutar. `AuthGate` ve `ShellPage` bunu
  `.builder()` ile dinler.
- Oturum şu an **bellek içidir** (uygulama kapanınca sıfırlanır → tekrar giriş).

### İlgili Dosyalar
| Dosya | Sorumluluk |
| ----- | ---------- |
| `lib/components/auth_gate.dart` | ⭐ Oturum kapısı — giriş yoksa `LoginPage` |
| `lib/pages/login_page.dart` | ⭐ Tam ekran giriş (telefon + kullanıcı adı/şifre) |
| `lib/components/login_sheet.dart` | Oturum sonrası QR kart sheet'i |
| `lib/components/otp_input.dart` | 6 haneli kod giriş alanı |
| `lib/components/staff_qr_view.dart` | QR kart (`qr_flutter` → `QrImageView`) |
| `lib/data/auth_service.dart` | `requestOtp` / `verifyOtp` / `loginWithCredentials` — ⚠️ DUMMY |
| `lib/core/state/session_state.dart` | Oturum reaktif state'i |
| `lib/models/staff_session.dart` | `StaffSession` (personnelId, ad, telefon, `isDemo`) |

### Gerçek API'ye Geçiş
1. `AuthService.requestOtp` → gerçek SMS/OTP servisini çağır.
2. `AuthService.verifyOtp` → doğrulama endpoint'i; `personnelId` ve personel
   bilgisi response'tan gelsin (sabit string DEĞİL).
3. `loginWithCredentials` → ya kaldır ya da yalnızca geliştirme için `isDemo`
   olarak tut; veri katmanı `isDemo` oturumda gerçek API'yi atlamalı.
4. Oturumu güvenli depolamaya yaz (kalıcılık).
5. Giriş/oturum da intranet'e bağlı olmalı — §4 kuralı gereği ağ dışında alınamaz.

---

## 15. ⭐ HBYS Menü Entegrasyonu (Kendi REST API'miz)

> Menü/personel verisi Turkcell **HBYS**'den gelir. Uygulama **doğrudan
> HBYS'ye bağlanmaz**; arada **kendi REST API'miz** (backend) durur. Backend
> HBYS'yi dinler, uygulama yalnızca bizim API'yi tanır.

```
Flutter App ──HTTPS──► Kendi REST API'miz (backend) ──► Turkcell HBYS
            (bizim sözleşme)                 (entegre-login + Bearer token)
```

### 15.1 Önemli Kural — Endpoint'ler BİZE Aittir

Entegrasyon dokümanındaki Turkcell yolları (`/auth/entegre-login`,
`/aylik-yemek-listesi/get-kayit-list`, `/personel/get-personel-karti-by-cep-tel`)
**uygulamada KULLANILMAZ**. Bunlar backend↔HBYS arasındadır. Uygulamanın
çağırdığı yollar bizim tasarımımızdır (`RemoteMenuRepository` içinde):

| Amaç | Bizim yol (uygulama → kendi API) | Kaynak (backend → HBYS) |
| ---- | -------------------------------- | ----------------------- |
| Aylık menü | `GET {apiBaseUrl}/menu/aylik?yil=&ay=` | `aylik-yemek-listesi` |
| Personel kartı | `GET {apiBaseUrl}/personel?cepTel=` (planlı) | `get-personel-karti-by-cep-tel` |

### 15.2 Yanıt Gövdesi — HBYS ile Birebir (Proxy)

Kendi API'miz, HBYS gövdesini **aynen** döner; uygulama bu alanları
`HbysMenuDto` ile parse eder. Aylık menü yanıtı: `{ "data": [ <gün kaydı> ] }`.

**HBYS alan → uygulama modeli eşlemesi** (`lib/data/dto/hbys_menu_dto.dart`):

| HBYS alanı | Model | Not |
| ---------- | ----- | --- |
| `tarih` `"31.01.2026 00:00:00"` | `DailyMenu.date` | `dd.MM.yyyy` parse edilir |
| `id`, `yil`, `ay` | `DailyMenu.id` (+ tarih yedeği) | |
| `kahvaltiY1..Y4Adi` | `Meal(kahvalti).dishes[].name` | ALL CAPS → Başlık (`TurkishText`) |
| `ogleY1..Y4Adi` | `Meal(ogle).dishes[].name` | |
| `aksamY1..Y4Adi` | `Meal(aksam).dishes[].name` | |
| `...Y1..Y4Id` | `MenuDish.id` | |
| ad içindeki `"(95 kcal)"` | `MenuDish.calories` | regex ile ad'dan ayıklanır |

> Boş slot (ad `null`/boş) atlanır. Öğünde hiç yemek yoksa o öğün boş kalır;
> günün hiç öğünü yoksa takvimde nokta çıkmaz, `DayMenuCard` "Menü Yok" gösterir.

### 15.3 Auth / Token

- HBYS Bearer token (~60 dk, `entegre-login`) **backend tarafında** alınıp
  yenilenir; uygulama bunu görmez. Uygulamanın kendi oturumu §14'tedir.
- Gerekirse `RemoteMenuRepository(tokenProvider: ...)` ile uygulama isteğine
  Bearer eklenebilir (örn. bizim API de token istiyorsa). `ApiClient` `token`
  parametresini `Authorization: Bearer` olarak gönderir.
- Hata gövdesi HBYS zarfıyla uyumludur:
  `{ httpStatus, exception: { errorCode, errorMessage } }` → `ApiException`.

### 15.4 Yapılandırma (`AppConfig`)

```dart
static const String apiBaseUrl  = 'https://api.hastane.yerel'; // KENDİ API'miz
static const bool   useRemoteApi = false;   // true → gerçek API; false → dummy
static const Duration apiTimeout = Duration(seconds: 10);
```

- `useRemoteApi=false` iken (varsayılan) tüm menü dummy gelir → backend
  olmadan geliştirme/sunum yapılır.
- Demo oturum (`isDemo`) `useRemoteApi`'den **bağımsız** olarak hep dummy görür.

### 15.5 Gerçek API'ye Geçiş (checklist)

1. Backend `/menu/aylik` yolunu HBYS `aylik-yemek-listesi`'ne proxy'le (gövde
   birebir geçebilir).
2. `AppConfig.apiBaseUrl`'i backend adresine, `useRemoteApi = true` yap.
3. Telefon girişinde personel kartını (`/personel?cepTel=`) çekip
   `StaffSession.cardNo`'ya yaz (QR değeri). `present=false` → erişim reddi.
4. Veri yalnızca intranet'ten gelmeli (§4.0); `apiBaseUrl` intranet host olmalı.

### İlgili Dosyalar
| Dosya | Sorumluluk |
| ----- | ---------- |
| `lib/core/network/api_client.dart` | JSON HTTP istemcisi (dart:io) + `ApiException` |
| `lib/data/menu_repository.dart` | `MenuRepository` + `Dummy`/`Remote` impl |
| `lib/data/menu_service.dart` | Cache + kaynak seçimi (dummy/remote) |
| `lib/data/dto/hbys_menu_dto.dart` | HBYS ham JSON → `DailyMenu` |
| `lib/core/utils/turkish_text.dart` | ALL CAPS → Türkçe başlık biçimi |
| `lib/core/constants/app_config.dart` | `apiBaseUrl` / `useRemoteApi` / `apiTimeout` |

---

> **Bu dosya projenin tek gerçek kaynağıdır.** Mimari karar, yeni desen veya
> WiFi-kapısı mantığı değiştiğinde burası güncellenmelidir.
