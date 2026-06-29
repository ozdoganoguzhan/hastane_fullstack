import 'package:flutter/material.dart';
import 'package:hastane_menu/core/constants/app_colors.dart';
import 'package:hastane_menu/core/constants/app_spacing.dart';
import 'package:hastane_menu/models/menu_models.dart';

/// Bir öğünü gösterir: başlık (emoji + ad + toplam kalori) + yemek satırları.
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
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
          child: Row(
            children: [
              Text(meal.type.emoji, style: const TextStyle(fontSize: 15)),
              AppSpacing.gapH8,
              Text(
                meal.type.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const Spacer(),
              if (meal.totalCalories > 0)
                Text(
                  '${meal.totalCalories} kcal',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.red,
                  ),
                ),
            ],
          ),
        ),
        for (var i = 0; i < meal.dishes.length; i++)
          _DishRow(
            dish: meal.dishes[i],
            showDivider: i != meal.dishes.length - 1,
          ),
      ],
    );
  }
}

class _DishRow extends StatelessWidget {
  const _DishRow({required this.dish, required this.showDivider});

  final MenuDish dish;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.border))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 10),
            decoration: const BoxDecoration(
              color: AppColors.red,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              dish.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.text,
              ),
            ),
          ),
          if (dish.hasCalories)
            Text(
              '${dish.calories} kcal',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textLight,
              ),
            ),
        ],
      ),
    );
  }
}
