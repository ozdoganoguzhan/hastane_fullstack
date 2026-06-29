/// Giriş yapan personelin oturum bilgisi.
///
/// Gerçek uygulamada bu veriler 2FA doğrulaması sonrası intranet API'sinden
/// döner. [personnelId] QR kodunda gösterilen benzersiz personel kimliğidir.
class StaffSession {
  const StaffSession({
    required this.personnelId,
    required this.fullName,
    required this.title,
    required this.phone,
    this.cardNo,
    this.isDemo = false,
  });

  /// Personel kimliği (API'den gelir).
  final String personnelId;
  final String fullName;
  final String title;
  final String phone;

  /// HBYS personel kart numarası (`personelKartNo`) — yemekhane girişinde
  /// okutulan QR'ın değeridir. Telefon ile girişte personel kartı servisinden
  /// gelir (§15). Yoksa [personnelId]'ye düşülür.
  final String? cardNo;

  /// QR koduna gömülecek değer.
  String get qrData =>
      (cardNo != null && cardNo!.isNotEmpty) ? cardNo! : personnelId;

  /// `true` ise oturum kullanıcı adı/şifre ile açılan **demo** oturumudur;
  /// gerçek API'ye bağlanılmaz, tüm veriler `lib/data/` dummy kaynaklarından
  /// gelir. Gerçek API entegrasyonunda bu bayrağa bakılarak demo akışı korunur.
  final bool isDemo;

  /// "0500 *** ** 12" gibi maskelenmiş telefon.
  String get maskedPhone {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return phone;
    final last2 = digits.substring(digits.length - 2);
    final first = digits.substring(0, digits.length >= 4 ? 4 : digits.length);
    return '$first *** ** $last2';
  }
}
