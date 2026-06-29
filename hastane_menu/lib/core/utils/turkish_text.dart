/// Türkçe-duyarlı metin yardımcıları (intl paketine ihtiyaç duymadan).
///
/// Dart'ın `toLowerCase()`/`toUpperCase()` metotları `I`/`İ`/`ı`/`i` çiftini
/// Türkçe kurallarına göre çevirmez; bu sınıf o eşlemeyi elle yapar. HBYS'den
/// gelen ALL CAPS yemek adlarını ("BEYAZ PEYNİR") okunur başlık biçimine
/// ("Beyaz Peynir") getirmek için kullanılır.
sealed class TurkishText {
  /// Türkçe kurallarıyla küçük harfe çevirir ('I'→'ı', 'İ'→'i').
  static String toLowerTr(String s) {
    final buffer = StringBuffer();
    for (final ch in s.split('')) {
      buffer.write(switch (ch) {
        'I' => 'ı',
        'İ' => 'i',
        _ => ch.toLowerCase(),
      });
    }
    return buffer.toString();
  }

  /// Türkçe kurallarıyla büyük harfe çevirir ('ı'→'I', 'i'→'İ').
  static String toUpperTr(String s) {
    final buffer = StringBuffer();
    for (final ch in s.split('')) {
      buffer.write(switch (ch) {
        'ı' => 'I',
        'i' => 'İ',
        _ => ch.toUpperCase(),
      });
    }
    return buffer.toString();
  }

  /// "BEYAZ PEYNİR" → "Beyaz Peynir" (her kelimenin ilk harfi büyük).
  static String titleCase(String input) {
    final words = input.trim().split(RegExp(r'\s+'));
    return words
        .map((word) {
          if (word.isEmpty) return word;
          final lower = toLowerTr(word);
          return toUpperTr(lower.substring(0, 1)) + lower.substring(1);
        })
        .join(' ');
  }
}
