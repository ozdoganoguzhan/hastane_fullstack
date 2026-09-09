import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hastane_menu/core/constants/app_config.dart';
import 'package:hastane_menu/core/network/hbys_trust.dart';

/// HBYS çağrısı başarısız olduğunda fırlatılır.
///
/// Doküman hata zarfı: `{ httpStatus, exception: { errorCode, errorMessage } }`.
///
/// Kullanıcıya gösterilen [message] dışında, sahada "ne nerede patladı"
/// sorusunu cevaplayacak ham bilgiyi de taşır ([stage], [url], [statusCode],
/// [responseBody], [exceptionType]). Bu alanlar yalnızca
/// `AppConfig.showErrorDiagnostics` açıkken ekranda gösterilir.
class HbysException implements Exception {
  const HbysException(
    this.message, {
    this.statusCode,
    this.errorCode,
    this.stage,
    this.method,
    this.url,
    this.responseBody,
    this.exceptionType,
  });

  final String message;
  final int? statusCode;
  final String? errorCode;

  /// Hangi adım? ("entegre-login", "personel sorgusu", "aylık menü")
  final String? stage;

  /// İstek fiili ve tam adresi.
  final String? method;
  final String? url;

  /// Sunucunun döndürdüğü HAM gövde (kısaltılmış).
  final String? responseBody;

  /// Yakalanan alt seviye istisnanın tipi (`SocketException`, `HandshakeException`…).
  final String? exceptionType;

  /// Token/oturum kaynaklı mı? (doküman: exception alınırsa yeniden login).
  bool get isAuthError =>
      statusCode == 401 ||
      statusCode == 403 ||
      (errorCode?.toUpperCase().startsWith('AUTH') ?? false);

  /// Ekranda/panoda gösterilecek teknik döküm.
  String get diagnostics {
    final b = StringBuffer();
    void line(String k, Object? v) {
      if (v == null) return;
      final s = '$v';
      if (s.trim().isEmpty) return;
      b.writeln('$k: $s');
    }

    line('Aşama', stage);
    line('İstek', [method, url].where((e) => e != null).join(' '));
    line('İstisna', exceptionType);
    line('HTTP', statusCode);
    line('errorCode', errorCode);
    line('Mesaj', message);
    line('Yanıt', responseBody);
    return b.toString().trimRight();
  }

  @override
  String toString() => message;
}

/// Turkcell HBYS Yemekhane servislerine **doğrudan** bağlanan istemci.
///
/// Araya bizim API'miz girmez; entegrasyon dokümanındaki protokol birebir
/// uygulanır:
///  • `POST {auth}/auth/entegre-login` → Bearer token (~60 dk)
///  • `GET  {menu}/aylik-yemek-listesi/get-kayit-list` (PrimeNG filter gövdesi)
///  • `POST {personnel}/personel/get-personel-karti-by-cep-tel?cepTel=`
///
/// Token bellekte tutulur, süresi dolunca ya da AUTH hatasında otomatik yenilenir.
class HbysClient {
  HbysClient();

  String? _token;
  DateTime? _tokenExpiresAt;
  Future<String>? _pendingLogin;

  /// Geçerli token'ı döner; yoksa/süresi dolduysa entegre-login yapar.
  /// Eşzamanlı çağrılarda tek login uçuşu paylaşılır.
  Future<String> _token$({bool forceRefresh = false}) {
    if (!forceRefresh && _isTokenValid) return Future.value(_token!);
    return _pendingLogin ??= _login().whenComplete(() => _pendingLogin = null);
  }

  bool get _isTokenValid =>
      _token != null &&
      _tokenExpiresAt != null &&
      DateTime.now().isBefore(
        _tokenExpiresAt!.subtract(const Duration(minutes: 2)),
      );

