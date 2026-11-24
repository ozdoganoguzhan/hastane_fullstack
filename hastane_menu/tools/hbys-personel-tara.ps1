<#
  HBYS PERSONEL SERVISI ADRES TARAYICI
  ESKH agindaki bir Windows PC'de calistirilir.

  DURUM: entegre-login CALISIYOR (token aliniyor). Ama personel sorgusu
         dokumandaki adreste "404 page not found" donuyor. Donen govde HBYS'nin
         JSON hata zarfi DEGIL, duz metin -> istek uygulamaya ulasmiyor,
         onundeki gateway reddediyor. Yani ADRES yanlis.

  NEDEN SUPHELENIYORUZ: Dokuman v1.0'da personel ve menu servisleri icin
         TEST ve CANLI satirlari BIREBIR AYNI yazilmis (kopyala-yapistir);
         yalnizca entegre-login'de gercek bir test host'u var.

  BU SCRIPT: token alir, sonra personel yolunu TUM host'larda ve iki metotla
         dener; menu servisini de ayni sekilde tarar. Hangi kombinasyonun
         gercek cevap verdigini raporlar.

  KULLANIM:
      powershell -ExecutionPolicy Bypass -File .\hbys-personel-tara.ps1 -CepTel 5551234567

  CIKTI: yanina  hbys-personel-tarama-<tarih>.txt  yazar. Onu gonder.
#>

[CmdletBinding()]
param(
    # Gercek bir personel cep telefonu (10 hane, basinda 0 YOK).
    [Parameter(Mandatory = $true)]
    [string]$CepTel,

    [string]$Username       = "KAPARI",
    [string]$Password       = "Eskisehir26.",
    [int]   $OrganizationId = 106,

    [string]$AuthUrl = "https://api-legacy.app.external.eskisehir.yerel/auth/entegre-login",

    # Denenecek host'lar. Turkcell baska bir ad verirse buraya ekle:
    #   -Hosts @("api-quality.app.external.eskisehir.yerel","api-yeni....")
    [string[]]$Hosts = @(
        "api-quality.app.his.eskisehir.yerel",
        "api-quality.app.external.eskisehir.yerel",
        "api-thirdparty.app.his.eskisehir.yerel",
        "api-legacy.app.external.eskisehir.yerel"
    )
)

$ErrorActionPreference = "Continue"
$stamp   = Get-Date -Format "yyyyMMdd-HHmmss"
$logPath = Join-Path $PSScriptRoot "hbys-personel-tarama-$stamp.txt"
$script:lines = @()

function Say {
    param([string]$Text, [string]$Color = "Gray")
    Write-Host $Text -ForegroundColor $Color
    $script:lines += $Text
}
function Head {
    param([string]$T)
    Say ""
    Say ("=" * 72)
    Say $T
    Say ("=" * 72)
}
function OK   { param([string]$T) ; Say "  [BULDUK] $T" "Green" }
function Bad  { param([string]$T) ; Say "  [ - ]    $T" "DarkGray" }
function Warn { param([string]$T) ; Say "  [ ! ]    $T" "Yellow" }

