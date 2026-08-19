import 'package:flutter/material.dart';
import 'package:hastane_menu/core/constants/app_colors.dart';
import 'package:hastane_menu/core/constants/app_spacing.dart';
import 'package:hastane_menu/core/constants/app_typography.dart';

/// Sayfa başlığı — sol tarafta kırmızı degrade aksan çubuğu, büyük başlık ve
/// opsiyonel alt satır. Tüm sekme sayfalarında ortak kurumsal kimlik sağlar.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: subtitle == null ? 22 : 34,
          decoration: const BoxDecoration(
            gradient: AppColors.redGradient,
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
        ),
        AppSpacing.gapH12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.headingLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: AppTypography.bodySmall),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
