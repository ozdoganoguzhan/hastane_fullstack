import 'package:flutter_test/flutter_test.dart';
import 'package:hastane_menu/core/network/hbys_client.dart';
import 'package:hastane_menu/core/network/sms_client.dart';
import 'package:hastane_menu/data/auth_service.dart';

/// HBYS'ye hiç gitmeyen sahte istemci.
///
/// Gerçek `HbysClient.personnelByPhone` içeride ÖNCE `entegre-login` yapar;
/// login patlarsa hata bu metottan dışarı çıkar. Sahtede de aynı şekilde
/// davranıyoruz: [failWith] verilirse metot o hatayı fırlatır.
class _FakeHbys extends HbysClient {
  _FakeHbys({this.failWith, this.response});

  final HbysException? failWith;
  final Map<String, dynamic>? response;

  /// Hangi numaraların sorulduğunu kaydeder.
  final List<String> askedFor = [];

  @override
  Future<Map<String, dynamic>> personnelByPhone(String cepTel) async {
    askedFor.add(cepTel);
    if (failWith != null) throw failWith!;
    return response ?? const {};
  }
}

/// SMS gönderilip gönderilmediğini izleyen sahte gönderici.
class _SpySms implements SmsClient {
  int sendCount = 0;

  @override
  Future<SmsResult> send(String phoneNumber, String text) async {
    sendCount++;
    return const SmsResult.ok('sahte');
  }
}

void main() {
  group('requestOtp — HBYS servis hesabı reddedildiğinde', () {
    // Sahadaki durum: entegre-login "Kullanıcı adı veya şifre hatalı" dönüyor.
    // Bu KULLANICININ değil, entegrasyon hesabının bilgisidir.
    final serverError = const HbysException(
      'Kullanıcı adı veya şifre hatalı.',
      statusCode: 400,
    );

    test('hata kullanıcıya iletilir ve SMS GÖNDERİLMEZ', () async {
      final sms = _SpySms();
      final auth = AuthService(
        client: _FakeHbys(failWith: serverError),
        smsClient: sms,
      );

      await expectLater(
        () => auth.requestOtp('5551234567'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('Kullanıcı adı veya şifre hatalı'),
          ),
        ),
      );
      expect(sms.sendCount, 0, reason: 'HBYS patladıysa kontör yakılmamalı');
    });

    test(
      'HASTANE PERSONELİNİN numarası da AYNI hatayı alır — '
      'çünkü login, personel sorgusundan ÖNCE çalışır',
      () async {
        final client = _FakeHbys(failWith: serverError);
        final auth = AuthService(client: client, smsClient: _SpySms());

        // Kayıtlı olsun ya da olmasın, ikisi de aynı noktada patlar.
        for (final phone in ['5551234567', '5327654321']) {
          await expectLater(
            () => auth.requestOtp(phone),
            throwsA(isA<AuthException>()),
          );
        }
        // Numaraların "kayıtlı mı" diye bakılmasına bile sıra gelmedi:
        // sorgu çağrıldı ama içeride login aşamasında düştü.
        expect(client.askedFor.length, 2);
      },
    );
  });

  group('requestOtp — numara kayıtlı değilse', () {
    test('mesaj telefonun kayıtsız olduğunu söyler', () async {
      final sms = _SpySms();
      final auth = AuthService(
        client: _FakeHbys(response: const {'present': false}),
        smsClient: sms,
      );

      await expectLater(
        () => auth.requestOtp('5551234567'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Bu telefon numarası sistemde kayıtlı değil.',
          ),
        ),
      );
      expect(sms.sendCount, 0);
    });
  });

  group('teşhis dökümü', () {
    test('HbysException tüm alanları okunur bir bloğa dizer', () {
      const e = HbysException(
        'Kullanıcı adı veya şifre hatalı.',
        statusCode: 400,
        errorCode: 'AUTH-001',
        stage: '1) entegre-login (servis hesabı)',
        method: 'POST',
        url: 'https://api-legacy.app.external.eskisehir.yerel/auth/entegre-login',
        responseBody: '{"exception":{"errorMessage":"..."}}',
        exceptionType: null,
      );

      final d = e.diagnostics;
      expect(d, contains('Aşama: 1) entegre-login'));
      expect(d, contains('İstek: POST https://api-legacy'));
      expect(d, contains('HTTP: 400'));
      expect(d, contains('errorCode: AUTH-001'));
      expect(d, contains('Yanıt: {"exception"'));
    });

    test('boş alanlar dökümde yer KAPLAMAZ', () {
      const e = HbysException('bir hata', stage: 'X', responseBody: '   ');
      expect(e.diagnostics, contains('Aşama: X'));
      expect(e.diagnostics, isNot(contains('HTTP')));
      expect(e.diagnostics, isNot(contains('Yanıt')));
    });

    test('AuthService dökümü kullanıcı katmanına taşır', () async {
      final auth = AuthService(
        client: _FakeHbys(
          failWith: const HbysException(
            'sunucu hatasi',
            statusCode: 500,
            stage: '1) entegre-login (servis hesabı)',
            url: 'https://ornek/auth/entegre-login',
            responseBody: '<html>proxy</html>',
          ),
        ),
        smsClient: _SpySms(),
      );

      await expectLater(
        () => auth.requestOtp('5551234567'),
        throwsA(
          isA<AuthException>()
              .having((e) => e.diagnostics, 'diagnostics', contains('HTTP: 500'))
              .having(
                (e) => e.diagnostics,
                'diagnostics',
                contains('<html>proxy</html>'),
              ),
        ),
      );
    });

    test('numara kayıtlı değilse ham yanıt dökümde görünür', () async {
      final auth = AuthService(
        client: _FakeHbys(response: const {'present': false, 'data': null}),
        smsClient: _SpySms(),
      );

      await expectLater(
        () => auth.requestOtp('5551234567'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.diagnostics,
            'diagnostics',
            allOf(contains('HTTP: 200'), contains('present: false')),
          ),
        ),
      );
    });
  });

  group('yönetici girişi', () {
    test('hata metni HBYS mesajından FARKLI olmalı', () async {
      final auth = AuthService(client: _FakeHbys(), smsClient: _SpySms());

      await expectLater(
        () => auth.loginWithCredentials(username: 'yanlis', password: 'yanlis'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Yönetici bilgileri hatalı.',
          ),
        ),
      );
    });
  });
}
