import 'package:flutter_test/flutter_test.dart';
import 'package:hastane_menu/core/network/hbys_trust.dart';

/// Kurum içi sertifika kabulü hangi host'lara uygulanıyor?
///
/// HBYS adresi değiştiğinde en kolay unutulan yer burası: yeni host bu
/// listeye girmezse istek sertifika aşamasında `HandshakeException` ile
/// düşer ve sorun "adres yanlış" sanılır.
void main() {
  group('sertifikası kabul edilen HBYS host\'ları', () {
    test('personel servisinin YENİ host\'u (app.his) kabul ediliyor', () {
      expect(
        HbysTrust.isTrustedHost('api-quality.app.his.eskisehir.yerel'),
        isTrue,
      );
    });

    test('entegre-login host\'u kabul ediliyor', () {
      expect(
        HbysTrust.isTrustedHost('api-legacy.app.external.eskisehir.yerel'),
        isTrue,
      );
    });

    test('menü servisinin YENİ host\'u (app.his) kabul ediliyor', () {
      expect(
        HbysTrust.isTrustedHost('api-thirdparty.app.his.eskisehir.yerel'),
        isTrue,
      );
    });

    test('menünün ESKİ (yanlış) host\'u artık listede DEĞİL', () {
      expect(
        HbysTrust.isTrustedHost('api-thirdparty.app.external.eskisehir.yerel'),
        isFalse,
      );
    });

    test('personelin ESKİ (404 dönen) host\'u artık listede DEĞİL', () {
      expect(
        HbysTrust.isTrustedHost('api-quality.app.external.eskisehir.yerel'),
        isFalse,
      );
    });

    test('ilgisiz host\'ların bozuk sertifikası kabul EDİLMİYOR', () {
      expect(HbysTrust.isTrustedHost('gateway.3gbilisim.com'), isFalse);
      expect(HbysTrust.isTrustedHost('evil.example.com'), isFalse);
    });
  });
}
