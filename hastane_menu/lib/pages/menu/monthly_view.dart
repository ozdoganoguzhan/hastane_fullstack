import 'package:flutter/material.dart';
import 'package:hastane_menu/components/async_status.dart';
import 'package:hastane_menu/components/day_menu_card.dart';
import 'package:hastane_menu/components/round_nav_button.dart';
import 'package:hastane_menu/core/constants/app_colors.dart';
import 'package:hastane_menu/core/constants/app_spacing.dart';
import 'package:hastane_menu/core/state/state_manager.dart';
import 'package:hastane_menu/core/utils/date_utils.dart';
import 'package:hastane_menu/data/menu_service.dart';
import 'package:hastane_menu/models/menu_models.dart';

/// Aylık takvim görünümü: ay seçici + takvim ızgarası + seçili gün menüsü.
class MonthlyView extends StatefulWidget {
  const MonthlyView({super.key});

  @override
  State<MonthlyView> createState() => _MonthlyViewState();
}

class _MonthlyViewState extends State<MonthlyView> {
  final MenuService _menuService = $get<MenuService>();

  late DateTime _cursor = DateTime(DateTime.now().year, DateTime.now().month);
  // İlk açılışta bugünü seçili getir — ekran boş görünmesin.
  DateTime? _selected = DateTime.now();
  late Future<List<DailyMenu>> _monthFuture = _loadMonth();

  Future<List<DailyMenu>> _loadMonth() =>
      _menuService.month(_cursor.year, _cursor.month);

