import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hastane_menu/core/constants/app_config.dart';

/// SMS gönderim sonucu.
class SmsResult {
  const SmsResult._(this.success, this.message);

  const SmsResult.ok(String message) : this._(true, message);
  const SmsResult.fail(String message) : this._(false, message);

  final bool success;
  final String message;
}

/// 3G Bilişim SMS gateway istemcisi — **uygulamadan doğrudan** (canlıda aracı
/// API yoktur).
///
/// Tek uç: `SendSmsGet.aspx`. Başarılı yanıt `"ID:<mesaj-id>"` ile başlar;
/// aksi hâlde gateway bir hata kodu döner ve olduğu gibi yüzeye çıkarılır.
///
/// ⚠️ Gateway `Content-Type: charset=ISO-8859-9` (Latin-5) döner. Dart'ta bu
/// codec yoktur; yanıt pratikte ASCII (`ID:...` / hata kodu) olduğu için
/// [latin1] ile güvenle çözülür (bozuk bayta takılmaması için `allowInvalid`).
class SmsClient {
  const SmsClient();

  /// Gönderimi **toplam süreye** bağlar; gateway bağlantıyı kabul edip yanıtı
  /// bitirmezse istek asılı kalmasın (spinner sonsuza dönmesin).
  Future<SmsResult> send(String phoneNumber, String text) {
    return _send(phoneNumber, text).timeout(
      AppConfig.apiTimeout,
      onTimeout: () => const SmsResult.fail(
        'SMS servisi zaman aşımına uğradı (IP whitelist / internet erişimi?).',
      ),
    );
  }

  Future<SmsResult> _send(String phoneNumber, String text) async {
    if (!AppConfig.smsEnabled) {
      debugPrint('[SMS kapalı] $phoneNumber → $text');
      return const SmsResult.ok('SMS gönderimi kapalı (AppConfig.smsEnabled=false).');
    }

    final uri = Uri.parse('${_trim(AppConfig.smsBaseUrl)}/SendSmsGet.aspx').replace(
      queryParameters: {
        'user': AppConfig.smsUsername,
        'password': AppConfig.smsPassword,
        'to': phoneNumber,
        'text': text,
        'origin': AppConfig.smsOriginator,
        'compncode': AppConfig.smsCompanyCode,
      },
    );

    final client = HttpClient()..connectionTimeout = AppConfig.apiTimeout;
    try {
      final request = await client.getUrl(uri).timeout(AppConfig.apiTimeout);
      final response = await request.close().timeout(AppConfig.apiTimeout);

      final bytes = await response.fold<List<int>>(
        <int>[],
        (buffer, chunk) => buffer..addAll(chunk),
      );
      final body = latin1.decode(bytes, allowInvalid: true).trim();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return SmsResult.fail('SMS servisi yanıt vermedi (${response.statusCode}).');
      }
      if (body.isEmpty) {
        return const SmsResult.fail('SMS servisinden boş yanıt alındı.');
      }
      if (body.toUpperCase().startsWith('ID:')) {
        return SmsResult.ok(body.substring(3).trim());
      }

      return SmsResult.fail('SMS gönderilemedi (servis yanıtı: $body).');
    } on SocketException catch (e) {
      return SmsResult.fail('SMS servisine ulaşılamadı: ${e.message}');
    } on TimeoutException {
      return const SmsResult.fail('SMS servisi zaman aşımına uğradı.');
    } finally {
      client.close(force: true);
    }
  }

  static String _trim(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;
}
