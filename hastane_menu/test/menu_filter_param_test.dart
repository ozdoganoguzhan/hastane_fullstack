import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hastane_menu/core/constants/app_config.dart';
import 'package:hastane_menu/core/network/hbys_client.dart';

/// Menü filtresi URL'ye Turkcell'in çalışan örneğiyle AYNI biçimde giriyor mu?
///
/// Turkcell teyidi (2026-09): filtre nesnesinin tamamı URL-encode edilip
/// `?filters=` query parametresinde gider, gövde yoktur. Aşağıdaki testler
/// bizim ürettiğimiz adresi onların gönderdiği adresle karşılaştırır.
void main() {
  const menuUrl =
      'https://api-thirdparty.app.his.eskisehir.yerel'
      '/aylik-yemek-listesi/get-kayit-list';

  // Turkcell'in gönderdiği ÇALIŞAN istek, olduğu gibi (ay=1).
  const turkcellOrnegi =
      'http://api-thirdparty.app.his.eskisehir.yerel/aylik-yemek-listesi/get-kayit-list'
      '?filters=%7B%20%20%22page%22%3A%200%2C%20%20%22rows%22%3A%20100%2C%20%20'
      '%22first%22%3A%200%2C%20%20%22sortField%22%3A%20%22id%22%2C%20%20'
      '%22sortOrder%22%3A%200%2C%20%20%22filters%22%3A%20%7B%20%20%22yil%22%3A'
      '%20%7B%20%20%22value%22%3A%202026%2C%20%20%22type%22%3A%20%22int%22%2C'
      '%20%20%22matchMode%22%3A%20%22equals%22%20%20%7D%2C%20%20%22ay%22%3A%20'
      '%7B%20%20%22value%22%3A%201%2C%20%20%22type%22%3A%20%22int%22%2C%20%20'
      '%22matchMode%22%3A%20%22equals%22%20%20%7D%20%20%7D%20%20%7D%20';

  test('varsayılan parametre adı `filters` (çoğul)', () {
    expect(AppConfig.hbysMenuFilterParam, 'filters');
  });

  test('bizim filtre nesnemiz Turkcell örneğindekiyle BİREBİR aynı', () {
    final onlarinki = jsonDecode(
      Uri.parse(turkcellOrnegi).queryParameters['filters']!,
    );
    expect(HbysClient.menuFilter(2026, 1), onlarinki);
  });

  test('adres Turkcell örneğiyle aynı yol + aynı tek parametre', () {
    final bizim = HbysClient.buildUri(menuUrl, HbysClient.menuQuery(2026, 1));
    final onlarin = Uri.parse(turkcellOrnegi);

    expect(bizim.host, onlarin.host);
    expect(bizim.path, onlarin.path);
    expect(bizim.queryParameters.keys, onlarin.queryParameters.keys);
    expect(
      jsonDecode(bizim.queryParameters['filters']!),
      jsonDecode(onlarin.queryParameters['filters']!),
    );
  });

  test('filtre dokümandaki alanların hepsini taşıyor', () {
    final f = HbysClient.menuFilter(2026, 9);
    expect(f['page'], 0);
    expect(f['rows'], 100);
    expect(f['first'], 0);
    expect(f['sortField'], 'id');
    expect(f['sortOrder'], 0);
    expect(f['filters'], {
      'yil': {'value': 2026, 'type': 'int', 'matchMode': 'equals'},
      'ay': {'value': 9, 'type': 'int', 'matchMode': 'equals'},
    });
  });

  test('JSON URL-encode ediliyor (ham { " : karakterleri adreste yok)', () {
    final uri = HbysClient.buildUri(menuUrl, HbysClient.menuQuery(2026, 9));
    final query = uri.toString().split('?').last;
    expect(query, startsWith('filters='));
    expect(query, isNot(contains('{')));
    expect(query, isNot(contains('"')));
    expect(query, isNot(contains(' ')));
  });
}
