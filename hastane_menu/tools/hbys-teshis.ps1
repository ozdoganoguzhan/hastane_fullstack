<#
  HBYS BAGLANTI TESHISI - hastane (ESKH) agindaki bir Windows PC'de calistirilir.

  AMAC: Uygulamanin canlida konusacagi Turkcell HBYS host'lari bu agdan
  gercekten erisilebiliyor mu? DNS cozuluyor mu, 443 acik mi, sertifika
  gecerli mi, entegre-login token veriyor mu, personel sorgusu calisiyor mu?

  KULLANIM (yonetici gerekmez):

      powershell -ExecutionPolicy Bypass -File .\hbys-teshis.ps1
      powershell -ExecutionPolicy Bypass -File .\hbys-teshis.ps1 -CepTel 5551234567

  CIKTI: yanina  hbys-teshis-<tarih>.txt  yazar. O dosyayi gonder.

  DIKKAT: Cikti dosyasi HBYS access token'inin ilk 24 karakterini icerir.
          Herkese acik bir yere koyma.

  NOT: Bu dosya bilerek sadece ASCII karakter icerir. PowerShell 5.1 BOM'suz
       dosyalari ANSI okur; Turkce harf/kutu karakteri konursa script bozulur.
#>

[CmdletBinding()]
param(
    # Personel sorgusunu da denemek icin gercek bir personel cep telefonu
    # (10 hane, basinda 0 YOK). Bos birakilirsa o adim atlanir.
    [string]$CepTel = "",

    [string]$Username       = "KAPARI",
    [string]$Password       = "Eskisehir26.",
    [int]   $OrganizationId = 106,

    [string]$AuthHost      = "api-legacy.app.external.eskisehir.yerel",
    [string]$MenuHost      = "api-thirdparty.app.his.eskisehir.yerel",
    [string]$PersonnelHost = "api-quality.app.his.eskisehir.yerel"
)

$ErrorActionPreference = "Continue"
$stamp   = Get-Date -Format "yyyyMMdd-HHmmss"
$logPath = Join-Path $PSScriptRoot "hbys-teshis-$stamp.txt"
$script:lines = @()

function Say {
    param([string]$Text, [string]$Color = "Gray")
    Write-Host $Text -ForegroundColor $Color
    $script:lines += $Text
}
function Head {
    param([string]$T)
    Say ""
    Say ("=" * 70)
    Say $T
    Say ("=" * 70)
}
function OK   { param([string]$T) ; Say "  [OK]   $T" "Green" }
function Bad  { param([string]$T) ; Say "  [HATA] $T" "Red" }
function Note { param([string]$T) ; Say "         $T" "DarkGray" }

