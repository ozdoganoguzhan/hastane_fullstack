import 'package:flutter/material.dart';
import 'package:hastane_menu/core/constants/app_colors.dart';
import 'package:hastane_menu/core/constants/app_config.dart';
import 'package:hastane_menu/core/constants/app_spacing.dart';
import 'package:hastane_menu/core/utils/date_utils.dart';

/// Kırmızı degrade üst başlık — kurum adı + bugünün tarihi.
class AppHeader extends StatelessWidget {
  const AppHeader({super.key, this.date});

  /// Gösterilecek tarih (varsayılan: bugün).
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final today = date ?? DateTime.now();
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.redGradient),
        child: Stack(
          children: [
            Positioned(top: -70, right: -40, child: _circle(220, 0.06)),
            Positioned(bottom: -60, left: -30, child: _circle(170, 0.05)),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.base,
                MediaQuery.of(context).padding.top + AppSpacing.base,
                AppSpacing.base,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: AppSpacing.borderRadiusMd,
                        ),
                        child: const Icon(
                          Icons.restaurant_menu,
                          color: AppColors.red,
                          size: 24,
                        ),
                      ),
                      AppSpacing.gapH12,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppConfig.hospitalName.toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                            Text(
                              AppConfig.appSubtitle,
                              style: TextStyle(
                                color: AppColors.white.withValues(alpha: 0.8),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapV16,
                  Text(
                    'BUGÜN',
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppDateUtils.longDate(today),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circle(double size, double opacity) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: AppColors.white.withValues(alpha: opacity),
      shape: BoxShape.circle,
    ),
  );
}
