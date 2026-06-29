import 'package:hastane_menu/core/constants/app_config.dart';

/// Yemekhane / hastane bilgisi (Bilgi sayfası). Panel'den girilir, mobil
/// `GET /hospital-info` ile çeker. Backend yokken [HospitalInfo.fromConfig]
/// AppConfig sabitlerinden üretilir.
class HospitalInfo {
  const HospitalInfo({
    required this.hospitalName,
    required this.subtitle,
    required this.description,
    required this.workingHours,
    required this.location,
    required this.contact,
  });

  final String hospitalName;
  final String subtitle;
  final String description;
  final String workingHours;
  final String location;
  final String contact;

  static const String _defaultDescription =
      'Yemekhanemiz hafta içi her gün personelimize hijyenik ve dengeli '
      'beslenme imkânı sunar. Menüler diyetisyen kontrolünde hazırlanmaktadır.';

  /// Backend yokken (dummy/demo) AppConfig'ten üretilen varsayılan bilgi.
  factory HospitalInfo.fromConfig() => const HospitalInfo(
    hospitalName: AppConfig.hospitalName,
    subtitle: AppConfig.appSubtitle,
    description: _defaultDescription,
    workingHours: AppConfig.workingHours,
    location: AppConfig.location,
    contact: AppConfig.contact,
  );

  /// `GET /hospital-info` yanıtı. Boş alanlar AppConfig varsayılanına düşer.
  factory HospitalInfo.fromJson(Map<String, dynamic> json) {
    String pick(String key, String fallback) {
      final value = json[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : fallback;
    }

    return HospitalInfo(
      hospitalName: pick('hospitalName', AppConfig.hospitalName),
      subtitle: pick('subtitle', AppConfig.appSubtitle),
      description: pick('description', _defaultDescription),
      workingHours: pick('workingHours', AppConfig.workingHours),
      location: pick('location', AppConfig.location),
      contact: pick('contact', AppConfig.contact),
    );
  }
}
