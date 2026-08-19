import 'package:flutter/material.dart';
import 'package:hastane_menu/core/constants/app_colors.dart';
import 'package:hastane_menu/core/constants/app_spacing.dart';
import 'package:hastane_menu/core/constants/app_typography.dart';
import 'package:hastane_menu/models/menu_models.dart';

/// Öğün türüne özel aksan renkleri (UI katmanı — model saf kalır).
extension MealTypeColors on MealType {
  Color get accent => switch (this) {
    MealType.kahvalti => AppColors.breakfast,
    MealType.ogle => AppColors.lunch,
    MealType.aksam => AppColors.dinner,
  };

  Color get accentSoft => switch (this) {
    MealType.kahvalti => AppColors.breakfastSoft,
    MealType.ogle => AppColors.lunchSoft,
    MealType.aksam => AppColors.dinnerSoft,
  };
}

/// Bir öğünü gösterir: renkli rozet + ad + toplam kalori ve yemek satırları.
///
/// Kahvaltı / Öğle / Akşam bölümleri için ortak yapı taşıdır (home, day_card,
/// monthly görünümlerinde kullanılır).
class MealSection extends StatelessWidget {
  const MealSection({super.key, required this.meal});

  final Meal meal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 14, 0, 6),
          child: Row(
            children: [
              // Öğüne özel renkli emoji rozeti.
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: meal.type.accentSoft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  meal.type.emoji,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              AppSpacing.gapH8,
              Text(
                meal.type.label,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textStrong,
                  letterSpacing: -0.1,
                ),
              ),
              const Spacer(),
              if (meal.totalCalories > 0)
                Text(
                  '${meal.totalCalories} kcal',
                  style: AppTypography.stat.copyWith(color: meal.type.accent),
                ),
            ],
          ),
        ),
        for (var i = 0; i < meal.dishes.length; i++)
          _DishRow(
            dish: meal.dishes[i],
            accent: meal.type.accent,
            showDivider: i != meal.dishes.length - 1,
          ),
      ],
    );
  }
}

class _DishRow extends StatelessWidget {
  const _DishRow({
    required this.dish,
    required this.accent,
    required this.showDivider,
  });

  final MenuDish dish;
  final Color accent;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.divider))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(left: 4, right: 12),
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text(
              dish.name,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: AppColors.text,
                height: 1.35,
              ),
            ),
          ),
          if (dish.hasCalories) ...[
            AppSpacing.gapH8,
            Text('${dish.calories} kcal', style: AppTypography.stat),
          ],
        ],
      ),
    );
  }
}
