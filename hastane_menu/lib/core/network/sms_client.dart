import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hastane_menu/core/constants/app_config.dart';

/// SMS gönderim sonucu.
class SmsResult {
  const SmsResult._(this.success, this.message, [this.detail]);

  const SmsResult.ok(String message) : this._(true, message);

  /// Başarısız gönderim. Kullanıcıya her zaman sade [failMessage] gösterilir;
  /// gateway'in ham cevabı / istisna ayrıntısı yalnızca [detail]'de kalır.
  const SmsResult.fail(String detail) : this._(false, failMessage, detail);

  /// ⛔ Kullanıcıya giden tek SMS hata metni — gateway yanıtı, HTTP kodu ya da
  ///    "IP whitelist" gibi teknik ipuçları buraya GİRMEZ.
  static const String failMessage =
      'Doğrulama kodu gönderilemedi. Lütfen biraz sonra tekrar deneyin.';

  final bool success;
  final String message;

  /// Teşhis için teknik ayrıntı (yalnızca teşhis dökümünde görünür).
  final String? detail;
}

/// 3G Bilişim SMS gateway istemcisi — **uygulamadan doğrudan** (canlıda aracı
/// API yoktur).
///
/// Tek uç: `SendSmsGet.aspx`. Başarılı yanıt `"ID:<mesaj-id>"` ile başlar;
/// aksi hâlde gateway bir hata kodu döner — bu kod [SmsResult.detail]'e yazılır.
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
      onTimeout: () => SmsResult.fail(
        'Zaman aşımı (${AppConfig.apiTimeout.inSeconds} sn) — IP whitelist / '
        'internet erişimi?',
      ),
    );
  }

  Future<SmsResult> _send(String phoneNumber, String text) async {
    if (!AppConfig.smsEnabled) {
      // Kod ve numara yalnızca debug derlemede loglanır.
      if (kDebugMode) debugPrint('[SMS kapalı] $phoneNumber → $text');
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
        return SmsResult.fail('HTTP ${response.statusCode}: $body');
      }
      if (body.isEmpty) {
        return const SmsResult.fail('Gateway boş yanıt döndü');
      }
      if (body.toUpperCase().startsWith('ID:')) {
        return SmsResult.ok(body.substring(3).trim());
      }

      return SmsResult.fail('Gateway yanıtı: $body');
    } on SocketException catch (e) {
      return SmsResult.fail('SocketException: ${e.message}');
    } on TimeoutException {
      return SmsResult.fail(
        'Zaman aşımı (${AppConfig.apiTimeout.inSeconds} sn)',
      );
    } finally {
      client.close(force: true);
    }
  }

  static String _trim(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;
}
