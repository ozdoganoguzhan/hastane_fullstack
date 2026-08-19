import 'package:flutter/material.dart';
import 'package:hastane_menu/components/pressable.dart';
import 'package:hastane_menu/core/constants/app_colors.dart';
import 'package:hastane_menu/core/constants/app_spacing.dart';

/// Takvim/hafta gezinme için yuvarlatılmış kare ok butonu.
class RoundNavButton extends StatelessWidget {
  const RoundNavButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.9,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.fromBorderSide(BorderSide(color: AppColors.divider)),
          boxShadow: AppSpacing.shadowSm,
        ),
        child: Icon(icon, size: 20, color: AppColors.text),
      ),
    );
  }
}
