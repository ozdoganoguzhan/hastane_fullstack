import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hastane_menu/core/constants/app_config.dart';

/// OTP servisinden dönen hata.
class OtpException implements Exception {
  const OtpException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// SMS ile doğrulama (OTP) için **kendi backend'imize** bağlanan ince istemci.
///
/// ⚠️ Turkcell HBYS dokümanında SMS/OTP servisi yoktur; kod üretimi/gönderimi
/// (3G Bilişim gateway) backend'dedir. Menü ve personel kartı ise doğrudan
/// Turkcell'den çekilir (bkz. [AppConfig] ve `hbys_client.dart`).
class OtpClient {
  const OtpClient();

  /// `POST /auth/otp/request` — kod üretip SMS gönderir.
  Future<void> requestCode(String cepTel) =>
      _post('/auth/otp/request', {'cepTel': cepTel});

  /// `POST /auth/otp/verify` — kodu doğrular.
  Future<void> verifyCode(String cepTel, String code) =>
      _post('/auth/otp/verify', {'cepTel': cepTel, 'code': code});

  Future<void> _post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${_trim(AppConfig.otpBaseUrl)}$path');
    final client = HttpClient()..connectionTimeout = AppConfig.apiTimeout;

    try {
      final request = await client.postUrl(uri).timeout(AppConfig.apiTimeout);
      request.headers
        ..set(HttpHeaders.acceptHeader, 'application/json')
        ..set('Accept-Language', 'tr')
        ..contentType = ContentType.json;
      request.add(utf8.encode(jsonEncode(body)));

      final response = await request.close().timeout(AppConfig.apiTimeout);
      final text = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 200 && response.statusCode < 300) return;

      throw OtpException(
        _messageFrom(text) ?? 'Doğrulama servisi hatası (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    } on SocketException catch (e) {
      throw OtpException('Doğrulama servisine ulaşılamadı: ${e.message}');
    } on TimeoutException {
      throw const OtpException('Doğrulama isteği zaman aşımına uğradı.');
    }
  }

  /// Backend hata gövdesi: `{ "message": "..." }`.
  String? _messageFrom(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['message'] is String) {
        return decoded['message'] as String;
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  static String _trim(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;
}
