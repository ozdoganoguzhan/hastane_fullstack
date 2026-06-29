import 'package:hastane_menu/core/network/api_client.dart';
import 'package:hastane_menu/data/announcement_data.dart';
import 'package:hastane_menu/data/dto/announcement_dto.dart';
import 'package:hastane_menu/models/announcement.dart';

/// Duyuru kaynağı sözleşmesi. UI kaynağı (dummy/remote) bilmez; [AnnouncementService]
/// üzerinden erişilir (menü deseninin aynısı — bkz. menu_repository.dart).
abstract interface class AnnouncementRepository {
  Future<List<Announcement>> all();
}

/// Backend hazır olana kadar / demo oturumda kullanılan dummy kaynak.
class DummyAnnouncementRepository implements AnnouncementRepository {
  const DummyAnnouncementRepository();

  @override
  Future<List<Announcement>> all() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return AnnouncementData.all;
  }
}

/// Kendi REST API'mizden (`GET /announcements`) yayınlanmış duyuruları çeker.
class RemoteAnnouncementRepository implements AnnouncementRepository {
  RemoteAnnouncementRepository({ApiClient? client})
    : _client = client ?? ApiClient();

  final ApiClient _client;

  @override
  Future<List<Announcement>> all() async {
    final json = await _client.getJson('/announcements');
    return AnnouncementDto.listFromResponse(json);
  }
}
