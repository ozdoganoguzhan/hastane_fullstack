import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Menü servisi "argument "content" is null" döndürdü — bu, Java/Jackson'ın
/// `readValue(null, ...)` hatasıdır: backend'e istek GÖVDESİ ulaşmamış.
///
/// Soru: gövdeyi biz mi göndermiyoruz, yoksa aradaki gateway mi siliyor?
/// Bu test `HbysClient._sendInner`'ın kullandığı dart:io çağrılarının AYNISIYLA
/// (openUrl('GET') + contentType + contentLength + add) yerel bir sunucuya
/// istek atar ve sunucunun gövdeyi alıp almadığına bakar.
void main() {
  test('dart:io GET isteğinde JSON gövdeyi GERÇEKTEN gönderiyor', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    String? receivedMethod;
    String? receivedBody;
    String? receivedLength;

    server.listen((req) async {
      receivedMethod = req.method;
      receivedLength = req.headers.value(HttpHeaders.contentLengthHeader);
      receivedBody = await utf8.decoder.bind(req).join();
      req.response
        ..statusCode = 200
        ..write('{"data":[]}');
      await req.response.close();
    });

    final body = {
      'page': 0,
      'rows': 100,
      'filters': {
        'yil': {'value': 2026, 'type': 'int', 'matchMode': 'equals'},
      },
    };

    // ── HbysClient._sendInner ile birebir aynı adımlar ──
    final client = HttpClient();
    final request = await client.openUrl(
      'GET',
      Uri.parse('http://127.0.0.1:${server.port}/aylik-yemek-listesi/get-kayit-list'),
    );
    final payload = utf8.encode(jsonEncode(body));
    request.headers.contentType = ContentType.json;
    request.contentLength = payload.length;
    request.add(payload);
    final response = await request.close();
    await response.drain<void>();
    client.close(force: true);
    await server.close(force: true);

    expect(receivedMethod, 'GET');
    expect(receivedLength, '${payload.length}');
    expect(receivedBody, jsonEncode(body),
        reason: 'Gövde sunucuya ulaşmadıysa sorun bizde demektir.');
  });
}