  void _shiftMonth(int delta) {
    setState(() {
      _cursor = DateTime(_cursor.year, _cursor.month + delta);
      _selected = null;
      _monthFuture = _loadMonth();
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _cursor = DateTime(now.year, now.month);
      _selected = now;
      _monthFuture = _loadMonth();
    });
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _cursor.year == now.year && _cursor.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        // ── Ay seçici ────────────────────────────────────────────────────
        Row(
          children: [
            RoundNavButton(
              icon: Icons.chevron_left,
              onTap: () => _shiftMonth(-1),
            ),
            Expanded(
              child: Text(
                AppDateUtils.monthYear(_cursor),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
            ),
            RoundNavButton(
              icon: Icons.chevron_right,
              onTap: () => _shiftMonth(1),
            ),
          ],
        ),
        AppSpacing.gapV16,
        FutureBuilder<List<DailyMenu>>(
          future: _monthFuture,
          builder: (context, snapshot) {
            final loading =
                snapshot.connectionState == ConnectionState.waiting;
            final list = snapshot.data ?? const <DailyMenu>[];
            final menuDays = list
                .where((m) => !m.isEmpty)
                .map((m) => m.date.day)
                .toSet();

            return Column(
              children: [
                _CalendarGrid(
                  cursor: _cursor,
                  today: now,
                  selected: _selected,
                  menuDays: menuDays,
                  onSelect: (day) => setState(() => _selected = day),
                ),
                AppSpacing.gapV12,
                _Legend(
                  showToday: !_isCurrentMonth || _selected == null,
                  loading: loading,
                  onToday: _goToToday,
                ),
                if (snapshot.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: MenuErrorCard(
                      message: '${snapshot.error}',
                      onRetry: () =>
                          setState(() => _monthFuture = _loadMonth()),
                    ),
                  )
                else
                  _SelectedDay(
                    selected: _selected,
                    loading: loading,
                    record: _recordFor(_selected, list),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  DailyMenu? _recordFor(DateTime? day, List<DailyMenu> list) {
    if (day == null) return null;
    for (final menu in list) {
      if (AppDateUtils.isSameDay(menu.date, day)) return menu;
    }
    return null;
  }
}

/// Seçili günün menü kartı (yükleniyor / kayıt / boş).
class _SelectedDay extends StatelessWidget {
  const _SelectedDay({
    required this.selected,
    required this.loading,
    required this.record,
  });

  final DateTime? selected;
  final bool loading;
  final DailyMenu? record;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SizeTransition(sizeFactor: anim, child: child),
      ),
      child: selected == null
          ? const SizedBox.shrink()
          : Padding(
              key: ValueKey('$selected-$loading'),
              padding: const EdgeInsets.only(top: 16),
              child: loading
                  ? const MenuLoadingCard()
                  : DayMenuCard(
                      menu: record ?? DailyMenu.empty(selected!),
                      title:
                          '${AppDateUtils.dayMonth(selected!)} • '
                          '${AppDateUtils.weekdayName(selected!.weekday)}',
                    ),
            ),
    );
  }
}

/// Takvim altındaki açıklama satırı + "Bugüne git" kısayolu.
class _Legend extends StatelessWidget {
  const _Legend({
    required this.showToday,
    required this.loading,
    required this.onToday,
  });

  final bool showToday;
  final bool loading;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: AppColors.blue,
            shape: BoxShape.circle,
          ),
        ),
        AppSpacing.gapH8,
        const Text(
          'Menü olan gün',
          style: TextStyle(fontSize: 12, color: AppColors.textLight),
        ),
        if (loading) ...[
          AppSpacing.gapH8,
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.textMuted,
            ),
          ),
        ],
        const Spacer(),
        if (showToday)
          GestureDetector(
            onTap: onToday,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.today_rounded, size: 14, color: AppColors.red),
                  AppSpacing.gapH4,
                  Text(
                    'Bugüne git',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.cursor,
    required this.today,
    required this.selected,
    required this.menuDays,
    required this.onSelect,
  });

  final DateTime cursor;
  final DateTime today;
  final DateTime? selected;
  final Set<int> menuDays;
  final ValueChanged<DateTime> onSelect;

  static const _weekdayLabels = [
    'Pzt',
    'Sal',
    'Çar',
    'Per',
    'Cum',
    'Cmt',
    'Paz',
  ];

  @override
  Widget build(BuildContext context) {
    final first = DateTime(cursor.year, cursor.month);
    final leading = first.weekday - 1; // Pazartesi = 0 boşluk
    final daysInMonth = DateTime(cursor.year, cursor.month + 1, 0).day;

    final cells = <Widget>[
      for (var i = 0; i < leading; i++) const SizedBox.shrink(),
      for (var day = 1; day <= daysInMonth; day++)
        _DayCell(
          day: day,
          isWeekend:
              DateTime(cursor.year, cursor.month, day).weekday >=
              DateTime.saturday,
          isToday: AppDateUtils.isSameDay(
            DateTime(cursor.year, cursor.month, day),
            today,
          ),
          isSelected:
              selected != null &&
              AppDateUtils.isSameDay(
                DateTime(cursor.year, cursor.month, day),
                selected!,
              ),
          hasMenu: menuDays.contains(day),
          onTap: () => onSelect(DateTime(cursor.year, cursor.month, day)),
        ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppSpacing.shadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < _weekdayLabels.length; i++)
                Expanded(
                  child: Text(
                    _weekdayLabels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: i >= 5 ? AppColors.red : AppColors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: cells,
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isWeekend,
    required this.isToday,
    required this.isSelected,
    required this.hasMenu,
    required this.onTap,
  });

  final int day;
  final bool isWeekend;
  final bool isToday;
  final bool isSelected;
  final bool hasMenu;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Renk önceliği: seçili > bugün > menülü > normal.
    final Color bg = isSelected
        ? AppColors.blue
        : isToday
        ? AppColors.red
        : hasMenu
        ? AppColors.errorLight.withValues(alpha: 0.5)
        : Colors.transparent;

    final Color fg = (isSelected || isToday)
        ? AppColors.white
        : isWeekend
        ? AppColors.textMuted
        : AppColors.text;

    final Color dotColor = (isSelected || isToday)
        ? AppColors.white
        : AppColors.blue;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          // Bugün seçili değilken kırmızı çerçeve ile vurgulanır.
          border: isToday && !isSelected
              ? Border.all(color: AppColors.red, width: 1.5)
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 13,
                fontWeight: (isToday || isSelected || hasMenu)
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: fg,
              ),
            ),
            if (hasMenu)
              Positioned(
                bottom: 5,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
