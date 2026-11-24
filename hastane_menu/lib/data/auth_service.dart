import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hastane_menu/core/constants/app_config.dart';
import 'package:hastane_menu/core/network/hbys_client.dart';
import 'package:hastane_menu/core/network/sms_client.dart';
import 'package:hastane_menu/models/staff_session.dart';

/// Giriş akışı — **tamamen uygulama içinde** (canlıda aracı API yoktur).
///
/// Akış (Turkcell dokümanına göre):
///  1. [requestOtp] → HBYS'ye entegre-login yapılır (token) ve
///     `get-personel-karti-by-cep-tel` ile **telefon doğrulanır**.
///  2. Personel bulunursa 6 haneli kod üretilir ve 3G Bilişim üzerinden
///     **SMS gönderilir**; personel bilgisi kod ile birlikte bellekte tutulur.
///  3. [verifyOtp] → kod cihazda doğrulanır ve 1. adımda alınan **gerçek**
///     personel bilgisiyle oturum açılır (ikinci HBYS çağrısı gerekmez).
///
/// ⚠️ Kod cihazda üretilip cihazda doğrulandığı için OTP bir güvenlik sınırı
///    DEĞİL, kullanıcı doğrulama akışıdır. Asıl kapılar: HBYS personel
///    doğrulaması + ağ kısıtı (SSID/BSSID — bkz. AGENTS.md §4).
class AuthService {
  AuthService({
    required HbysClient client,
    SmsClient smsClient = const SmsClient(),
  }) : _client = client,
       _sms = smsClient;

  final HbysClient _client;
  final SmsClient _sms;
  final Random _random = Random.secure();

  /// Telefon → bekleyen doğrulama kaydı (yalnızca bellekte).
  final Map<String, _PendingOtp> _pending = {};

  /// Demo girişi için hatalı deneme sayacı (uygulama ömrü boyunca).
  int _demoAttempts = 0;
  static const int _demoMaxAttempts = 5;

  /// Aynı numara için uçuşta olan istekler (çift SMS'i önler).
  final Map<String, Future<void>> _inFlight = {};

  /// 1) Telefonu HBYS'de doğrular, 2) doğruysa kod üretip SMS gönderir.
  ///
  /// ⚠️ Aynı numara için eşzamanlı çağrılar **tek isteği paylaşır**; ayrıca
  /// bekleme süresi SMS gönderilmeden ÖNCE rezerve edilir. Aksi hâlde art arda
  /// gelen iki istek de kontrolü geçip **çift SMS** gönderirdi (kontör yakar).
  Future<void> requestOtp(String phone) {
    final cepTel = _normalize(phone);

    return _inFlight.putIfAbsent(
      cepTel,
      // ⚠️ DİKKAT: Gövde bloklu `{ ... }` OLMALI, `=> _inFlight.remove(...)`
      // DEĞİL. `Map.remove` sildiği değeri (yani bu future'ın kendisini) döner;
      // `whenComplete` callback'i bir Future döndürürse onu BEKLER → future
      // kendini bekler, sonsuza kadar tamamlanmaz (spinner hiç durmaz).
      () => _performRequest(cepTel).whenComplete(() {
        _inFlight.remove(cepTel);
      }),
    );
  }

