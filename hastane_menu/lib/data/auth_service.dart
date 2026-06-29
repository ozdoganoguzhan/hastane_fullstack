import 'package:hastane_menu/models/staff_session.dart';

/// 2FA giriş akışını yöneten servis.
///
/// ⚠️ ŞİMDİLİK DUMMY: gerçek SMS/OTP servisi ve personel API'si bağlanmadı.
/// Akış netleştiğinde [requestOtp] gerçek SMS gönderimine, [verifyOtp] gerçek
/// doğrulama + personel-bilgisi çekme endpoint'ine bağlanacaktır.
class AuthService {
  /// Telefona 6 haneli kod gönderir (dummy: sadece bekler).
  Future<void> requestOtp(String phone) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      throw const AuthException('Geçerli bir telefon numarası girin.');
    }
    // TODO: gerçek SMS servisini çağır.
  }

  /// Kodu doğrular ve personel oturumunu döner (dummy: 6 hane kabul eder).
  Future<StaffSession> verifyOtp({
    required String phone,
    required String code,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (code.length != 6) {
      throw const AuthException('Doğrulama kodu 6 haneli olmalıdır.');
    }
    // TODO: gerçek doğrulama API'sini çağır; personel bilgisi response'tan gelsin.
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final suffix = digits.substring(digits.length - 6);
    // TODO(§15): personel kartı servisinden (get-personel-karti-by-cep-tel)
    // adiSoyadi + personelKartNo (cardNo) gelsin — sabit string DEĞİL.
    return StaffSession(
      personnelId: 'ESH-PER-$suffix',
      fullName: 'Hastane Personeli',
      title: 'Yemekhane Erişimi',
      phone: phone,
      cardNo: '90$suffix',
    );
  }

  /// Kullanıcı adı + şifre ile **demo** girişi.
  ///
  /// ⚠️ DUMMY: yalnızca `test` / `12345` kabul edilir. Başarılı olursa
  /// [StaffSession.isDemo] `true` olan bir oturum döner — bu oturumda gerçek
  /// API'ye gidilmez, tüm içerik `lib/data/` dummy kaynaklarından gösterilir.
  /// Gerçek API geldiğinde bu metot personel kimlik-doğrulama endpoint'ine
  /// bağlanır (demo kullanıcı yalnızca geliştirme için tutulabilir).
  Future<StaffSession> loginWithCredentials({
    required String username,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
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
}

/// Giriş akışı hataları.
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
