import 'package:flutter/material.dart';
import 'package:hastane_menu/components/empty_state.dart';
import 'package:hastane_menu/components/meal_section.dart';
import 'package:hastane_menu/core/constants/app_colors.dart';
import 'package:hastane_menu/core/constants/app_spacing.dart';
import 'package:hastane_menu/models/menu_models.dart';

/// Bir günün tüm öğünlerini tek kartta gösterir: başlık + toplam kalori +
/// Kahvaltı/Öğle/Akşam bölümleri. Menü yoksa boş durum gösterir.
///
/// Ana sayfada bugünün menüsü ve aylık görünümde seçili gün için kullanılır.
class DayMenuCard extends StatelessWidget {
  const DayMenuCard({super.key, required this.menu, required this.title});

  final DailyMenu menu;
  final String title;

  @override
  Widget build(BuildContext context) {
    final meals = menu.nonEmptyMeals;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: AppSpacing.borderRadiusXl,
        boxShadow: AppSpacing.shadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: meals.isEmpty
          ? const EmptyState(
              emoji: '🌙',
              title: 'Menü Yok',
              message: 'Bu gün için menü bulunmuyor.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base,
                    vertical: 14,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceTint,
                    border: Border(
                      bottom: BorderSide(color: AppColors.divider),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textStrong,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      if (menu.totalCalories > 0)
                        _TotalCaloriePill(calories: menu.totalCalories),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.base,
                    0,
                    AppSpacing.base,
                    14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [for (final meal in meals) MealSection(meal: meal)],
                  ),
                ),
              ],
            ),
    );
  }
}

class _TotalCaloriePill extends StatelessWidget {
  const _TotalCaloriePill({required this.calories});

  final int calories;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 5),
      decoration: BoxDecoration(
        gradient: AppColors.redGradientLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: Text(
        '🔥 $calories kcal',
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: AppColors.white,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