  Future<void> _performRequest(String cepTel) async {
    _log('[OTP] 1/4 baslatildi → $cepTel');

    // Tekrar gönderim bekleme süresi.
    final existing = _pending[cepTel];
    if (existing != null) {
      final elapsed = DateTime.now().difference(existing.issuedAt);
      if (elapsed < AppConfig.otpResendCooldown) {
        final remaining = AppConfig.otpResendCooldown - elapsed;
        _log('[OTP] ✗ cooldown: ${remaining.inSeconds + 1} sn');
        throw AuthException(
          'Yeni kod için ${remaining.inSeconds + 1} saniye bekleyin.',
        );
      }
    }

    // 1) HBYS: login + telefon doğrulama (personel kartı).
    _log('[OTP] 2/4 HBYS personel sorgusu → ${AppConfig.personnelBaseUrl}');
    final Map<String, dynamic> response;
    try {
      response = await _client.personnelByPhone(cepTel);
      _log('[OTP] 2/4 HBYS yanit: present=${response['present']}');
    } on HbysException catch (e) {
      _log('[OTP] ✗ HBYS hatasi: ${e.message}\n${e.diagnostics}');
      throw AuthException(e.message, diagnostics: e.diagnostics);
    }

    if (response['present'] != true || response['data'] is! Map) {
      // Sunucu cevap VERDİ ama kayıt yok — ham yanıtı göster ki alan adları
      // beklediğimizden farklıysa (present/data) anlaşılsın.
      throw AuthException(
        'Bu telefon numarası sistemde kayıtlı değil.',
        diagnostics:
            'Aşama: 2) personel kartı sorgusu (cepTel=$cepTel)\n'
            'HTTP: 200 (istek başarılı, kayıt bulunamadı)\n'
            'Yanıt: ${_clip(response)}',
      );
    }

    final data = response['data'] as Map;
    final cardNo = (data['personelKartNo'] as String?)?.trim() ?? '';
    final fullName = (data['adiSoyadi'] as String?)?.trim() ?? '';

    if (cardNo.isEmpty) {
      throw AuthException(
        'Personel kart numarası alınamadı.',
        diagnostics:
            'Aşama: 2) personel kartı sorgusu — personelKartNo boş\n'
            'Yanıt: ${_clip(response)}',
      );
    }

    // 2) Kod üret ve kaydı SMS'ten ÖNCE yaz → bekleme süresi anında devreye
    //    girer, ikinci bir istek SMS gönderemez.
    final code = (100000 + _random.nextInt(900000)).toString();

    _pending[cepTel] = _PendingOtp(
      code: code,
      issuedAt: DateTime.now(),
      expiresAt: DateTime.now().add(AppConfig.otpLifetime),
      fullName: fullName.isEmpty ? 'Personel' : fullName,
      cardNo: cardNo,
    );

    // 3) SMS gönder. Başarısızsa kaydı geri al ki kullanıcı hemen tekrar
    //    deneyebilsin (boşuna 60 sn beklemesin).
    _log('[OTP] 3/4 SMS gonderiliyor → ${AppConfig.smsBaseUrl} (kod: $code)');
    final result = await _sms.send(
      cepTel,
      'Kapari Hazir Yemek dogrulama kodunuz: $code',
    );
    _log(
      '[OTP] 4/4 SMS sonuc: success=${result.success} → '
      '${result.detail ?? result.message}',
    );

    if (!result.success) {
      _pending.remove(cepTel);
      throw AuthException(
        result.message,
        diagnostics:
            'Aşama: 4) SMS gönderimi (3G Bilişim)\n'
            'İstek: GET ${AppConfig.smsBaseUrl}/SendSmsGet.aspx\n'
            'origin=${AppConfig.smsOriginator}, to=$cepTel\n'
            'Yanıt: ${result.detail ?? result.message}',
      );
    }
  }

  /// Akış logu — YALNIZCA debug derlemede yazılır.
  ///
  /// ⛔ Bu loglar telefon numarasını ve OTP KODUNU içerir. `debugPrint`
  ///    release'de de logcat'e yazar; mağaza sürümünde kodun log'a düşmemesi
  ///    için `kDebugMode` şartı zorunludur.
  static void _log(String message) {
    if (kDebugMode) debugPrint(message);
  }

  /// Teşhis kutusuna sığacak şekilde kısaltılmış gösterim.
  static String _clip(Object? value, [int max = 400]) {
    final s = '$value';
    return s.length <= max ? s : '${s.substring(0, max)}… (${s.length} karakter)';
  }

