# Play Store Yayın Varlıkları — Kapari Hazır Yemek

## Ekran görüntüleri (`screenshots/`)

Play Console → Ana mağaza girişi → **Telefon ekran görüntüleri** bölümüne
yüklenir. 7 adet, sırayla:

| # | Dosya | Ekran |
| - | ----- | ----- |
| 1 | `01-ana-sayfa.png` | Ana sayfa — bugünün menüsü, öğün başına kalori |
| 2 | `02-hizli-erisim.png` | Ana sayfa alt kısmı — akşam öğünü + hızlı erişim |
| 3 | `03-menu-haftalik.png` | Menü takvimi — haftalık gün şeridi |
| 4 | `04-menu-gun-secimi.png` | Başka bir güne geçiş |
| 5 | `05-menu-aylik-takvim.png` | Aylık takvim görünümü |
| 6 | `06-personel-qr-karti.png` | Yemekhane girişinde okutulan personel QR kartı |
| 7 | `07-yemekhane-bilgileri.png` | Çalışma saatleri, konum, iletişim |

**Format:** 1080×1920 (tam 9:16), 24-bit PNG, alfa kanalı yok — Play Console'un
telefon ekran görüntüsü kurallarına uyar. Cihaz çıktısı 1080×2220 (18.5:9) olduğu
için içerik 9:16'ya sığacak şekilde ölçeklenip yanlara arka plan rengi
(`#F4F6FA`) eklendi; hiçbir içerik kırpılmadı.

`screenshots/ham/` — emülatörden çıkan işlenmemiş 1080×2220 kareler. Farklı bir
düzen istenirse buradan yeniden üretilir.

### Nasıl üretildi

Pixel 3a / Android 14 emülatöründe release derlemesi ile alındı (2026-08 lacivert
rebrand sonrası, 1080×2220). Emülatör
hastane ağında olmadığı için oturum **test girişiyle** açıldı; menü içeriği
`DemoMenuSource`'tan gelen örnek veridir (bkz. AGENTS.md §4.2.1). Ekranların
düzeni gerçek oturumla birebir aynıdır.

> Bilgi sayfası karesinde demo oturum kartı ("Test Kullanıcısı") görünüyordu;
> mağaza görseline girmemesi için o şerit `ffmpeg` ile çıkarılıp arka plan
> rengiyle dolduruldu.

## Eksik kalanlar (Play Console'da elle girilecek)

- **Uygulama simgesi 512×512** — Kapari ikon setindeki 1024 px sürümden
  küçültülür. APK/AAB içinde DEĞİLDİR.
- **Öne çıkan grafik 1024×500** — zorunlu.
- Kısa/uzun açıklama, gizlilik politikası URL'si, veri güvenliği formu.
- **Konum izni beyanı:** uygulama `ACCESS_FINE_LOCATION` istiyor (yalnızca bağlı
  Wi-Fi ağının adını doğrulamak için — bkz. AGENTS.md §4.4). Play Console'daki
  hassas izin formunda bu gerekçe yazılmalıdır.
