import 'package:flutter_test/flutter_test.dart';

import 'package:hastane_menu/core/network/wifi_guard.dart';

void main() {
  group('WifiGuard.normalizeMac', () {
    test('Android biçimi (2 haneli oktetler) aynen birleşir', () {
      expect(WifiGuard.normalizeMac('04:ca:ed:11:22:33'), '04caed112233');
      expect(WifiGuard.normalizeMac('04-CA-ED-11-22-33'), '04caed112233');
    });

    test('iOS baştaki sıfırları yutar → oktetler 2 haneye tamamlanır', () {
      expect(WifiGuard.normalizeMac('4:ca:ed:1:2:33'), '04caed010233');
      expect(WifiGuard.normalizeMac('0:0:0:0:0:0'), '000000000000');
    });

    test('ayırıcısız önek (AppConfig.allowedBssidPrefixes) değişmez', () {
      expect(WifiGuard.normalizeMac('04caed'), '04caed');
      expect(WifiGuard.normalizeMac('EC819C'), 'ec819c');
    });

    test('iOS biçimli BSSID izinli önekle eşleşir', () {
      final bssid = WifiGuard.normalizeMac('4:ca:ed:a:b:c')!;
      expect(bssid.length, 12);
      expect(bssid.startsWith(WifiGuard.normalizeMac('04caed')!), isTrue);
    });

    test('boş / null → null', () {
      expect(WifiGuard.normalizeMac(null), isNull);
      expect(WifiGuard.normalizeMac(''), isNull);
      expect(WifiGuard.normalizeMac('::'), isNull);
    });
  });
}