  /// Kodu doğrular ve 1. adımda HBYS'den alınan personel bilgisiyle oturum açar.
  Future<StaffSession> verifyOtp({
    required String phone,
    required String code,
  }) async {
    final cepTel = _normalize(phone);
    final pending = _pending[cepTel];

    if (pending == null) {
      throw const AuthException('Önce doğrulama kodu isteyin.');
    }
    if (DateTime.now().isAfter(pending.expiresAt)) {
      _pending.remove(cepTel);
      throw const AuthException('Kodun süresi doldu, yeni kod isteyin.');
    }
    if (pending.attempts >= AppConfig.otpMaxAttempts) {
      _pending.remove(cepTel);
      throw const AuthException('Çok fazla hatalı deneme. Yeni kod isteyin.');
    }
    if (code.trim() != pending.code) {
      pending.attempts++;
      throw const AuthException('Doğrulama kodu hatalı.');
    }

    _pending.remove(cepTel); // tek kullanımlık

    return StaffSession(
      personnelId: pending.cardNo,
      fullName: pending.fullName,
      title: 'Yemekhane Erişimi',
      phone: phone,
      cardNo: pending.cardNo,
    );
  }

  /// Kullanıcı adı + şifre ile **demo** girişi (dummy data; HBYS'ye gitmez).
  ///
  /// ⚠️ Arayüzde **"Yönetici girişi"** olarak sunulur — son kullanıcı "test"
  /// ibaresi görmesin diye. Teknik olarak hâlâ demo oturumudur: `isDemo: true`
  /// döner, `MenuService` gerçek API'yi atlar.
  ///
  /// Hata mesajı bilerek HBYS'ninkinden FARKLIDIR ("Yönetici bilgileri
  /// hatalı"); aynı metin olsaydı sahadan gelen ekran görüntüsünde hatanın
  /// cihazdan mı sunucudan mı geldiği ayırt edilemezdi (bir kez oldu).
  ///
  /// Şifre karşılaştırması sabit süreli yapılır ve hatalı denemeler
  /// [_demoMaxAttempts] ile sınırlanır — mağaza sürümünde bu giriş açık
  /// kaldığı için kaba kuvvet denemesini pahalı hâle getirir.
  Future<StaffSession> loginWithCredentials({
    required String username,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (!AppConfig.demoLoginEnabled) {
      throw const AuthException('Yönetici bilgileri hatalı.');
    }
    if (_demoAttempts >= _demoMaxAttempts) {
      throw const AuthException(
        'Çok fazla hatalı deneme. Uygulamayı kapatıp yeniden açın.',
      );
    }

    final userOk = _constantTimeEquals(
      username.trim().toLowerCase(),
      AppConfig.demoUsername.toLowerCase(),
    );
    final passOk = _constantTimeEquals(password, AppConfig.demoPassword);

    if (userOk && passOk) {
      _demoAttempts = 0;
      return const StaffSession(
        personnelId: 'YONETICI-0001',
        fullName: 'Yönetici',
        title: 'Yönetici Erişimi',
        phone: '0500 000 00 00',
        isDemo: true,
      );
    }

    _demoAttempts++;
    throw const AuthException('Yönetici bilgileri hatalı.');
  }

  /// Karşılaştırma süresinin girilen değere bağlı olmaması için tüm baytlar
  /// her hâlükârda taranır (erken çıkış yok).
  static bool _constantTimeEquals(String a, String b) {
    var diff = a.length ^ b.length;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i % (b.isEmpty ? 1 : b.length));
    }
    return diff == 0;
  }

  /// Doküman: cepTel 10 haneli olmalıdır ("0555 555 55 11" → "5555555511").
  String _normalize(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      throw const AuthException('Geçerli bir telefon numarası girin.');
    }
    return digits.substring(digits.length - 10);
  }
}

/// Bekleyen doğrulama kaydı — kod + HBYS'den alınan gerçek personel bilgisi.
class _PendingOtp {
  _PendingOtp({
    required this.code,
    required this.issuedAt,
    required this.expiresAt,
    required this.fullName,
    required this.cardNo,
  });

  final String code;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final String fullName;
  final String cardNo;
  int attempts = 0;
}

/// Giriş akışı hataları.
class AuthException implements Exception {
  const AuthException(this.message, {this.diagnostics});

  final String message;

  /// "Ne nerede patladı" dökümü (aşama, istek, HTTP kodu, ham yanıt).
  /// Yalnızca `AppConfig.showErrorDiagnostics` açıkken ekrana basılır.
  final String? diagnostics;

  @override
  String toString() => message;
}
