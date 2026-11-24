import 'package:flutter_test/flutter_test.dart';
import 'package:hastane_menu/core/network/hbys_client.dart';
import 'package:hastane_menu/core/network/sms_client.dart';

/// Mağaza sürümünde kullanıcı teknik ayrıntı GÖRMEMELİ.
///
/// Sahada hata metinlerinde host adları, HTTP kodları, "HBYS" ve
/// `argument "content" is null` gibi ham sunucu mesajları görünüyordu. Bu
/// testler, kullanıcıya giden [HbysException.message] ve [SmsResult.message]
/// alanlarının sade kaldığını, teknik bilginin ise teşhis alanlarında
/// korunduğunu doğrular.
void main() {
  /// Kullanıcı metninde asla geçmemesi gerekenler.
  const forbidden = [
    'HBYS',
    'eskisehir.yerel',
    'content',
    'null',
    'Exception',
    'HTTP',
    '555',
    '404',
    'whitelist',
    'errno',
  ];

  void expectClean(String userText) {
    for (final word in forbidden) {
      expect(
        userText.toLowerCase().contains(word.toLowerCase()),
        isFalse,
        reason: 'Kullanıcı metninde "$word" geçmemeli: "$userText"',
      );
    }
  }

  group('HBYS sunucu hataları', () {
    test('ham sunucu mesajı kullanıcıya GİTMEZ, teşhiste KALIR', () {
      final e = HbysClient.errorFrom(
        555,
        {
          'httpStatus': 555,
          'exception': {
            'errorCode': '----',
            'errorMessage': 'argument "content" is null',
          },
        },
        stage: '3) aylık menü listesi',
        method: 'GET',
        url: 'https://api-thirdparty.app.his.eskisehir.yerel/aylik-yemek-listesi/get-kayit-list',
        rawBody: '{"exception":{"errorMessage":"argument \\"content\\" is null"}}',
      );

      expect(e.message, HbysMessages.unavailable);
      expectClean(e.message);

      expect(e.serverMessage, 'argument "content" is null');
      expect(e.statusCode, 555);
      expect(e.diagnostics, contains('Sunucu mesajı: argument "content" is null'));
      expect(e.diagnostics, contains('eskisehir.yerel'));
    });

    test('düz metin hata gövdesi (404 page not found) kullanıcıya GİTMEZ', () {
      final e = HbysClient.errorFrom(404, null, rawBody: '404 page not found');
      expectClean(e.message);
      expect(e.responseBody, '404 page not found');
    });

    test('gövde-yok imzası sade mesajla da tanınıyor', () {
      final e = HbysClient.errorFrom(
        555,
        {
          'exception': {'errorMessage': 'argument "content" is null'},
        },
      );
      expect(HbysClient.isBodyMissingError(e), isTrue);
    });

    test('tüm hazır kullanıcı metinleri sade', () {
      for (final text in [
        HbysMessages.network,
        HbysMessages.secureConnection,
        HbysMessages.timeout,
        HbysMessages.unavailable,
        HbysMessages.serviceLogin,
      ]) {
        expectClean(text);
      }
    });
  });

  group('"Kayıt bulunamadı" hata değil, boş sonuç sayılır', () {
    test('sunucu "Kayıt bulunamadı" dediyse tanınır', () {
      final e = HbysClient.errorFrom(555, {
        'exception': {'errorCode': '----', 'errorMessage': 'Kayıt bulunamadı'},
      });
      expect(HbysClient.isNotFoundError(e), isTrue);
    });

    test('büyük harf / Türkçe karaktersiz varyant da tanınır', () {
      final e = HbysClient.errorFrom(555, {
        'exception': {'errorMessage': 'KAYIT BULUNAMADI'},
      });
      expect(HbysClient.isNotFoundError(e), isTrue);
    });

    test('başka hatalar boş sonuç SAYILMAZ', () {
      final auth = HbysClient.errorFrom(555, {
        'exception': {'errorCode': 'AUTH-101', 'errorMessage': 'Kullanıcı bulunamadı'},
      });
      expect(HbysClient.isNotFoundError(auth), isFalse);

      const network = HbysException(HbysMessages.network);
      expect(HbysClient.isNotFoundError(network), isFalse);
    });
  });

  group('SMS', () {
    test('gateway ayrıntısı kullanıcıya GİTMEZ, detail\'de KALIR', () {
      const r = SmsResult.fail('HTTP 500: ERR-12 IP whitelist');
      expect(r.success, isFalse);
      expect(r.message, SmsResult.failMessage);
      expectClean(r.message);
      expect(r.detail, contains('IP whitelist'));
    });
  });
}
