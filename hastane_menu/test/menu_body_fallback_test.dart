import 'package:flutter_test/flutter_test.dart';
import 'package:hastane_menu/core/network/hbys_client.dart';

/// "Sunucu filtreyi/gövdeyi almadı" imzası doğru tanınıyor mu?
///
/// Menü isteği bu imzayla düşerse teşhis dökümü "parametre adı yanlış
/// olabilir" diye açıkça yazar. Yanlış tanıma sahada yanlış yönlendirir
/// (ör. 404'ü parametre sorunu sanmak), bu yüzden karar mantığı ayrıca test
/// edilir.
void main() {
  group('filtre/gövde sunucuya ulaşmadı imzası TANINIR', () {
    test('sahada görülen Jackson mesajı — errorMessage içinde', () {
      const e = HbysException('argument "content" is null', statusCode: 555);
      expect(HbysClient.isBodyMissingError(e), isTrue);
    });

    test('Jackson mesajı yalnızca ham gövdede (kaçışlı tırnaklarla)', () {
      const e = HbysException(
        'HBYS sunucu hatası (500)',
        statusCode: 500,
        responseBody:
            '{"httpStatus":555,"exception":{"errorMessage":"argument \\"content\\" is null"}}',
      );
      expect(HbysClient.isBodyMissingError(e), isTrue);
    });

    test('Spring: Required request body is missing', () {
      const e = HbysException(
        'Required request body is missing: public ResponseEntity ...',
        statusCode: 400,
      );
      expect(HbysClient.isBodyMissingError(e), isTrue);
    });
  });

  group('başka hatalar bu imzayla KARIŞTIRILMAZ', () {
    test('kayıt bulunamadı', () {
      const e = HbysException('Kayıt bulunamadı', statusCode: 555);
      expect(HbysClient.isBodyMissingError(e), isFalse);
    });

    test('404 page not found', () {
      const e = HbysException(
        'HBYS sunucu hatası (404)',
        statusCode: 404,
        responseBody: '404 page not found',
      );
      expect(HbysClient.isBodyMissingError(e), isFalse);
    });

    test('405 Method Not Allowed', () {
      const e = HbysException(
        'HBYS sunucu hatası (405)',
        statusCode: 405,
        responseBody:
            '{"type":"about:blank","title":"Method Not Allowed","status":405}',
      );
      expect(HbysClient.isBodyMissingError(e), isFalse);
    });

    test('yetki hatası', () {
      const e = HbysException('Unauthorized', statusCode: 401);
      expect(HbysClient.isBodyMissingError(e), isFalse);
    });

    test('zaman aşımı', () {
      const e = HbysException('HBYS isteği zaman aşımına uğradı.');
      expect(HbysClient.isBodyMissingError(e), isFalse);
    });
  });
}
