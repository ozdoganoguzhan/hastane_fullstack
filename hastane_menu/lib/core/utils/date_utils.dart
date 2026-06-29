/// Türkçe tarih formatlama yardımcıları.
///
/// `intl` paketine ihtiyaç duymadan, Türkçe ay/gün isimlerini elle haritalar.
sealed class AppDateUtils {
  static const List<String> _months = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  /// Pazartesi=1 ... Pazar=7 (DateTime.weekday ile aynı indeks).
  static const List<String> _weekdays = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];

  static String monthName(int month) => _months[month - 1];

  static String weekdayName(int weekday) => _weekdays[weekday - 1];

  /// "20 Haziran"
  static String dayMonth(DateTime d) => '${d.day} ${monthName(d.month)}';

  /// "20 Haziran 2026"
  static String dayMonthYear(DateTime d) =>
      '${d.day} ${monthName(d.month)} ${d.year}';

  /// "20 Haziran 2026, Cumartesi"
  static String longDate(DateTime d) =>
      '${dayMonthYear(d)}, ${weekdayName(d.weekday)}';

  /// "Haziran 2026"
  static String monthYear(DateTime d) => '${monthName(d.month)} ${d.year}';

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Verilen tarihin haftasının Pazartesi gününü döner.
  static DateTime startOfWeek(DateTime d) {
    final date = DateTime(d.year, d.month, d.day);
    return date.subtract(Duration(days: date.weekday - 1));
  }
}