try {
    [Net.ServicePointManager]::SecurityProtocol =
        [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11
} catch { }

# GET+govde icin gerekli (bkz. Try-Endpoint).
Add-Type -AssemblyName System.Net.Http -ErrorAction SilentlyContinue

# Kurum ici sertifikayi kabul et (teshis amacli).
try {
    Add-Type -TypeDefinition @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
using System.Net.Security;
public class HbysScanBypass {
    public static void Enable() {
        ServicePointManager.ServerCertificateValidationCallback =
            delegate(object s, X509Certificate c, X509Chain ch, SslPolicyErrors e) { return true; };
    }
}
"@ -ErrorAction SilentlyContinue
    [HbysScanBypass]::Enable()
} catch { }

Head "HBYS PERSONEL ADRES TARAMASI - $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')"
Say "Aranan numara : $CepTel"

# -------------------------------------------------------------------------
Head "1) TOKEN"
# -------------------------------------------------------------------------
$token = $null
Say "  POST $AuthUrl"
try {
    $body = @{ username = $Username; password = $Password; organizationId = $OrganizationId } |
            ConvertTo-Json -Compress
    $resp = Invoke-WebRequest -Uri $AuthUrl -Method POST -Body $body `
              -ContentType "application/json" `
              -Headers @{ "Accept" = "*/*"; "Accept-Language" = "tr" } `
              -TimeoutSec 20 -UseBasicParsing
    $json = $resp.Content | ConvertFrom-Json
    if ($json.access_token) {
        $token = $json.access_token
        Say "  [OK] token alindi (name=$($json.name))"
    } else {
        Warn "access_token yok. Yanit: $($resp.Content)"
    }
} catch {
    Warn "login basarisiz - $($_.Exception.Message)"
    if ($_.Exception.Response) {
        try {
            $sr = New-Object IO.StreamReader($_.Exception.Response.GetResponseStream())
            Say "         Sunucu yaniti: $($sr.ReadToEnd())"
        } catch { }
    }
}

if (-not $token) {
    Head "TOKEN ALINAMADI - tarama yapilamiyor"
    $script:lines | Out-File -FilePath $logPath -Encoding utf8
    Write-Host "Rapor: $logPath" -ForegroundColor Cyan
    return
}

# -------------------------------------------------------------------------
# HAM HTTPS istegi. GET+govde gonderebilmek icin gerekli (yukaridaki nota bak).
# Ham yaniti (durum satiri + basliklar + govde) tek parca metin olarak doner.
# -------------------------------------------------------------------------
function Invoke-RawHttps {
    param(
        [string]$Method,
        [string]$HostName,
        [string]$PathAndQuery,
        [string]$Body,
        [string]$Bearer
    )

    $tcp = $null
    $ssl = $null
    try {
        $tcp = New-Object Net.Sockets.TcpClient
        $tcp.SendTimeout    = 20000
        $tcp.ReceiveTimeout = 20000
        $tcp.Connect($HostName, 443)

        # Kurum ici sertifikayi kabul et (teshis amacli).
        $cb  = [Net.Security.RemoteCertificateValidationCallback] {
            param($a, $b, $c, $d) return $true
        }
        $ssl = New-Object Net.Security.SslStream($tcp.GetStream(), $false, $cb)
        $ssl.AuthenticateAsClient($HostName)

        $bodyBytes = [byte[]]@()
        if ($Body) { $bodyBytes = [Text.Encoding]::UTF8.GetBytes($Body) }

        $sb = New-Object Text.StringBuilder
        [void]$sb.Append("$Method $PathAndQuery HTTP/1.1`r`n")
        [void]$sb.Append("Host: $HostName`r`n")
        [void]$sb.Append("Authorization: Bearer $Bearer`r`n")
        [void]$sb.Append("Accept: */*`r`n")
        [void]$sb.Append("Accept-Language: tr`r`n")
        if ($bodyBytes.Length -gt 0) {
            [void]$sb.Append("Content-Type: application/json`r`n")
            [void]$sb.Append("Content-Length: $($bodyBytes.Length)`r`n")
        }
        # Connection: close -> sunucu isi bitince akisi kapatir, okuma dongusu
        # deterministik biter (chunked/keep-alive tahmini yapmaya gerek kalmaz).
        [void]$sb.Append("Connection: close`r`n`r`n")

        $head = [Text.Encoding]::ASCII.GetBytes($sb.ToString())
        $ssl.Write($head, 0, $head.Length)
        if ($bodyBytes.Length -gt 0) { $ssl.Write($bodyBytes, 0, $bodyBytes.Length) }
        $ssl.Flush()

        $ms  = New-Object IO.MemoryStream
        $buf = New-Object byte[] 8192
        while ($true) {
            $n = $ssl.Read($buf, 0, $buf.Length)
            if ($n -le 0) { break }
            $ms.Write($buf, 0, $n)
        }
        return [Text.Encoding]::UTF8.GetString($ms.ToArray())
    } finally {
        if ($ssl) { $ssl.Dispose() }
        if ($tcp) { $tcp.Close() }
    }
}

# -------------------------------------------------------------------------
# Tek bir kombinasyonu dener ve sonucu siniflandirir.
# -------------------------------------------------------------------------
function Try-Endpoint {
    param(
        [string]$Method,
        [string]$Url,
        [string]$Body = $null
    )

    # NOT: Ne Invoke-WebRequest ne de .NET Framework'un HttpClient'i GET
    # istegine GOVDE koymaya izin verir ("Bu fiil turuyle icerik govdesi
    # gonderilemez"). Ama dokumana gore aylik-yemek-listesi GET + JSON govde
    # istiyor ve uygulama (dart:io) bunu yapabiliyor. Bu yuzden istegi HAM
    # SOKET uzerinden yaziyoruz: hem kisit kalkiyor, hem de uygulamanin attigi
    # istegin birebir aynisi gidiyor.
    $status  = $null
    $content = $null
    try {
        $u    = [Uri]$Url
        $raw  = Invoke-RawHttps -Method $Method -HostName $u.Host `
                    -PathAndQuery $u.PathAndQuery -Body $Body -Bearer $token

        $split = $raw.IndexOf("`r`n`r`n")
        if ($split -ge 0) {
            $headText = $raw.Substring(0, $split)
            $content  = $raw.Substring($split + 4)
        } else {
            $headText = $raw
            $content  = ""
        }
        if ($headText -match '^HTTP/\d\.\d\s+(\d{3})') { $status = [int]$Matches[1] }
    } catch {
        $content = $_.Exception.Message
        if ($_.Exception.InnerException) {
            $content = "$content | $($_.Exception.InnerException.Message)"
        }
    }

    $short = $content
    if ($short -and $short.Length -gt 300) { $short = $short.Substring(0, 300) + "..." }

    Say ""
    Say "  --> $Method $Url"
    Say "      HTTP $status"
    Say "      Yanit: $short"

    # Siniflandirma:
    #  - "404 page not found" duz metin  -> gateway'de yol YOK
    #  - JSON zarf / data alani          -> UYGULAMAYA ULASTIK
    if ($content -match '404 page not found') {
        Bad "gateway'de boyle bir yol yok"
        return $false
    }
    if ($status -eq 404) {
        Bad "404"
        return $false
    }
    if ($content -match '"present"' -or $content -match '"data"' -or $content -match '"exception"') {
        OK "UYGULAMAYA ULASTIK - bu adres dogru!"
        return $true
    }
    if ($status -eq 401 -or $status -eq 403) {
        Warn "yetki hatasi - yol DOGRU olabilir, token/rol sorunu"
        return $true
    }
    Warn "belirsiz yanit"
    return $false
}

