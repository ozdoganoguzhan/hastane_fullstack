import 'package:flutter/material.dart';
import 'package:hastane_menu/core/constants/app_colors.dart';
import 'package:hastane_menu/core/constants/app_spacing.dart';
import 'package:hastane_menu/core/constants/app_typography.dart';
import 'package:hastane_menu/pages/menu/monthly_view.dart';
import 'package:hastane_menu/pages/menu/weekly_view.dart';

/// Menü takvimi sayfası — Haftalık / Aylık görünüm arasında geçiş.
class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  int _tab = 0; // 0 = Haftalık, 1 = Aylık

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text('📅 Menü Takvimi', style: AppTypography.headingLarge),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SegmentedTabs(
              labels: const ['Haftalık', 'Aylık Takvim'],
              current: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
          ),
          AppSpacing.gapV16,
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: const [WeeklyView(), MonthlyView()],
            ),
          ),
        ],
      ),
    );
  }
}

/// İki seçenekli segment kontrolü (Haftalık / Aylık).
class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({
    required this.labels,
    required this.current,
    required this.onChanged,
  });

  final List<String> labels;
  final int current;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == current ? AppColors.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: i == current ? AppSpacing.shadow : null,
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: i == current ? AppColors.red : AppColors.textLight,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
