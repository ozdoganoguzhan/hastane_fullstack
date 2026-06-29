import 'package:flutter/material.dart';
import 'package:hastane_menu/core/constants/app_colors.dart';
import 'package:hastane_menu/core/constants/app_spacing.dart';
import 'package:hastane_menu/core/utils/date_utils.dart';
import 'package:hastane_menu/models/announcement.dart';

/// Duyuru kartı — sol renkli kenarlık + tür etiketi + başlık + metin + tarih.
class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({super.key, required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    final type = announcement.type;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppSpacing.shadow,
        border: Border(left: BorderSide(color: type.color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: type.background,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              type.label.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: type.color,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            announcement.title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            announcement.body,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppDateUtils.dayMonthYear(announcement.date),
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