# -------------------------------------------------------------------------
Head "2) PERSONEL SERVISI - host x metot taramasi"
# -------------------------------------------------------------------------
# "404 page not found" yalnizca "bu METOT + bu YOL kaydi yok" demektir; sebebi
# yanlis host OLABILECEGI gibi metot uyusmazligi (Go router'lari 405 yerine 404
# doner), sondaki slash farki ya da gateway oneki de olabilir. Hepsini tariyoruz.
$personelPaths = @(
    "/personel/get-personel-karti-by-cep-tel?cepTel=$CepTel",
    "/personel/get-personel-karti-by-cep-tel/?cepTel=$CepTel",
    "/get-personel-karti-by-cep-tel?cepTel=$CepTel"
)
$hits = @()

foreach ($h in $Hosts) {
    foreach ($p in $personelPaths) {
        foreach ($m in @("POST", "GET")) {
            if (Try-Endpoint -Method $m -Url "https://$h$p") {
                $hits += "$m https://$h$p"
            }
        }
    }
}

# -------------------------------------------------------------------------
Head "3) MENU SERVISI - hangi host'ta?"
# -------------------------------------------------------------------------
$now = Get-Date
$menuBody = @{
    page = 0; rows = 100; first = 0; sortField = "id"; sortOrder = 0
    filters = @{
        yil = @{ value = $now.Year;  type = "int"; matchMode = "equals" }
        ay  = @{ value = $now.Month; type = "int"; matchMode = "equals" }
    }
} | ConvertTo-Json -Depth 5 -Compress

$menuHits = @()
foreach ($h in $Hosts) {
    $url = "https://$h/aylik-yemek-listesi/get-kayit-list"
    if (Try-Endpoint -Method "GET" -Url $url -Body $menuBody) {
        $menuHits += "GET $url"
    }
}

# -------------------------------------------------------------------------
Head "SONUC"
# -------------------------------------------------------------------------
if ($hits.Count -gt 0) {
    Say "  PERSONEL servisi su adres(ler)de calisiyor:"
    foreach ($x in $hits) { OK $x }
} else {
    Warn "PERSONEL servisi denenen 3 host'un HICBIRINDE bulunamadi."
    Say "  -> Turkcell'e sorulacak: canli ortamda"
    Say "     get-personel-karti-by-cep-tel hangi host/path uzerinde?"
}

Say ""
if ($menuHits.Count -gt 0) {
    Say "  MENU servisi su adres(ler)de calisiyor:"
    foreach ($x in $menuHits) { OK $x }
} else {
    Warn "MENU servisi de bulunamadi."
}

Head "BITTI"
Say "Rapor dosyasi: $logPath"
$script:lines | Out-File -FilePath $logPath -Encoding utf8
Write-Host ""
Write-Host "Rapor: $logPath" -ForegroundColor Cyan
Write-Host "Bu dosyayi gonder." -ForegroundColor Cyan
