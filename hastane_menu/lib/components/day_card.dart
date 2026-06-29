import 'package:flutter/material.dart';
import 'package:hastane_menu/components/meal_section.dart';
import 'package:hastane_menu/core/constants/app_colors.dart';
import 'package:hastane_menu/core/constants/app_spacing.dart';
import 'package:hastane_menu/core/utils/date_utils.dart';
import 'package:hastane_menu/models/menu_models.dart';

/// Haftalık görünümde açılır/kapanır gün kartı.
///
/// "Bugün" ise başlık kırmızı degrade olur. Tıklayınca öğün bölümleri
/// (Kahvaltı/Öğle/Akşam) açılır. Menü yoksa kısa bir bilgi satırı gösterilir.
class DayCard extends StatefulWidget {
  const DayCard({
    super.key,
    required this.menu,
    this.isToday = false,
    this.initiallyExpanded = false,
  });

  final DailyMenu menu;
  final bool isToday;
  final bool initiallyExpanded;

  @override
  State<DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<DayCard> {
  late bool _expanded = widget.initiallyExpanded || widget.isToday;

  @override
  Widget build(BuildContext context) {
    final menu = widget.menu;
    final meals = menu.nonEmptyMeals;
    final hasMenu = meals.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppSpacing.shadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: hasMenu
                ? () => setState(() => _expanded = !_expanded)
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                gradient: widget.isToday ? AppColors.redGradientLight : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppDateUtils.weekdayName(menu.date.weekday),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: widget.isToday
                                ? AppColors.white
                                : AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          AppDateUtils.dayMonth(menu.date),
                          style: TextStyle(
                            fontSize: 11,
                            color: widget.isToday
                                ? AppColors.white
                                : AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasMenu) ...[
                    _CalorieBadge(
                      calories: menu.totalCalories,
                      onColored: widget.isToday,
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: widget.isToday
                          ? AppColors.white
                          : AppColors.textMuted,
                    ),
                  ] else
                    Text(
                      'Menü yok',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.isToday
                            ? AppColors.white
                            : AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (hasMenu && _expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
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

class _CalorieBadge extends StatelessWidget {
  const _CalorieBadge({required this.calories, required this.onColored});

  final int calories;
  final bool onColored;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: onColored
            ? AppColors.white.withValues(alpha: 0.25)
            : AppColors.errorLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '🔥 $calories kcal',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: onColored ? AppColors.white : AppColors.red,
        ),
      ),
    );
  }
}
