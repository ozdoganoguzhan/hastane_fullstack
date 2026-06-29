import 'package:hastane_menu/models/announcement.dart';

/// Örnek (dummy) duyuru verisi. Gerçek uygulamada intranet API'sinden gelir.
sealed class AnnouncementData {
  static final List<Announcement> all = [
    Announcement(
      type: AnnouncementType.important,
      title: 'Ramazan Ayı İftar Menüsü',
      body:
          'Ramazan ayı boyunca iftar menüsü 19:00 - 20:30 saatleri arasında '
          'sunulacaktır. Nöbetçi personel için sahur paketi hazırlanmaktadır.',
      date: DateTime(2026, 4, 7),
    ),
    Announcement(
      type: AnnouncementType.info,
      title: 'Diyabet Dostu Menü Seçeneği',
      body:
          'Diyabet hastaları ve personelimiz için özel düşük glisemik indeksli '
          'menü seçeneği her gün sunulmaktadır.',
      date: DateTime(2026, 4, 5),
    ),
    Announcement(
      type: AnnouncementType.general,
      title: 'Hijyen Denetimi Tamamlandı',
      body:
          'Yemekhanemiz İl Sağlık Müdürlüğü hijyen denetimini tam puan ile '
          'geçmiştir. Gıda güvenliği sertifikamız yenilenmiştir.',
      date: DateTime(2026, 4, 3),
    ),
    Announcement(
      type: AnnouncementType.info,
      title: 'Cuma Balık Menüsü',
      body:
          'Her Cuma günü taze balık menümüz sunulmaktadır. Balık alerjisi olan '
          'personelimiz için alternatif tavuk menüsü mevcuttur.',
      date: DateTime(2026, 4, 1),
    ),
    Announcement(
      type: AnnouncementType.important,
      title: 'Yemekhane Bakım Çalışması',
      body:
          '19-20 Nisan tarihleri arasında yemekhane havalandırma bakımı '
          'yapılacaktır. Bu sürede yemekler paket olarak dağıtılacaktır.',
      date: DateTime(2026, 3, 28),
    ),
    Announcement(
      type: AnnouncementType.general,
      title: 'Personel Memnuniyet Anketi',
      body:
          'Yemekhane hizmet kalitemizi artırmak için memnuniyet anketimize '
          'katılımınızı bekliyoruz.',
      date: DateTime(2026, 3, 25),
    ),
  ];
}
