import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hastane_menu/core/constants/app_config.dart';

/// HBYS çağrısı başarısız olduğunda fırlatılır.
///
/// Doküman hata zarfı: `{ httpStatus, exception: { errorCode, errorMessage } }`.
class HbysException implements Exception {
  const HbysException(this.message, {this.statusCode, this.errorCode});

  final String message;
  final int? statusCode;
  final String? errorCode;

  /// Token/oturum kaynaklı mı? (doküman: exception alınırsa yeniden login).
  bool get isAuthError =>
      statusCode == 401 ||
      statusCode == 403 ||
      (errorCode?.toUpperCase().startsWith('AUTH') ?? false);

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
  Future<String> _login() async {
    final json = await _send(
      method: 'POST',
      url: '${_trim(AppConfig.authBaseUrl)}/auth/entegre-login',
      body: {
        'username': AppConfig.hbysUsername,
        'password': AppConfig.hbysPassword,
        'organizationId': AppConfig.hbysOrganizationId,
      },
    );

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

  Future<dynamic> _send({
    required String method,
    required String url,
    Object? body,
    Map<String, dynamic>? query,
    String? token,
  }) async {
    var uri = Uri.parse(url);
    if (query != null) {
      uri = uri.replace(
        queryParameters: query.map((k, v) => MapEntry(k, '$v')),
      );
    }

    final client = HttpClient()..connectionTimeout = AppConfig.apiTimeout;
    try {
      final request = await client.openUrl(method, uri).timeout(AppConfig.apiTimeout);
      request.headers
        ..set(HttpHeaders.acceptHeader, '*/*')
        ..set('Accept-Language', 'tr');
      if (token != null) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      if (body != null) {
        // NOT: Doküman aylık-menü için GET + gövde kullanıyor; dart:io buna izin verir.
        request.headers.contentType = ContentType.json;
        request.add(utf8.encode(jsonEncode(body)));
      }

      final response = await request.close().timeout(AppConfig.apiTimeout);
      final text = await response.transform(utf8.decoder).join();
      final decoded = text.isEmpty ? null : jsonDecode(text);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _errorFrom(response.statusCode, decoded);
      }
      return decoded;
    } on SocketException catch (e) {
      throw HbysException('HBYS sunucusuna ulaşılamadı: ${e.message}');
    } on TimeoutException {
      throw const HbysException('HBYS isteği zaman aşımına uğradı.');
    } on FormatException {
      throw const HbysException('HBYS sunucusundan geçersiz yanıt alındı.');
    } finally {
      client.close(force: true);
    }
  }

  /// Doküman hata zarfı → [HbysException].
  HbysException _errorFrom(int status, dynamic body) {
    if (body is Map && body['exception'] is Map) {
      final exception = body['exception'] as Map;
      return HbysException(
        (exception['errorMessage'] as String?) ?? 'HBYS sunucu hatası',
        statusCode: status,
        errorCode: exception['errorCode'] as String?,
      );
    }
    return HbysException('HBYS sunucu hatası ($status)', statusCode: status);
  }

  static String _trim(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;
}