  /// Doküman: ENTEGRE-LOGIN. Yanıt: `{ name, access_token, expires_in }`.
  ///
  /// ⚠️ Buradaki kimlik bilgileri **entegrasyon servis hesabıdır**, kullanıcının
  /// kendi bilgisi DEĞİLDİR. HBYS bunu reddederse dönen metin ("Kullanıcı adı
  /// veya şifre hatalı" gibi) doğrudan kullanıcıya gösterilirse, kişi kendi
  /// telefonunu yanlış girdiğini sanır. Bir kez sahada tam bu oldu → sunucu
  /// mesajını sarmalayıp NE OLDUĞUNU söylüyoruz.
  Future<String> _login() async {
    final dynamic json;
    try {
      json = await _send(
        method: 'POST',
        url: '${_trim(AppConfig.authBaseUrl)}/auth/entegre-login',
        stage: '1) entegre-login (servis hesabı)',
        body: {
          'username': AppConfig.hbysUsername,
          'password': AppConfig.hbysPassword,
          'organizationId': AppConfig.hbysOrganizationId,
        },
      );
    } on HbysException catch (e) {
      throw HbysException(
        'Sunucu bağlantısı kurulamadı: yemekhane entegrasyon hesabı kabul '
        'edilmedi. Lütfen yetkiliye bildirin. (HBYS: ${e.message})',
        statusCode: e.statusCode,
        errorCode: e.errorCode,
        stage: e.stage ?? '1) entegre-login (servis hesabı)',
        method: e.method,
        url: e.url,
        responseBody: e.responseBody,
        exceptionType: e.exceptionType,
      );
    }

    if (json is! Map || json['access_token'] is! String) {
      throw const HbysException('HBYS giriş yanıtında access_token bulunamadı.');
    }

    _token = json['access_token'] as String;
    _tokenExpiresAt = _parseExpiry(json['expires_in']);
    return _token!;
  }

  /// `expires_in` örnekte epoch-ms (1773779828239); dokümanda tip "string"
  /// yazıyor. İkisini de kabul et; çözülemezse varsayılan 55 dk (doc: ~60 dk).
  DateTime _parseExpiry(dynamic raw) {
    final fallback = DateTime.now().add(const Duration(minutes: 55));
    final ms = switch (raw) {
      final int v => v,
      final num v => v.toInt(),
      final String v => int.tryParse(v),
      _ => null,
    };
    if (ms == null || ms <= 0) return fallback;
    final parsed = DateTime.fromMillisecondsSinceEpoch(ms);
    return parsed.isAfter(DateTime.now()) ? parsed : fallback;
  }

  /// Doküman: AYLIK-YEMEK-LIST. Ham gövdeyi (`{ "data": [...] }`) döner.
  Future<Map<String, dynamic>> monthlyMenu(int yil, int ay) async {
    final json = await _authorized(
      (token) => _send(
        method: 'GET',
        url:
            '${_trim(AppConfig.menuBaseUrl)}/aylik-yemek-listesi/get-kayit-list',
        stage: '3) aylık menü listesi ($yil/$ay)',
        token: token,
        body: {
          'page': 0,
          'rows': 100,
          'first': 0,
          'sortField': 'id',
          'sortOrder': 0,
          'filters': {
            'yil': {'value': yil, 'type': 'int', 'matchMode': 'equals'},
            'ay': {'value': ay, 'type': 'int', 'matchMode': 'equals'},
          },
        },
      ),
    );
    return json is Map<String, dynamic> ? json : const {};
  }

  /// Doküman: GET-PERSONEL-KARTI-BY-CEP-TEL.
  /// Yanıt: `{ data: { adiSoyadi, personelKartNo }, present }`.
  Future<Map<String, dynamic>> personnelByPhone(String cepTel) async {
    final json = await _authorized(
      (token) => _send(
        method: 'POST',
        url:
            '${_trim(AppConfig.personnelBaseUrl)}/personel/get-personel-karti-by-cep-tel',
        stage: '2) personel kartı sorgusu (cepTel=$cepTel)',
        token: token,
        query: {'cepTel': cepTel},
      ),
    );
    return json is Map<String, dynamic> ? json : const {};
  }

