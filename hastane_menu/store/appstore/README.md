# App Store Yayın Varlıkları — Kapari Hazır Yemek

Bu klasördeki dosyalar App Store Connect'e **doğrudan** yüklenir. `ham/`
klasörü yalnızca yeniden üretim içindir; yüklenmez.

## Hangi dosya nereye

App Store Connect → uygulama → iOS sürümü (1.0.0) → **Product Page Information**

| Alan | Dosya(lar) | Ölçü |
| ---- | ---------- | ---- |
| Header (Header Asset) | `header-5244x2950.png` (yedek: `header-3840x1646.png`) — **yalnızca biri** | 5244×2950 |
| Header and Search Results → **Search Results** | `search-results-1920x1280.png` | 1920×1280 |
| Screenshots → **iPhone with Dynamic Island** | `iphone-dynamic-island-1-…` → `-5-…` (bu sırayla) | 1206×2622 |
| Screenshots → **iPhone Duo** | `iphone-duo-1-…` → `-5-…` (bu sırayla) | 2007×2853 |
| Screenshots → **iPad 13" Display** | `ipad-1-…` → `ipad-5-…` (bu sırayla) | 2064×2752 |

> ⚠️ Eski 6.9" ölçüsü (1290×2796) bu yuvalara yüklenmiyor ("dimension"
> hatası) — üretilmiyor. Ölçüler `tools/appstore-gorselleri.py` → `TARGETS`.
> "iPhone Duo"nun oranı (~1.42) tablete yakın olduğu için kareleri iPad ham
> görüntülerinden (uygulamanın geniş düzeni) üretilir.

> iPad kareleri yalnızca uygulama iPad'i destekliyorsa gerekir
> (`TARGETED_DEVICE_FAMILY = "1,2"` iken ZORUNLU). iPhone-only yapılırsa atlanır.

## Metinler

**Promotional Text** (≤170)

```
Bugünün menüsü, haftalık ve aylık yemek takvimi, kalori bilgisi ve personel QR yemek kartınız — hepsi tek uygulamada.
```

**Description** (≤4000)

```
Kapari Hazır Yemek, hizmet verdiğimiz hastane yemekhanesinin menüsünü personelin cebine taşır. Bugün ne çıkacağını, haftanın ve ayın menüsünü, her yemeğin kalori bilgisini tek ekranda görün; yemekhane girişinde QR yemek kartınızı okutun.

BUGÜNÜN MENÜSÜ
• Kahvaltı, öğle ve akşam öğünleri tek bakışta
• Her yemeğin ve her öğünün kalori bilgisi
• Günün toplam kalorisi

MENÜ TAKVİMİ
• Gün şeridinde kaydırarak günler arasında gezinin
• Aylık takvimden istediğiniz günü seçin
• Menüsü olan günler takvimde işaretlidir

PERSONEL QR YEMEK KARTI
• Yemekhane girişinde okutulan QR kodunuz her an yanınızda
• Kişisel bilgileriniz kart üzerinde yazı olarak gösterilmez

YEMEKHANE BİLGİLERİ
• Çalışma saatleri, konum ve iletişim bilgileri

YETKİLİ PERSONEL İÇİNDİR
Giriş, kayıtlı cep telefonunuza gönderilen tek kullanımlık doğrulama koduyla yapılır. Menü verileri yalnızca hastane ağından erişilebilen sistemden geldiği için uygulama, hastanenin Wi-Fi ağına bağlıyken çalışır. Bağlı olduğunuz ağı doğrulamak için konum izni istenir; konum bilginiz kaydedilmez ve hiçbir yere gönderilmez.
```

**Keywords** (≤100 — virgülden sonra boşluk YOK; 99 karakter)

```
yemekhane,menü,yemek listesi,personel,hastane,kalori,günlük menü,yemek kartı,qr,kahvaltı,öğle,akşam
```

**Version:** `1.0.0` — pubspec'teki `version: 1.0.0+N` ile AYNI olmalı; "1.0"
bırakılırsa Codemagic'in yüklediği 1.0.0 build'i bu sürümde seçilemez.

**Copyright:** `2026 Kapari Hazır Yemek`

**Support URL:** zorunlu — şirket sitesi / iletişim sayfası. **Marketing URL:** boş.

**Routing App Coverage File, App Clip, iMessage App, Game Center:** boş / kapalı.

**Build:** Codemagic yükledikten ~15-30 dk sonra buradan seçilir. Info.plist'te
`ITSAppUsesNonExemptEncryption = false` olduğu için şifreleme belgesi istenmez.

## App Review Information

- **Sign-in required:** ✔ — User name `test` · Password `AppConfig.demoPassword`
- **Contact Information:** Apple'ın ulaşabileceği gerçek kişi (ad, telefon, e-posta).
- **Notes** (inceleme ekibi İngilizce okur):

```
This app is the staff cafeteria menu for a hospital served by Kapari Hazır Yemek (catering). By design it only works on the hospital's internal Wi-Fi network: real staff sign in with a one-time SMS code tied to the hospital personnel system, which cannot be reached from outside the hospital.

To review the app from any network, please use the demo account. It shows sample menu data and never connects to hospital systems:
1. Launch the app. A screen will say you are not on the hospital network (or that location permission is needed).
2. Tap "Yönetici girişi" (Admin sign-in) at the bottom of that screen.
3. Username: test
   Password: (see Sign-In Information above)
4. You can then browse today's menu, the menu calendar, the staff QR card (center button of the tab bar) and the cafeteria info page. Sign out is on the "Bilgi" (Info) tab.

Location permission is requested only to read the name/BSSID of the connected Wi-Fi network to verify the hospital network. Location data is never stored or transmitted.
The app's interface is Turkish only.
```

## Nasıl üretildi

Android emülatöründe (Android 14, release derlemesi, test girişi) çözünürlük
birebir Apple ölçülerine ayarlanıp ekranlar alındı:

```bash
adb shell wm size 1290x2796 && adb shell wm density 480   # iPhone 6.9" (430pt @3x)
adb shell wm size 2064x2752 && adb shell wm density 320   # iPad 13"  (1032pt @2x)
adb shell wm size reset && adb shell wm density reset     # geri al
```

Ham kareler `ham/`'a konur, sonra:

```bash
python -I tools/appstore-gorselleri.py store/appstore
```

Script Android durum çubuğunu ve gezinme/görev çubuğunu **kırpar** (App Store
görselinde başka platformun arayüzü görünmemeli), ekranı başlıklı markalı
kareye yerleştirir ve header'ları üretir. Menü içeriği `DemoMenuSource`
örnek verisidir; düzen gerçek oturumla birebir aynıdır. Emoji'ler Android
çizimiyle görünür (iPhone'da Apple emojisi çıkar) — kabul edilebilir fark.
