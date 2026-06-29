import 'package:hastane_menu/core/network/api_client.dart';
import 'package:hastane_menu/models/hospital_info.dart';

/// Hastane bilgisi kaynağı sözleşmesi. [HospitalInfoService] üzerinden erişilir.
abstract interface class HospitalInfoRepository {
  Future<HospitalInfo> get();
}

/// Backend hazır olana kadar / demo oturumda kullanılan dummy kaynak (AppConfig).
class DummyHospitalInfoRepository implements HospitalInfoRepository {
  const DummyHospitalInfoRepository();

  @override
  Future<HospitalInfo> get() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return HospitalInfo.fromConfig();
  }
}

/// Kendi REST API'mizden (`GET /hospital-info`) hastane bilgisini çeker.
class RemoteHospitalInfoRepository implements HospitalInfoRepository {
  RemoteHospitalInfoRepository({ApiClient? client})
    : _client = client ?? ApiClient();

  final ApiClient _client;

  @override
  Future<HospitalInfo> get() async {
    final json = await _client.getJson('/hospital-info');
    if (json is Map<String, dynamic>) return HospitalInfo.fromJson(json);
    return HospitalInfo.fromConfig();
  }
}