  /// Token ile dener; AUTH hatası gelirse bir kez yenileyip tekrar dener
  /// (doküman: "Exception alınırsa entegre-login ile yeni Bearer token alın").
  Future<dynamic> _authorized(Future<dynamic> Function(String token) call) async {
    var token = await _token$();
    try {
      return await call(token);
    } on HbysException catch (e) {
      if (!e.isAuthError) rethrow;
      token = await _token$(forceRefresh: true);
      return call(token);
    }
  }

  /// Tüm istek adımlarını (bağlantı + gövde okuma) **tek bir toplam süreye**
  /// bağlar. Aksi hâlde sunucu bağlantıyı kabul edip yanıtı hiç bitirmezse
  /// istek sonsuza kadar asılı kalır ve ekranda spinner dönmeye devam eder.
  Future<dynamic> _send({
    required String method,
    required String url,
    Object? body,
    Map<String, dynamic>? query,
    String? token,
    String? stage,
  }) {
    return _sendInner(
      method: method,
      url: url,
      body: body,
      query: query,
      token: token,
      stage: stage,
    ).timeout(
      AppConfig.apiTimeout,
      onTimeout: () => throw HbysException(
        'HBYS isteği zaman aşımına uğradı. Sunucuya ulaşılamıyor olabilir.',
        stage: stage,
        method: method,
        url: url,
        exceptionType:
            'TimeoutException (toplam ${AppConfig.apiTimeout.inSeconds} sn)',
      ),
    );
  }

