# Saha kontrolü — ESKH ağındaki PC'de (AnyDesk) yapılacaklar

> **Neden gerekiyor:** Mağazadaki sürüm `useMockHbys = true` ile çıktı; tüm HBYS
> çağrıları `http://10.0.2.2:5080` adresine gitti. Bu adres yalnızca Android
> **emülatöründe** geliştirme PC'sini gösterir; gerçek telefonda kimseye ait
> değildir → istek asılı kalır → 15 sn sonra "HBYS isteği zaman aşımına uğradı".
>
> Kod tarafı düzeltildi (artık varsayılan canlı HBYS). Ama yeni sürümü
> yayınlamadan önce **canlı host'ların o ağdan gerçekten erişilebildiğini**
> doğrulamamız gerekiyor — yoksa aynı hatayı ikinci kez yayınlarız.

---

## Adım 1 — Dosyayı karşı PC'ye taşı

`hbys-teshis.ps1` dosyasını AnyDesk ile karşı bilgisayara kopyala.
Masaüstü yeterli, örn. `C:\Users\<kullanici>\Desktop\hbys-teshis.ps1`.

## Adım 2 — Ağı doğrula

Karşı PC **ESKH ağında** olmalı (Wi-Fi ya da kablolu — HBYS'ye erişen ağ).
Script zaten bağlı SSID'yi ve IP'yi raporun başına yazıyor.

## Adım 3 — Çalıştır

PowerShell'i aç (yönetici gerekmez), dosyanın olduğu klasöre gidip:

```powershell
cd $env:USERPROFILE\Desktop
powershell -ExecutionPolicy Bypass -File .\hbys-teshis.ps1
```

Elinde **gerçek bir personel cep numarası** varsa (10 hane, başında 0 yok)
personel sorgusunu da test etsin:

```powershell
powershell -ExecutionPolicy Bypass -File .\hbys-teshis.ps1 -CepTel 5551234567
```

Script ~1 dakika sürer, yanına `hbys-teshis-<tarih>.txt` yazar.
**O dosyayı bana gönder.**

> Not: Rapor, HBYS token'ının ilk 24 karakterini içerir. Herkese açık bir yere
> koyma; doğrudan bana ilet.

---

## Script ne kontrol ediyor?

| # | Kontrol | Ne öğreniyoruz |
| - | ------- | -------------- |
| 1 | SSID / IP / DNS sunucusu | Gerçekten doğru ağda mı |
| 2 | 3 host'un DNS çözümü | `*.eskisehir.yerel` adları bu ağdan görünüyor mu |
| 3 | 443 portu | Sunuculara TCP bağlantısı kurulabiliyor mu |
| 4 | TLS sertifikası | Kurum içi CA mı? Telefonda el sıkışma patlar mı |
| 5 | `entegre-login` | Kullanıcı/şifre/organizationId doğru mu, token geliyor mu |
| 6 | `get-personel-karti-by-cep-tel` | Telefonla giriş akışının HBYS ayağı çalışıyor mu |
| 7 | `aylik-yemek-listesi` | Menü servisi veri dönüyor mu |

---

## Sonuca göre ne yapacağız

**Hepsi [OK] ise** → sorun sadece `useMockHbys` idi. Düzeltilmiş sürümü
derleyip yayınlıyoruz:

```powershell
flutter build appbundle --release
```

**2. adımda DNS çözülmüyorsa** → host adları yanlış ya da bu ağ o DNS'e
erişmiyor. Turkcell'den doğru host adlarını / IP'leri isteyeceğiz;
`AppConfig`'teki üç adresi güncelleyip yeniden derleyeceğiz.

**4. adımda sertifika doğrulanamıyorsa** → sunucular kurum içi bir CA ile
imzalanmış demektir. Telefon o CA'yı tanımadığı için uygulama bağlanamaz.
Çözüm ya kurum CA'sını uygulamaya gömmek, ya da Turkcell'in public bir
sertifika kullanması. Bu durumda söyle, uygulama tarafını ona göre yazarım.

**5. adımda 401/403 geliyorsa** → `KAPARI` / `Eskisehir26.` / `organizationId=106`
üçlüsünde bir şey değişmiş. Doğrusunu alıp `AppConfig`'i güncelleriz.

---

## Hızlı tek satırlık kontroller (script çalışmazsa)

```powershell
# DNS
Resolve-DnsName api-legacy.app.external.eskisehir.yerel

# Port
Test-NetConnection api-legacy.app.external.eskisehir.yerel -Port 443

# Login
$b = '{"username":"KAPARI","password":"Eskisehir26.","organizationId":106}'
Invoke-RestMethod -Uri https://api-legacy.app.external.eskisehir.yerel/auth/entegre-login `
  -Method POST -Body $b -ContentType application/json
```