# Windows PowerShell 5.1: TLS 1.2'yi elle ac, yoksa modern sunucularla el
# sikisma basarisiz olur ve sorun sertifika sanilir.
try {
    [Net.ServicePointManager]::SecurityProtocol =
        [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11
} catch { }

Head "HBYS TESHIS - $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')"
Say "Bilgisayar : $env:COMPUTERNAME"
Say "Kullanici  : $env:USERNAME"
Say "PowerShell : $($PSVersionTable.PSVersion)"

# -------------------------------------------------------------------------
Head "1) AG - hangi Wi-Fi / hangi IP?"
# -------------------------------------------------------------------------
try {
    $wifi = (netsh wlan show interfaces) 2>$null
    if ($wifi) {
        $m = $wifi | Select-String -Pattern '^\s*SSID\s*:\s*(.+)$'
        if ($m) {
            $ssid = $m.Matches[0].Groups[1].Value.Trim()
            Say "  Bagli SSID : $ssid"
        } else {
            Say "  Bagli SSID : (bulunamadi - kablolu baglanti olabilir)"
        }
    }
} catch {
    Note "SSID okunamadi (kablolu baglanti olabilir, sorun degil)."
}

Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object { $_.IPAddress -ne "127.0.0.1" } |
    ForEach-Object { Say ("  IP         : {0}  ({1})" -f $_.IPAddress, $_.InterfaceAlias) }

Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object { $_.ServerAddresses.Count -gt 0 } |
    ForEach-Object { Say ("  DNS        : {0}  ({1})" -f ($_.ServerAddresses -join ", "), $_.InterfaceAlias) }

# -------------------------------------------------------------------------
Head "2) DNS - host adlari cozuluyor mu?"
# -------------------------------------------------------------------------
$hostList = @(
    @{ Name = $AuthHost;      Rol = "auth (entegre-login)" },
    @{ Name = $MenuHost;      Rol = "menu (aylik-yemek-listesi)" },
    @{ Name = $PersonnelHost; Rol = "personel (cep-tel sorgusu)" }
)

$resolved = @{}
foreach ($h in $hostList) {
    Say ""
    Say ("  --> {0}   [{1}]" -f $h.Name, $h.Rol)
    try {
        $r = Resolve-DnsName -Name $h.Name -Type A -ErrorAction Stop |
             Where-Object { $_.IPAddress }
        if ($r) {
            foreach ($rec in $r) { OK ("cozuldu -> {0}" -f $rec.IPAddress) }
            $resolved[$h.Name] = ($r | Select-Object -First 1).IPAddress
        } else {
            Bad "A kaydi donmedi"
        }
    } catch {
        Bad ("COZULEMEDI - {0}" -f $_.Exception.Message)
        Note "Bu host bu agdan gorunmuyor. Ya isim yanlis, ya da bu ag bu DNS sunucusuna erisemiyor."
    }
}

# -------------------------------------------------------------------------
Head "3) TCP - 443 portu acik mi?"
# -------------------------------------------------------------------------
foreach ($h in $hostList) {
    $name = $h.Name
    if (-not $resolved.ContainsKey($name)) {
        Note "$name : DNS cozulmedigi icin atlandi"
        continue
    }
    try {
        $t = Test-NetConnection -ComputerName $name -Port 443 -WarningAction SilentlyContinue
        if ($t.TcpTestSucceeded) {
            OK ("{0} : 443 ACIK  (ping: {1})" -f $name, $t.PingSucceeded)
        } else {
            Bad "$name : 443 KAPALI / yanit yok"
            Note "Guvenlik duvari veya yonlendirme engelliyor olabilir."
        }
    } catch {
        Bad ("{0} : test edilemedi - {1}" -f $name, $_.Exception.Message)
    }
}

# -------------------------------------------------------------------------
Head "4) TLS - sertifika gecerli mi?"
# -------------------------------------------------------------------------
# Uygulama (Flutter/dart:io) sertifikayi CIHAZIN kok deposuna gore dogrular.
# Kurum ici bir CA ile imzalanmissa telefonda el sikisma patlar.
foreach ($h in $hostList) {
    $name = $h.Name
    if (-not $resolved.ContainsKey($name)) { continue }
    Say ""
    Say "  --> $name"
    $tcp = $null
    $ssl = $null
    $strict = $true
    try {
        $tcp = New-Object Net.Sockets.TcpClient
        $tcp.Connect($name, 443)
        $ssl = New-Object Net.Security.SslStream($tcp.GetStream(), $false)
        try {
            $ssl.AuthenticateAsClient($name)
            OK "sertifika zinciri GECERLI (Windows kok deposuna gore)"
        } catch {
            $strict = $false
            Bad ("sertifika DOGRULANAMADI - {0}" -f $_.Exception.Message)
            Note "Telefonda da ayni hata olusur: 'guvenlik sertifikasi dogrulanamadi'."
            $ssl.Dispose()
            $tcp.Close()
            $tcp = New-Object Net.Sockets.TcpClient
            $tcp.Connect($name, 443)
            $cb = [Net.Security.RemoteCertificateValidationCallback] { param($a, $b, $c, $d) return $true }
            $ssl = New-Object Net.Security.SslStream($tcp.GetStream(), $false, $cb)
            $ssl.AuthenticateAsClient($name)
        }
        $cert = [Security.Cryptography.X509Certificates.X509Certificate2]$ssl.RemoteCertificate
        Say ("         Konu     : {0}" -f $cert.Subject)
        Say ("         Veren    : {0}" -f $cert.Issuer)
        Say ("         Gecerlik : {0} - {1}" -f $cert.NotBefore.ToString("dd.MM.yyyy"), $cert.NotAfter.ToString("dd.MM.yyyy"))
        if ($cert.NotAfter -lt (Get-Date)) { Bad "SERTIFIKA SURESI DOLMUS" }
        if (-not $strict) { Note "(yukaridaki bilgiler dogrulama atlanarak okundu)" }
    } catch {
        Bad ("TLS baglantisi kurulamadi - {0}" -f $_.Exception.Message)
    } finally {
        if ($ssl) { $ssl.Dispose() }
        if ($tcp) { $tcp.Close() }
    }
}

# -------------------------------------------------------------------------
Head "5) ENTEGRE-LOGIN - token aliniyor mu?"
# -------------------------------------------------------------------------
# Sertifika sorunu teshisi engellemesin diye bu adimda dogrulama atlanir;
# gercek sertifika durumu 4. adimda zaten raporlandi.
try {
    Add-Type -TypeDefinition @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
using System.Net.Security;
public class HbysCertBypass {
    public static void Enable() {
        ServicePointManager.ServerCertificateValidationCallback =
            delegate(object s, X509Certificate c, X509Chain ch, SslPolicyErrors e) { return true; };
    }
}
"@ -ErrorAction SilentlyContinue
    [HbysCertBypass]::Enable()
} catch { }

$token = $null
$loginUrl = "https://$AuthHost/auth/entegre-login"
Say "  POST $loginUrl"
Say "  govde: { username=$Username, password=***, organizationId=$OrganizationId }"
try {
    $body = @{ username = $Username; password = $Password; organizationId = $OrganizationId } |
            ConvertTo-Json -Compress
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $resp = Invoke-WebRequest -Uri $loginUrl -Method POST -Body $body `
              -ContentType "application/json" `
              -Headers @{ "Accept" = "*/*"; "Accept-Language" = "tr" } `
              -TimeoutSec 20 -UseBasicParsing
    $sw.Stop()
    OK ("HTTP {0} - {1} ms" -f $resp.StatusCode, $sw.ElapsedMilliseconds)
    $json = $resp.Content | ConvertFrom-Json
    if ($json.access_token) {
        $token = $json.access_token
        $short = $token.Substring(0, [Math]::Min(24, $token.Length))
        OK "access_token alindi (ilk 24 karakter): $short..."
        if ($json.expires_in) { Say ("         expires_in: {0}" -f $json.expires_in) }
        if ($json.name)       { Say ("         name      : {0}" -f $json.name) }
    } else {
        Bad "yanitta access_token YOK"
        Say ("         Yanit: {0}" -f $resp.Content)
    }
} catch {
    Bad ("login BASARISIZ - {0}" -f $_.Exception.Message)
    if ($_.Exception.Response) {
        try {
            $sr = New-Object IO.StreamReader($_.Exception.Response.GetResponseStream())
            Say ("         Sunucu yaniti: {0}" -f $sr.ReadToEnd())
        } catch { }
    }
}

# -------------------------------------------------------------------------
Head "6) PERSONEL SORGUSU - telefon numarasi dogrulaniyor mu?"
# -------------------------------------------------------------------------
if (-not $token) {
    Note "Token alinamadigi icin atlandi."
} elseif (-not $CepTel) {
    Note "-CepTel verilmedi, atlandi.  Ornek:  .\hbys-teshis.ps1 -CepTel 5551234567"
} else {
    $url = "https://$PersonnelHost/personel/get-personel-karti-by-cep-tel?cepTel=$CepTel"
    Say "  POST $url"
    try {
        $sw = [Diagnostics.Stopwatch]::StartNew()
        $resp = Invoke-WebRequest -Uri $url -Method POST `
                  -Headers @{ "Authorization" = "Bearer $token"; "Accept" = "*/*"; "Accept-Language" = "tr" } `
                  -TimeoutSec 20 -UseBasicParsing
        $sw.Stop()
        OK ("HTTP {0} - {1} ms" -f $resp.StatusCode, $sw.ElapsedMilliseconds)
        Say ("         Yanit: {0}" -f $resp.Content)
    } catch {
        Bad ("personel sorgusu BASARISIZ - {0}" -f $_.Exception.Message)
        if ($_.Exception.Response) {
            try {
                $sr = New-Object IO.StreamReader($_.Exception.Response.GetResponseStream())
                Say ("         Sunucu yaniti: {0}" -f $sr.ReadToEnd())
            } catch { }
        }
    }
}

# -------------------------------------------------------------------------
Head "7) AYLIK MENU - menu servisi calisiyor mu?"
# -------------------------------------------------------------------------
if (-not $token) {
    Note "Token alinamadigi icin atlandi."
} else {
    $url = "https://$MenuHost/aylik-yemek-listesi/get-kayit-list"
    $now = Get-Date
    Say ("  GET {0}   (yil={1}, ay={2})" -f $url, $now.Year, $now.Month)
    Note "Not: bu servis GET + JSON govde ister (dokumana gore)."
    try {
        $body = @{
            page = 0; rows = 100; first = 0; sortField = "id"; sortOrder = 0
            filters = @{
                yil = @{ value = $now.Year;  type = "int"; matchMode = "equals" }
                ay  = @{ value = $now.Month; type = "int"; matchMode = "equals" }
            }
        } | ConvertTo-Json -Depth 5 -Compress
        $sw = [Diagnostics.Stopwatch]::StartNew()
        $resp = Invoke-WebRequest -Uri $url -Method GET -Body $body `
                  -ContentType "application/json" `
                  -Headers @{ "Authorization" = "Bearer $token"; "Accept" = "*/*"; "Accept-Language" = "tr" } `
                  -TimeoutSec 20 -UseBasicParsing
        $sw.Stop()
        OK ("HTTP {0} - {1} ms" -f $resp.StatusCode, $sw.ElapsedMilliseconds)
        $len = $resp.Content.Length
        Say ("         Yanit uzunlugu: {0} karakter" -f $len)
        Say "         Ilk 400 karakter:"
        Say ("         {0}" -f $resp.Content.Substring(0, [Math]::Min(400, $len)))
    } catch {
        Bad ("menu sorgusu BASARISIZ - {0}" -f $_.Exception.Message)
        if ($_.Exception.Response) {
            try {
                $sr = New-Object IO.StreamReader($_.Exception.Response.GetResponseStream())
                Say ("         Sunucu yaniti: {0}" -f $sr.ReadToEnd())
            } catch { }
        }
    }
}

Head "BITTI"
Say "Rapor dosyasi: $logPath"
$script:lines | Out-File -FilePath $logPath -Encoding utf8
Write-Host ""
Write-Host "Rapor kaydedildi: $logPath" -ForegroundColor Cyan
Write-Host "Bu dosyayi gonder." -ForegroundColor Cyan
