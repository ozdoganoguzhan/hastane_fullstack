import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hastane_menu/core/constants/app_config.dart';

/// API çağrısı başarısız olduğunda fırlatılır.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.errorCode});

  final String message;
  final int? statusCode;
  final String? errorCode;

  @override
  String toString() =>
      'ApiException(${statusCode ?? '-'}'
      '${errorCode != null ? ' / $errorCode' : ''}): $message';
}

/// Kendi REST API'mize JSON istek atan ince istemci.
///
/// `dart:io` `HttpClient` kullanır — ek bağımlılık yoktur (AGENTS.md §2 notu).
/// Taban adres [AppConfig.apiBaseUrl]'dir; Bearer token opsiyoneldir (menü
/// servisleri token ister — bkz. §15). Hata gövdesi HBYS zarfıyla
/// (`{ exception: { errorCode, errorMessage } }`) uyumlu ayrıştırılır.
class ApiClient {
  ApiClient({String? baseUrl, Duration? timeout})
    : _baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
      _timeout = timeout ?? AppConfig.apiTimeout;

  final String _baseUrl;
  final Duration _timeout;

  Future<dynamic> getJson(
    String path, {
    Map<String, dynamic>? query,
    String? token,
  }) => _send('GET', path, query: query, token: token);

  Future<dynamic> postJson(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    String? token,
  }) => _send('POST', path, body: body, query: query, token: token);

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    String? token,
  }) async {
    final uri = _buildUri(path, query);
    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final request = await client.openUrl(method, uri).timeout(_timeout);
      request.headers
        ..set(HttpHeaders.acceptHeader, 'application/json, */*')
        ..set('Accept-Language', 'tr');
      if (token != null && token.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.add(utf8.encode(jsonEncode(body)));
      }

      final response = await request.close().timeout(_timeout);
      final text = await response.transform(utf8.decoder).join();
      final decoded = text.isEmpty ? null : jsonDecode(text);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _errorFrom(response.statusCode, decoded);
      }
      return decoded;
    } on SocketException catch (e) {
      throw ApiException('Sunucuya ulaşılamadı: ${e.message}');
    } on TimeoutException {
      throw const ApiException('İstek zaman aşımına uğradı.');
    } on FormatException {
      throw const ApiException('Sunucudan geçersiz yanıt alındı.');
    } finally {
      client.close(force: true);
    }
  }

  Uri _buildUri(String path, Map<String, dynamic>? query) {
    final base = Uri.parse(_baseUrl);
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return base.replace(
      path: '${base.path}$normalizedPath'.replaceAll('//', '/'),
      queryParameters: query?.map((key, value) => MapEntry(key, '$value')),
    );
  }

  /// HBYS hata zarfı: `{ httpStatus, exception: { errorCode, errorMessage } }`.
  ApiException _errorFrom(int status, dynamic body) {
    if (body is Map && body['exception'] is Map) {
      final exception = body['exception'] as Map;
      return ApiException(
        (exception['errorMessage'] as String?) ?? 'Sunucu hatası',
        statusCode: status,
        errorCode: exception['errorCode'] as String?,
      );
    }
    return ApiException('Sunucu hatası ($status)', statusCode: status);
  }
}
