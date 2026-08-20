import 'package:hastane_menu/core/constants/app_config.dart';

/// Marka + yemekhane bilgisi (Bilgi sayfası).
///
/// ⚠️ Turkcell HBYS dokümanında kurum bilgisi ucu YOKTUR ve yönetici paneli
/// kaldırılmıştır → bu bilgiler tamamen [AppConfig]'ten gelir (tek merkez).
class BrandInfo {
  const BrandInfo({
    required this.brandName,
    required this.subtitle,
    required this.description,
    required this.workingHours,
    required this.location,
    required this.contact,
  });

  final String brandName;
  final String subtitle;
  final String description;
  final String workingHours;
  final String location;
  final String contact;

  /// Config'ten üretilen tek kaynak.
  factory BrandInfo.fromConfig() => const BrandInfo(
    brandName: AppConfig.brandName,
    subtitle: AppConfig.appSubtitle,
    description: AppConfig.cafeteriaDescription,
    workingHours: AppConfig.workingHours,
    location: AppConfig.location,
    contact: AppConfig.contact,
  );
}
