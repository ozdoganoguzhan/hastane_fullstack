import 'package:hastane_menu/models/announcement.dart';

/// Kendi REST API'mizin `GET /announcements` yanıtını [Announcement]'a çevirir.
///
/// Yanıt gövdesi: `[ { id, type, title, body, date } ]`
///  - `type`: "important" | "info" | "general"
///  - `date`: ISO 8601 ("2026-04-07T00:00:00")
sealed class AnnouncementDto {
  static List<Announcement> listFromResponse(dynamic json) {
    if (json is! List) return const [];
    return json
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList(growable: false);
  }

  static Announcement fromJson(Map<String, dynamic> json) {
    return Announcement(
      type: _type(json['type']),
      title: (json['title'] as String?)?.trim() ?? '',
      body: (json['body'] as String?)?.trim() ?? '',
      date: _date(json['date']),
    );
  }

  static AnnouncementType _type(dynamic raw) {
    final value = raw is String ? raw.trim().toLowerCase() : '';
    return switch (value) {
      'important' => AnnouncementType.important,
      'general' => AnnouncementType.general,
      _ => AnnouncementType.info,
    };
  }

  static DateTime _date(dynamic raw) {
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw)?.toLocal() ?? DateTime.now();
    }
    return DateTime.now();
  }
}
