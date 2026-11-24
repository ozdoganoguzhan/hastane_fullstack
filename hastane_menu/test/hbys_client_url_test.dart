import 'package:flutter_test/flutter_test.dart';
import 'package:hastane_menu/core/constants/app_config.dart';
import 'package:hastane_menu/core/network/hbys_client.dart';

/// "404 page not found" hatası bizden mi kaynaklanıyor?
///
/// Bu dosya, uygulamanın ÜRETTİĞİ adresi Turkcell dokümanı v1.0'daki adresle
/// birebir karşılaştırır. Geçiyorsa istemci tarafında yanlış bir şey yok;
/// 404 karşı taraftaki yönlendiriciden geliyor demektir.
void main() {
  // GET-PERSONEL-KARTI-BY-CEP-TEL — Turkcell'in 2026-09'da DÜZELTTİĞİ canlı
  // adres. Doküman v1.0'daki `app.external` host'u 404 dönüyordu; doğrusu
  // `app.his`. (Aynen: "(POST) https://api-quality.app.his.eskisehir.yerel
  // /personel/get-personel-karti-by-cep-tel?cepTel=XXXXXXXXXX, Bearer Token ile")
  const dokumandakiPersonelUrl =
      'https://api-quality.app.his.eskisehir.yerel'
      '/personel/get-personel-karti-by-cep-tel?cepTel=5555555511';

  // AYLIK-YEMEK-LIST — Turkcell'in 2026-09'da DÜZELTTİĞİ canlı adres
  // (doküman v1.0'daki `app.external` yanlıştı). Aynen:
  // "GET https://api-thirdparty.app.his.eskisehir.yerel/aylik-yemek-listesi/get-kayit-list"
  const dokumandakiMenuUrl =
      'https://api-thirdparty.app.his.eskisehir.yerel'
      '/aylik-yemek-listesi/get-kayit-list';

  // Doküman v1.0, ENTEGRE-LOGIN bölümü, CANLI satırı:
  const dokumandakiLoginUrl =
      'https://api-legacy.app.external.eskisehir.yerel/auth/entegre-login';

  group('üretilen adres dokümanla aynı mı?', () {
    test('personel kartı sorgusu — cepTel query dahil BİREBİR', () {
      final uri = HbysClient.buildUri(
        '${AppConfig.hbysPersonnelBaseUrl}/personel/get-personel-karti-by-cep-tel',
        {'cepTel': '5555555511'},
      );
      expect(uri.toString(), dokumandakiPersonelUrl);
    });

    test('aylık menü listesi', () {
      final uri = HbysClient.buildUri(
        '${AppConfig.hbysMenuBaseUrl}/aylik-yemek-listesi/get-kayit-list',
      );
      expect(uri.toString(), dokumandakiMenuUrl);
    });

    test('entegre-login', () {
      final uri = HbysClient.buildUri(
        '${AppConfig.hbysAuthBaseUrl}/auth/entegre-login',
      );
      expect(uri.toString(), dokumandakiLoginUrl);
    });
  });

  group('adres kurulumunda sürpriz var mı?', () {
    test('yolun sonuna slash EKLENMİYOR', () {
      final uri = HbysClient.buildUri(
        'https://ornek/personel/get-personel-karti-by-cep-tel',
        {'cepTel': '5321234567'},
      );
      expect(uri.path, '/personel/get-personel-karti-by-cep-tel');
      expect(uri.path.endsWith('/'), isFalse);
    });

    test('telefon numarası kodlanmadan, düz geçiyor', () {
      final uri = HbysClient.buildUri(
        'https://ornek/personel/get-personel-karti-by-cep-tel',
        {'cepTel': '5321234567'},
      );
      expect(uri.query, 'cepTel=5321234567');
      expect(uri.queryParameters['cepTel'], '5321234567');
    });

    test('çift slash oluşmuyor', () {
      final uri = HbysClient.buildUri('https://ornek/auth/entegre-login');
      expect(uri.toString(), isNot(contains('//auth')));
      expect(uri.toString(), 'https://ornek/auth/entegre-login');
    });

    test('query yoksa adrese ? eklenmiyor', () {
      final uri = HbysClient.buildUri('https://ornek/aylik-yemek-listesi/get-kayit-list');
      expect(uri.toString(), isNot(contains('?')));
    });
  });
}
