import 'package:flutter/material.dart';
import 'package:hastane_menu/components/app_button.dart';
import 'package:hastane_menu/components/skeleton.dart';
import 'package:hastane_menu/core/constants/app_colors.dart';
import 'package:hastane_menu/core/constants/app_spacing.dart';

/// Menü yüklenirken gösterilen iskelet kart — spinner yerine, gelecek içeriğin
/// biçiminde parlayan (shimmer) placeholder.
class MenuLoadingCard extends StatelessWidget {
  const MenuLoadingCard({super.key, this.height});

  /// Verilirse kart bu yüksekliğe sabitlenir (taşan iskelet kırpılır).
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: AppSpacing.borderRadiusXl,
        boxShadow: AppSpacing.shadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Shimmer(
        child: Padding(
          padding: AppSpacing.paddingAllBase,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Başlık satırı: gün adı + kalori hapı.
              const Row(
                children: [
                  SkeletonBox(width: 132, height: 14),
                  Spacer(),
                  SkeletonBox(
                    width: 76,
                    height: 24,
                    radius: AppSpacing.radiusRound,
                  ),
                ],
              ),
              AppSpacing.gapV20,
              ..._mealGroup(),
              AppSpacing.gapV16,
              ..._mealGroup(),
            ],
          ),
        ),
      ),
    );
  }

  /// Öğün bloğu iskeleti: rozet + başlık, ardından iki yemek satırı.
  List<Widget> _mealGroup() => [
    Row(
      children: const [
        SkeletonBox(height: 30, circle: true),
        AppSpacing.gapH8,
        SkeletonBox(width: 88, height: 12),
      ],
    ),
    AppSpacing.gapV12,
    Row(
      children: const [
        Expanded(child: SkeletonBox(height: 10)),
        AppSpacing.gapH16,
        SkeletonBox(width: 44, height: 10),
      ],
    ),
    AppSpacing.gapV12,
    Row(
      children: const [
        Expanded(child: SkeletonBox(height: 10)),
        AppSpacing.gapH16,
        SkeletonBox(width: 44, height: 10),
      ],
    ),
  ];
}

/// İçerik yüklenemediğinde gösterilen hata kartı + "Tekrar dene".
class MenuErrorCard extends StatelessWidget {
  const MenuErrorCard({
    super.key,
    required this.message,
    this.onRetry,
    this.title = 'Menü yüklenemedi',
  });

  final String message;
  final String title;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: AppSpacing.borderRadiusXl,
        boxShadow: AppSpacing.shadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.errorLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              size: 30,
              color: AppColors.primary,
            ),
          ),
          AppSpacing.gapV12,
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textStrong,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textLight,
              height: 1.5,
            ),
          ),
          if (onRetry != null) ...[
            AppSpacing.gapV20,
            AppButton(
              label: 'Tekrar Dene',
              icon: Icons.refresh_rounded,
              variant: AppButtonVariant.soft,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}