  Future<dynamic> _sendInner({
    required String method,
    required String url,
    Object? body,
    Map<String, dynamic>? query,
    String? token,
    String? stage,
  }) async {
    var uri = Uri.parse(url);
    if (query != null) {
      uri = uri.replace(
        queryParameters: query.map((k, v) => MapEntry(k, '$v')),
      );
    }

    // Yanıt gövdesi okunabildiyse hata yollarında da elimizde olsun.
    String? rawBody;

    // Kurum içi sertifika: varsa gömülü CA ile doğrula, yoksa HBYS host'ları
    // için doğrulamayı atla (bkz. HbysTrust).
    final client = HttpClient(context: await HbysTrust.context())
      ..connectionTimeout = AppConfig.apiTimeout
      ..badCertificateCallback = HbysTrust.badCertificateCallback;
    try {
      final request = await client.openUrl(method, uri).timeout(AppConfig.apiTimeout);
      request.headers
        ..set(HttpHeaders.acceptHeader, '*/*')
        ..set('Accept-Language', 'tr');
      if (token != null) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      if (body != null) {
        // Doküman aylık-menüyü GET + gövde ile istiyor. dart:io buna izin verir
        // AMA gövdesiz sayılan fiillerde (GET/HEAD) contentLength varsayılan 0
        // olduğu için uzunluğu ELLE bildirmek şarttır; aksi hâlde:
        // "HttpException: content size exceeds specified contentLength".
        final payload = utf8.encode(jsonEncode(body));
        request.headers.contentType = ContentType.json;
        request.contentLength = payload.length;
        request.add(payload);
      }

      final response = await request.close().timeout(AppConfig.apiTimeout);
      // Ham metni ÖNCE al: gövde JSON değilse (proxy HTML'i, boş yanıt, düz
      // metin hata) teşhiste asıl işe yarayan şey tam olarak bu metindir.
      final text = await response.transform(utf8.decoder).join();
      rawBody = text;

      if (response.statusCode < 200 || response.statusCode >= 300) {
        dynamic decodedError;
        try {
          decodedError = text.isEmpty ? null : jsonDecode(text);
        } catch (_) {
          decodedError = null; // JSON değilse ham metinle devam.
        }
        throw _errorFrom(
          response.statusCode,
          decodedError,
          stage: stage,
          method: method,
          url: '$uri',
          rawBody: text,
        );
      }
      return text.isEmpty ? null : jsonDecode(text);
    } on SocketException catch (e) {
      // Saha teşhisi için sebebi AYIR: DNS mi çözülmüyor, yoksa host'a mı
      // ulaşılamıyor? İkisi bambaşka sorunlardır (DNS sunucusu vs. yönlendirme
      // /güvenlik duvarı) ama ikisi de aynı istisnadan gelir.
      final dnsFailure = e.osError == null || e.message.contains('host lookup');
      throw HbysException(
        dnsFailure
            ? 'Sunucu adı çözümlenemedi (${uri.host}). Hastane ağında '
                  'olduğunuzdan emin olun.'
            : 'HBYS sunucusuna ulaşılamadı (${uri.host}): ${e.message}',
        stage: stage,
        method: method,
        url: '$uri',
        exceptionType: 'SocketException'
            '${e.osError != null ? ' (errno ${e.osError!.errorCode})' : ''}',
      );
    } on HandshakeException catch (e) {
      // Kurum içi sertifika zinciri cihaz tarafından tanınmıyorsa buraya düşer;
      // aksi hâlde bu istisna yakalanmadan yukarı kaçardı.
      throw HbysException(
        'HBYS sunucusunun güvenlik sertifikası doğrulanamadı (${uri.host}): '
        '${e.message}',
        stage: stage,
        method: method,
        url: '$uri',
        exceptionType: 'HandshakeException',
      );
    } on TimeoutException {
      throw HbysException(
        'HBYS isteği zaman aşımına uğradı (${uri.host}).',
        stage: stage,
        method: method,
        url: '$uri',
        exceptionType: 'TimeoutException (${AppConfig.apiTimeout.inSeconds} sn)',
      );
    } on FormatException catch (e) {
      // 2xx geldi ama gövde JSON değil → ham metni MUTLAKA taşı; genelde
      // araya giren bir proxy/portal HTML'i olur.
      throw HbysException(
        'HBYS sunucusundan geçersiz yanıt alındı (JSON değil).',
        stage: stage,
        method: method,
        url: '$uri',
        exceptionType: 'FormatException: ${e.message}',
        responseBody: _clip(rawBody),
      );
    } on HbysException {
      rethrow;
    } catch (e) {
      // Beklenmeyen her şey de teşhise dahil olsun; sessizce kaybolmasın.
      throw HbysException(
        'Beklenmeyen hata: $e',
        stage: stage,
        method: method,
        url: '$uri',
        exceptionType: e.runtimeType.toString(),
        responseBody: _clip(rawBody),
      );
    } finally {
      client.close(force: true);
    }
  }

  /// Doküman hata zarfı → [HbysException].
  HbysException _errorFrom(
    int status,
    dynamic body, {
    String? stage,
    String? method,
    String? url,
    String? rawBody,
  }) {
    if (body is Map && body['exception'] is Map) {
      final exception = body['exception'] as Map;
      return HbysException(
        (exception['errorMessage'] as String?) ?? 'HBYS sunucu hatası',
        statusCode: status,
        errorCode: exception['errorCode'] as String?,
        stage: stage,
        method: method,
        url: url,
        responseBody: _clip(rawBody),
      );
    }
    return HbysException(
      'HBYS sunucu hatası ($status)',
      statusCode: status,
      stage: stage,
      method: method,
      url: url,
      responseBody: _clip(rawBody),
    );
  }

  /// Ham gövdeyi ekrana sığacak boyuta indirir.
  static String? _clip(String? raw, [int max = 600]) {
    if (raw == null) return null;
    final t = raw.trim();
    if (t.isEmpty) return '(boş gövde)';
    return t.length <= max ? t : '${t.substring(0, max)}… (${t.length} karakter)';
  }

  static String _trim(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;
}
