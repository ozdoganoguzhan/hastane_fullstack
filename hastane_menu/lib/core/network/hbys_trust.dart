import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:hastane_menu/core/constants/app_config.dart';

/// HBYS sunucularının TLS sertifikasına nasıl güvenildiğini yöneten yer.
///
/// **Sorun:** Turkcell HBYS host'ları (`*.eskisehir.yerel`) kurum içi /
/// kendinden imzalı bir sertifika sunuyor. Android'in kök deposu bu zinciri
/// tanımadığı için `dart:io` el sıkışmayı reddediyor:
/// `HandshakeException: ... certificate verify failed`.
/// Windows'ta tarayıcı çalışabilir, çünkü Windows eksik ara sertifikayı
/// internetten indirebilir (AIA); Android bunu YAPMAZ.
///
/// **Uygulanan çözüm:** [AppConfig.trustInternalHbysCertificate] açıkken bu
/// host'ların sertifikası doğrulanmadan kabul edilir.
///
/// ⚠️ Kabul **yalnızca HBYS host'larına** özeldir; SMS gateway'i ve diğer tüm
/// bağlantılar normal doğrulamadan geçmeye devam eder. Yani "tüm TLS kapalı"
/// değil, "şu üç iç sunucu için doğrulama atlanıyor" durumundayız.
///
/// Daha sağlamı istenirse: kurum CA'sı `tools/hbys-sertifika-al.ps1` ile
/// çıkarılıp [_caAsset] yoluna konur; o dosya varsa doğrulama gerçekten yapılır
/// ve aşağıdaki atlama gereksiz kalır.
sealed class HbysTrust {
  /// Gömülü CA paketi (PEM). Opsiyoneldir; yoksa sistem kökleri kullanılır.
  static const String _caAsset = 'assets/certs/hbys-ca.pem';

  static SecurityContext? _context;

  /// Sertifikası doğrulanmadan kabul edilecek host'lar — [AppConfig]'teki
  /// gerçek HBYS adreslerinden türetilir ki listeler birbirinden ayrı düşmesin.
  static final Set<String> _internalHosts = {
    Uri.parse(AppConfig.hbysAuthBaseUrl).host,
    Uri.parse(AppConfig.hbysMenuBaseUrl).host,
    Uri.parse(AppConfig.hbysPersonnelBaseUrl).host,
  };

  /// İstemcinin kullanacağı güven bağlamı. CA gömülü değilse `null` döner
  /// (sistem kökleri kullanılır). Bir kez kurulur, sonra önbellekten döner.
  ///
  /// ⚠️ Önbellek **Future** olarak tutulur, bayrak olarak DEĞİL. Bayrak
  /// kullanılsaydı (`if (_ready) return _context;` + `_ready = true;`) bayrak
  /// `await`ten önce set edildiği için eşzamanlı ikinci çağrı CA daha
  /// yüklenmeden `null` alırdı — ve entegre-login ile personel sorgusu tam da
  /// eşzamanlı gidiyor. Future'ı paylaşınca ikinci çağrı da aynı sonucu bekler.
  static Future<SecurityContext?> context() => _loading ??= _load();

  static Future<SecurityContext?>? _loading;

  static Future<SecurityContext?> _load() async {
    try {
      final pem = await rootBundle.load(_caAsset);
      final bytes = pem.buffer.asUint8List(
        pem.offsetInBytes,
        pem.lengthInBytes,
      );
      if (bytes.isEmpty) return _context;

      // withTrustedRoots: sistem kökleri KORUNUR, üzerine kurum CA'sı eklenir.
      _context = SecurityContext(withTrustedRoots: true)
        ..setTrustedCertificatesBytes(bytes);
      debugPrint('[TLS] Kurum CA paketi yuklendi (${bytes.length} bayt).');
    } on TlsException catch (e) {
      // Bozuk PEM'i sessizce yutma; aksi hâlde neden çalışmadığı anlaşılmaz.
      debugPrint('[TLS] CA paketi OKUNAMADI (gecersiz PEM): ${e.message}');
    } catch (_) {
      // Asset yok → normal durum, CA gömülmemiş demektir.
    }
    return _context;
  }

  /// Doğrulaması başarısız sertifikalar için karar.
  ///
  /// Yalnızca [_internalHosts] içindeki HBYS sunucuları için `true` döner.
  /// Başka bir host'un bozuk sertifikası **kabul edilmez**.
  static bool Function(X509Certificate, String, int)? get badCertificateCallback {
    if (!AppConfig.trustInternalHbysCertificate) return null;
    return (cert, host, port) {
      final internal = _internalHosts.contains(host);
      debugPrint(
        internal
            ? '[TLS] Kurum ici sertifika kabul edildi: $host:$port '
                  '(${cert.subject})'
            : '[TLS] REDDEDILDI (HBYS host listesinde degil): $host:$port',
      );
      return internal;
    };
  }
}
