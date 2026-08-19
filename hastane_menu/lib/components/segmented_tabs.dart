import 'package:flutter/material.dart';
import 'package:hastane_menu/core/constants/app_colors.dart';
import 'package:hastane_menu/core/constants/app_spacing.dart';

/// Segment seçeneği — etiket + opsiyonel ikon.
class SegmentedItem {
  const SegmentedItem(this.label, {this.icon});

  final String label;
  final IconData? icon;
}

/// Kayan beyaz başparmaklı (thumb) animasyonlu segment kontrolü.
///
/// Menü sayfasında (Haftalık/Aylık) ve giriş ekranında (Telefon/Kullanıcı adı)
/// kullanılan ortak premium bileşendir.
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.items,
    required this.current,
    required this.onChanged,
  });

  final List<SegmentedItem> items;
  final int current;
  final ValueChanged<int> onChanged;

  static const double _padding = 4;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: const BorderRadius.all(
          Radius.circular(AppSpacing.radiusMd + 2),
        ),
        border: Border.all(color: AppColors.divider),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double segmentWidth = constraints.maxWidth / items.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                left: segmentWidth * current,
                top: 0,
                bottom: 0,
                width: segmentWidth,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppSpacing.borderRadiusSm,
                    boxShadow: AppSpacing.shadow,
                  ),
                ),
              ),
              // Positioned.fill → satır tam yüksekliği kaplar; içerik dikeyde
              // tam ortalanır (gevşek constraint'te üste yapışma bug'ı olmaz).
              Positioned.fill(
                child: Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(child: _segment(i)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _segment(int index) {
    final item = items[index];
    final bool selected = index == current;
    final Color color = selected ? AppColors.red : AppColors.textLight;

    return GestureDetector(
      onTap: () => onChanged(index),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (item.icon != null) ...[
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                item.icon,
                key: ValueKey(selected),
                size: 16,
                color: color,
              ),
            ),
            AppSpacing.gapH8,
          ],
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.textStrong : AppColors.textLight,
            ),
            child: Text(item.label),
          ),
        ],
      ),
    );
  }
}
