import 'package:flutter/services.dart';

/// Türkiye cep telefonu girişi için maskeleyici: `532 123 45 67`.
///
/// Neden kendi formatter'ımız var (`LengthLimitingTextInputFormatter` +
/// `digitsOnly` yerine):
///  • Hane sınırını **kendisi** uygular. Bazı Android klavyeleri metni
///    composing bölge olarak gönderdiğinde `LengthLimitingTextInputFormatter`
///    devreye girmeyebiliyor ve alan sınırsız uzayabiliyordu (sahada görüldü).
///  • Yapıştırılan `+90 532 ...`, `0532 ...`, `90532...` gibi biçimleri
///    tek bir kurala indirger: **10 hane, 5 ile başlar.**
///  • İmleci hane sayısına göre taşır; ortadan düzenlemede imleç sıçramaz.
///
/// Alanın önünde sabit `+90` öneki gösterildiği için ülke kodu METNE dahil
/// EDİLMEZ; [digitsOf] her zaman 10 haneli yerel numarayı verir.
class TurkishPhoneInputFormatter extends TextInputFormatter {
  const TurkishPhoneInputFormatter();

  /// Yerel numaranın hane sayısı (5XX XXX XX XX).
  static const int maxDigits = 10;

  /// Gruplama: 3-3-2-2 → "532 123 45 67".
  static const List<int> _groups = [3, 3, 2, 2];

  /// Herhangi bir metinden normalize edilmiş yerel haneleri çıkarır.
  /// `+90 532 123 45 67`, `0532...`, `90532...` → `5321234567`
  static String digitsOf(String text) {
    var digits = text.replaceAll(RegExp(r'\D'), '');

    // Ülke kodu: yalnızca ONSUZ da 10 haneden uzunsa soyulur; aksi hâlde
    // gerçek hanelerin başını kesme riski olurdu.
    if (digits.length > maxDigits && digits.startsWith('90')) {
      digits = digits.substring(2);
    }
    // Şehirler arası "0" öneki.
    while (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (digits.length > maxDigits) digits = digits.substring(0, maxDigits);
    return digits;
  }

  /// `5321234567` → `532 123 45 67`
  static String format(String digits) {
    final buffer = StringBuffer();
    var index = 0;
    for (final size in _groups) {
      if (index >= digits.length) break;
      if (index > 0) buffer.write(' ');
      final end = index + size;
      buffer.write(
        digits.substring(index, end > digits.length ? digits.length : end),
      );
      index = end;
    }
    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = digitsOf(newValue.text);
    final text = format(digits);

    // İmleç: kullanıcının bulunduğu noktaya kadar KAÇ HANE olduğunu say, sonra
    // biçimlenmiş metinde o kadar haneyi geçtiğimiz yere koy. Böylece araya
    // eklenen boşluklar imleci kaydırmaz.
    final cursor = newValue.selection.end.clamp(0, newValue.text.length);
    final digitsBeforeCursor = newValue.text
        .substring(0, cursor)
        .replaceAll(RegExp(r'\D'), '')
        .length;

    var offset = 0;
    var seen = 0;
    while (offset < text.length && seen < digitsBeforeCursor) {
      if (text.codeUnitAt(offset) != 0x20) seen++; // boşluk değilse hane
      offset++;
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
