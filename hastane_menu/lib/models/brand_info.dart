import 'package:hastane_menu/core/constants/app_config.dart';

/// Yemekhane / hastane bilgisi (Bilgi sayfası).
///
/// ⚠️ Turkcell HBYS dokümanında hastane bilgisi ucu YOKTUR ve yönetici paneli
/// kaldırılmıştır → bu bilgiler tamamen [AppConfig]'ten gelir (tek merkez).
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

  /// Config'ten üretilen tek kaynak.
  factory HospitalInfo.fromConfig() => const HospitalInfo(
    hospitalName: AppConfig.hospitalName,
    subtitle: AppConfig.appSubtitle,
    description: AppConfig.cafeteriaDescription,
    workingHours: AppConfig.workingHours,
    location: AppConfig.location,
    contact: AppConfig.contact,
  );
}
