import 'package:hastane_menu/core/network/hbys_client.dart';
import 'package:hastane_menu/core/network/otp_client.dart';
import 'package:hastane_menu/models/staff_session.dart';

/// Giriş akışını yöneten servis.
///
/// İki kaynak konuşur:
///  • **OTP (SMS)** → kendi backend'imiz (3G Bilişim) — Turkcell'de SMS ucu yok.
///  • **Personel kartı** → DOĞRUDAN Turkcell HBYS. Dummy personel verisi yoktur.
class AuthService {
  AuthService({required HbysClient client, OtpClient otpClient = const OtpClient()})
    : _client = client,
      _otp = otpClient;

  final HbysClient _client;
  final OtpClient _otp;

  /// Telefona 6 haneli kod gönderir (backend SMS gönderir).
  Future<void> requestOtp(String phone) async {
    final digits = _digits(phone);
    if (digits.length < 10) {
      throw const AuthException('Geçerli bir telefon numarası girin.');
    }

    try {
      await _otp.requestCode(digits.substring(digits.length - 10));
    } on OtpException catch (e) {
      throw AuthException(e.message);
    }
  }

  /// Kodu backend'de doğrular, ardından **HBYS'den personel kartını** çeker.
  Future<StaffSession> verifyOtp({
    required String phone,
    required String code,
  }) async {
    if (code.length != 6) {
      throw const AuthException('Doğrulama kodu 6 haneli olmalıdır.');
    }

    final digits = _digits(phone);
    if (digits.length < 10) {
      throw const AuthException('Geçerli bir telefon numarası girin.');
    }
    final cepTel = digits.substring(digits.length - 10);

    // 1) SMS kodunu doğrula (kendi backend'imiz).
    try {
      await _otp.verifyCode(cepTel, code);
    } on OtpException catch (e) {
      throw AuthException(e.message);
    }

    // 2) Personel kartını Turkcell HBYS'den çek (doküman: cepTel 10 hane).
    final Map<String, dynamic> response;
    try {
      response = await _client.personnelByPhone(cepTel);
    } on HbysException catch (e) {
      throw AuthException(e.message);
    }

    if (response['present'] != true || response['data'] is! Map) {
      throw const AuthException('Bu numaraya kayıtlı personel bulunamadı.');
    }

    final data = response['data'] as Map;
    final cardNo = (data['personelKartNo'] as String?)?.trim() ?? '';
    final fullName = (data['adiSoyadi'] as String?)?.trim() ?? '';

    if (cardNo.isEmpty) {
      throw const AuthException('Personel kart numarası alınamadı.');
    }

    return StaffSession(
      personnelId: cardNo,
      fullName: fullName.isEmpty ? 'Hastane Personeli' : fullName,
      title: 'Yemekhane Erişimi',
      phone: phone,
      cardNo: cardNo,
    );
  }

  /// Kullanıcı adı + şifre ile **demo** girişi (yalnızca geliştirme/sunum).
  ///
  /// ⚠️ Kalan tek dummy budur: `test` / `12345`. Canlıya çıkarken kaldırılabilir
  /// (giriş ekranındaki "Kullanıcı Adı" sekmesiyle birlikte).
  Future<StaffSession> loginWithCredentials({
    required String username,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (username.trim().toLowerCase() == 'test' && password == '12345') {
      return const StaffSession(
        personnelId: 'DEMO-0001',
        fullName: 'Test Kullanıcısı',
        title: 'Demo Erişimi',
        phone: '0500 000 00 00',
        isDemo: true,
      );
    }
    throw const AuthException('Kullanıcı adı veya şifre hatalı.');
  }

  static String _digits(String value) => value.replaceAll(RegExp(r'\D'), '');
}

/// Giriş akışı hataları.
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
