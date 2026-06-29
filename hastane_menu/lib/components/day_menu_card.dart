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
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppSpacing.borderRadiusLg,
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
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.border),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.redGradientLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '🔥 ${menu.totalCalories} kcal',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final meal in meals) MealSection(meal: meal),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
