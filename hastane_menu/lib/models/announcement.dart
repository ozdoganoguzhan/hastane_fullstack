import 'package:flutter/material.dart';
import 'package:hastane_menu/core/constants/app_colors.dart';

/// Duyuru türü — etiket metni ve renkleri taşır.
enum AnnouncementType {
  important('Önemli', AppColors.red, AppColors.errorLight),
  info('Bilgi', AppColors.blue, AppColors.infoLight),
  general('Genel', AppColors.success, AppColors.successLight);

  const AnnouncementType(this.label, this.color, this.background);

  final String label;
  final Color color;
  final Color background;
}

/// Tek bir duyuru.
class Announcement {
  const Announcement({
    required this.type,
    required this.title,
    required this.body,
    required this.date,
  });

  final AnnouncementType type;
  final String title;
  final String body;
  final DateTime date;
}
