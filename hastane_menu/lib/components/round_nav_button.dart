import 'package:flutter/material.dart';
import 'package:hastane_menu/core/constants/app_colors.dart';

/// Takvim/hafta gezinme için yuvarlatılmış kare ok butonu.
class RoundNavButton extends StatelessWidget {
  const RoundNavButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Icon(icon, size: 18, color: AppColors.text),
      ),
    );
  }
}
