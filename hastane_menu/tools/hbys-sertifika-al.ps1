<#
  HBYS SERTIFIKA ZINCIRI CIKARICI
  ESKH agindaki Windows PC'de calistirilir.

  NEDEN: Telefonda "guvenlik sertifikasi dogrulanamadi / handshake error"
  aliniyor. Iki farkli sebep olabilir ve COZUMLERI FARKLI:

    (A) UntrustedRoot  -> Sunucu kurum ici bir CA ile imzalanmis. Android bu
                          CA'yi tanimiyor. Cozum: CA sertifikasini uygulamaya
                          gommek.
    (B) PartialChain   -> Sunucu ara (intermediate) sertifikayi GONDERMIYOR.
                          Windows eksigi internetten indirip tamamlayabildigi
                          icin tarayicida sorun cikmaz, Android indiremez.
                          Cozum: ya sunucu tam zinciri gonderecek, ya da ara
                          sertifikayi uygulamaya gomecegiz.

  Bu script hangisi oldugunu soyler ve gereken sertifikalari disari yazar.

  KULLANIM:
      powershell -ExecutionPolicy Bypass -File .\hbys-sertifika-al.ps1

  CIKTI: yanina  certs\  klasoru + hbys-ca.pem + hbys-sertifika-raporu.txt
         BU UC CIKTIYI DA GONDER (klasoru zip'leyip atman en kolayi).

  NOT: Sertifikalar GIZLI BILGI DEGILDIR (herkese acik sunulan verilerdir),
       rahatca gonderebilirsin.
#>

[CmdletBinding()]
param(
    [string[]]$Hosts = @(
        "api-legacy.app.external.eskisehir.yerel",
        "api-thirdparty.app.his.eskisehir.yerel",
        "api-quality.app.his.eskisehir.yerel"
    ),
    [int]$Port = 443
)

$ErrorActionPreference = "Continue"
$outDir  = Join-Path $PSScriptRoot "certs"
$pemPath = Join-Path $PSScriptRoot "hbys-ca.pem"
$logPath = Join-Path $PSScriptRoot "hbys-sertifika-raporu.txt"
$script:lines = @()
$script:caCerts = @{}   # thumbprint -> cert (tekrar yazmamak icin)

if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

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
function Bad  { param([string]$T) ; Say "  [!!]   $T" "Red" }
function Note { param([string]$T) ; Say "         $T" "DarkGray" }

try {
    [Net.ServicePointManager]::SecurityProtocol =
        [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11
} catch { }

function Save-Cert {
    param($Cert, [string]$HostName, [int]$Index)
    $cn = "cert"
    try {
        $cn = $Cert.GetNameInfo([Security.Cryptography.X509Certificates.X509NameType]::SimpleName, $false)
    } catch { }
    if (-not $cn) { $cn = "cert" }
    $safe = ($cn -replace '[^A-Za-z0-9\.\-_]', '_')
    $file = Join-Path $outDir ("{0}-{1}-{2}.cer" -f $HostName, $Index, $safe)

    $b64 = [Convert]::ToBase64String($Cert.RawData, [Base64FormattingOptions]::InsertLineBreaks)
    $pem = "-----BEGIN CERTIFICATE-----`r`n$b64`r`n-----END CERTIFICATE-----`r`n"
    [IO.File]::WriteAllText($file, $pem, [Text.Encoding]::ASCII)
    return $file
}

Head "HBYS SERTIFIKA ZINCIRI - $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')"
Say "Bilgisayar : $env:COMPUTERNAME"
Say "Cikti      : $outDir"

foreach ($h in $Hosts) {
    Head "HOST: $h"

    $tcp = $null
    $ssl = $null

    # ONEMLI: callback'e gelen X509Chain nesnesi callback DONDUKTEN SONRA
    # gecersizlesir (.NET onu sifirlar). Bu yuzden sertifikalari ve durum
    # bayraklarini callback'in ICINDE kopyaliyoruz.
    $script:capCerts  = @()
    $script:capStatus = @()
    $script:capErrors = "None"

    try {
        $tcp = New-Object Net.Sockets.TcpClient
        $tcp.Connect($h, $Port)

        # Dogrulamayi ATLAYAN ama zinciri YAKALAYAN callback: boylece sunucu
        # ne gonderiyorsa gorebiliyoruz, hata olsa bile.
        $cb = [Net.Security.RemoteCertificateValidationCallback] {
            param($sender, $certificate, $chain, $sslPolicyErrors)
            $script:capErrors = $sslPolicyErrors
            if ($chain) {
                foreach ($el in $chain.ChainElements) {
                    $script:capCerts += New-Object `
                        Security.Cryptography.X509Certificates.X509Certificate2 (, $el.Certificate.RawData)
                }
                foreach ($st in $chain.ChainStatus) {
                    $script:capStatus += ("{0}|{1}" -f $st.Status, $st.StatusInformation.Trim())
                }
            }
            if ($script:capCerts.Count -eq 0 -and $certificate) {
                $script:capCerts += New-Object `
                    Security.Cryptography.X509Certificates.X509Certificate2 (, $certificate.GetRawCertData())
            }
            return $true
        }
        $ssl = New-Object Net.Security.SslStream($tcp.GetStream(), $false, $cb)
        $ssl.AuthenticateAsClient($h)

        Say "  TLS protokolu : $($ssl.SslProtocol)"
        Say "  Dogrulama     : $($script:capErrors)"
        Say ""

        if ($script:capCerts.Count -gt 0) {
            Say "  ZINCIR ($($script:capCerts.Count) sertifika):"
            $i = 0
            foreach ($c in $script:capCerts) {
                $rol = "ARA (intermediate)"
                if ($i -eq 0) { $rol = "SUNUCU (leaf)" }
                if ($c.Subject -eq $c.Issuer) { $rol = "KOK (root CA)" }

                Say ""
                Say "   [$i] $rol"
                Say "       Konu       : $($c.Subject)"
                Say "       Veren      : $($c.Issuer)"
                Say "       Gecerlik   : $($c.NotBefore.ToString('dd.MM.yyyy')) - $($c.NotAfter.ToString('dd.MM.yyyy'))"
                Say "       Parmak izi : $($c.Thumbprint)"
                if ($c.NotAfter -lt (Get-Date)) { Bad "BU SERTIFIKANIN SURESI DOLMUS" }

                $saved = Save-Cert -Cert $c -HostName $h -Index $i
                Note "kaydedildi: $(Split-Path $saved -Leaf)"

                # Leaf disindaki her sertifika CA paketine girer.
                if ($i -gt 0 -and -not $script:caCerts.ContainsKey($c.Thumbprint)) {
                    $script:caCerts[$c.Thumbprint] = $c
                }
                $i++
            }
        } else {
            Bad "Zincir okunamadi."
        }

        Say ""
        if ($script:capStatus.Count -gt 0) {
            Say "  ZINCIR DURUMU:"
            foreach ($st in $script:capStatus) {
                $parts = $st -split '\|', 2
                Bad "$($parts[0]) - $($parts[1])"
            }
            $flags = $script:capStatus -join ","
            Say ""
            if ($flags -match "PartialChain") {
                Say "  >>> TESHIS: (B) ARA SERTIFIKA EKSIK" "Yellow"
                Note "Sunucu tam zinciri gondermiyor. Android bunu tamamlayamaz."
            } elseif ($flags -match "UntrustedRoot") {
                Say "  >>> TESHIS: (A) KURUM ICI CA" "Yellow"
                Note "Kok sertifika Windows/Android deposunda yok, uygulamaya gomulmeli."
            } else {
                Say "  >>> TESHIS: baska bir zincir sorunu (yukaridaki duruma bak)" "Yellow"
            }
        } else {
            OK "Windows'a gore zincir SORUNSUZ."
            Note "Windows eksik ara sertifikayi internetten indirmis olabilir (AIA)."
            Note "Android bunu YAPAMAZ; asagidaki hbys-ca.pem yine de gomulmelidir."
        }

    } catch {
        Bad "Baglanti kurulamadi - $($_.Exception.Message)"
    } finally {
        if ($ssl) { $ssl.Dispose() }
        if ($tcp) { $tcp.Close() }
    }
}

# -------------------------------------------------------------------------
Head "BIRLESIK CA PAKETI (uygulamaya gomulecek dosya)"
# -------------------------------------------------------------------------
if ($script:caCerts.Count -eq 0) {
    Bad "Hicbir CA sertifikasi toplanamadi."
    Note "Sunucu yalnizca leaf gonderiyor olabilir; certs\ klasorundeki 0 numarali"
    Note "dosyalari yine de gonder."
} else {
    $sb = New-Object Text.StringBuilder
    foreach ($tp in $script:caCerts.Keys) {
        $c = $script:caCerts[$tp]
        $cn = "CA"
        try { $cn = $c.GetNameInfo([Security.Cryptography.X509Certificates.X509NameType]::SimpleName, $false) } catch { }
        [void]$sb.AppendLine("# $cn")
        [void]$sb.AppendLine("# Veren: $($c.Issuer)")
        [void]$sb.AppendLine("# Parmak izi: $($c.Thumbprint)")
        $b64 = [Convert]::ToBase64String($c.RawData, [Base64FormattingOptions]::InsertLineBreaks)
        [void]$sb.AppendLine("-----BEGIN CERTIFICATE-----")
        [void]$sb.AppendLine($b64)
        [void]$sb.AppendLine("-----END CERTIFICATE-----")
        [void]$sb.AppendLine("")
    }
    [IO.File]::WriteAllText($pemPath, $sb.ToString(), [Text.Encoding]::ASCII)
    OK "$($script:caCerts.Count) adet CA sertifikasi yazildi:"
    Say "         $pemPath"
}

Head "BITTI - SUNU GONDER"
Say "  1) $pemPath"
Say "  2) $outDir  (klasorun tamami)"
Say "  3) $logPath"
$script:lines | Out-File -FilePath $logPath -Encoding utf8
Write-Host ""
Write-Host "Rapor: $logPath" -ForegroundColor Cyan
Write-Host "hbys-ca.pem ve certs klasorunu gonder." -ForegroundColor Cyan
