import 'package:flutter/material.dart';
import 'package:hastane_menu/components/async_status.dart';
import 'package:hastane_menu/components/day_menu_card.dart';
import 'package:hastane_menu/components/page_header.dart';
import 'package:hastane_menu/components/pressable.dart';
import 'package:hastane_menu/components/round_nav_button.dart';
import 'package:hastane_menu/core/constants/app_colors.dart';
import 'package:hastane_menu/core/constants/app_spacing.dart';
import 'package:hastane_menu/core/state/state_manager.dart';
import 'package:hastane_menu/core/utils/date_utils.dart';
import 'package:hastane_menu/data/menu_service.dart';
import 'package:hastane_menu/models/menu_models.dart';

/// Menü Takvimi — tek akışkan deneyim (haftalık/aylık mod ayrımı YOKTUR):
///
///  1. **Ay çubuğu** — ‹ Temmuz 2026 › ; ortasına dokununca **takvim ızgarası**
///     aşağı açılır (uzak bir güne tek dokunuşla atlama).
///  2. **Gün şeridi** — yatay kaydırılan gün çipleri; seçili gün kırmızı
///     degrade, bugün çerçeveli, menüsü olan günler noktalı.
///  3. **Gün sayfaları** — menü kartı sola/sağa **kaydırılarak** gün gezilir;
///     şerit ve takvim her zaman senkron kalır.
class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final MenuService _menuService = $get<MenuService>();

  late DateTime _cursor = DateTime(DateTime.now().year, DateTime.now().month);
  late int _selectedDay = DateTime.now().day;
  late Future<List<DailyMenu>> _monthFuture = _loadMonth();
  bool _calendarOpen = false;

  late PageController _pageController = PageController(
    initialPage: _selectedDay - 1,
  );
  final ScrollController _stripController = ScrollController();

  /// Gün şeridi çip genişliği + sağ boşluk (kaydırma hesabı için).
  static const double _chipExtent = 54 + 8;

  int get _daysInMonth => DateTime(_cursor.year, _cursor.month + 1, 0).day;

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _cursor.year == now.year && _cursor.month == now.month;
  }

  bool get _isTodaySelected =>
      _isCurrentMonth && _selectedDay == DateTime.now().day;

  @override
  void initState() {
    super.initState();
    // İlk açılışta bugünü şeridin ortasına getir.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollStripTo(_selectedDay, animate: false),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _stripController.dispose();
    super.dispose();
  }

  Future<List<DailyMenu>> _loadMonth() =>
      _menuService.month(_cursor.year, _cursor.month);

  // ── Seçim / gezinme ──────────────────────────────────────────────────────

  /// Şeritte seçili günü görünür alanın ortasına kaydırır.
  void _scrollStripTo(int day, {bool animate = true}) {
    if (!_stripController.hasClients) return;
    final position = _stripController.position;
    final target =
        ((day - 1) * _chipExtent -
                (position.viewportDimension - _chipExtent) / 2)
            .clamp(0.0, position.maxScrollExtent);
    if (animate) {
      _stripController.animateTo(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _stripController.jumpTo(target);
    }
  }

  /// Gün seçimi — şerit/takvim dokunuşları buradan geçer.
  void _selectDay(int day, {bool closeCalendar = false}) {
    setState(() {
      _selectedDay = day;
      if (closeCalendar) _calendarOpen = false;
    });
    _pageController.animateToPage(
      day - 1,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
    _scrollStripTo(day);
  }

  /// Kaydırma ile sayfa değişince şerit ve seçim senkron kalır.
  void _onPageChanged(int index) {
    if (_selectedDay == index + 1) return;
    setState(() => _selectedDay = index + 1);
    _scrollStripTo(index + 1);
  }

  /// Ayı değiştirir; mümkünse bugünü, değilse ayın ilk gününü seçer.
  void _setMonth(DateTime month) {
    final now = DateTime.now();
    final bool toCurrent =
        month.year == now.year && month.month == now.month;
    final int day = toCurrent ? now.day : 1;

    // Eski controller bu frame'de sökülen PageView'a bağlı; sonra at.
    final old = _pageController;
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());

    setState(() {
      _cursor = DateTime(month.year, month.month);
      _selectedDay = day;
      _monthFuture = _loadMonth();
      _pageController = PageController(initialPage: day - 1);
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollStripTo(day, animate: false),
    );
  }

  void _shiftMonth(int delta) =>
      _setMonth(DateTime(_cursor.year, _cursor.month + delta));

  void _goToToday() {
    final now = DateTime.now();
    if (_isCurrentMonth) {
      _selectDay(now.day, closeCalendar: true);
    } else {
      _setMonth(now);
    }
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.base,
              AppSpacing.base,
              AppSpacing.base,
              AppSpacing.md,
            ),
            child: PageHeader(
              title: 'Menü Takvimi',
              subtitle: 'Kaydırarak veya güne dokunarak gezinin',
              trailing: _isTodaySelected ? null : _TodayChip(onTap: _goToToday),
            ),
          ),
          Padding(
            padding: AppSpacing.screenPadding,
            child: _MonthBar(
              label: AppDateUtils.monthYear(_cursor),
              calendarOpen: _calendarOpen,
              onPrev: () => _shiftMonth(-1),
              onNext: () => _shiftMonth(1),
              onToggleCalendar: () =>
                  setState(() => _calendarOpen = !_calendarOpen),
            ),
          ),
          AppSpacing.gapV12,
          Expanded(
            child: FutureBuilder<List<DailyMenu>>(
              future: _monthFuture,
              builder: (context, snapshot) {
                final bool loading =
                    snapshot.connectionState == ConnectionState.waiting;
                final list = snapshot.data ?? const <DailyMenu>[];
                final menuDays = <int>{
                  for (final m in list)
                    if (!m.isEmpty) m.date.day,
                };

                return Column(
                  children: [
                    // ── Açılır takvim ızgarası ──────────────────────────
                    AnimatedSize(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: _calendarOpen
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.base,
                                0,
                                AppSpacing.base,
                                AppSpacing.md,
                              ),
                              child: _MonthGrid(
                                cursor: _cursor,
                                selectedDay: _selectedDay,
                                menuDays: menuDays,
                                onSelect: (day) =>
                                    _selectDay(day, closeCalendar: true),
                              ),
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                    // ── Gün şeridi ──────────────────────────────────────
                    SizedBox(
                      height: 76,
                      child: ListView.builder(
                        controller: _stripController,
                        scrollDirection: Axis.horizontal,
                        padding: AppSpacing.screenPadding,
                        itemCount: _daysInMonth,
                        itemBuilder: (context, i) {
                          final date = DateTime(
                            _cursor.year,
                            _cursor.month,
                            i + 1,
                          );
                          return _DayChip(
                            date: date,
                            selected: _selectedDay == i + 1,
                            hasMenu: menuDays.contains(i + 1),
                            onTap: () => _selectDay(i + 1),
                          );
                        },
                      ),
                    ),
                    AppSpacing.gapV8,
                    // ── Gün sayfaları ───────────────────────────────────
                    Expanded(
                      child: snapshot.hasError
                          ? ListView(
                              padding: AppSpacing.paddingAllBase,
                              children: [
                                MenuErrorCard(
                                  message: '${snapshot.error}',
                                  onRetry: () => setState(
                                    () => _monthFuture = _loadMonth(),
                                  ),
                                ),
                              ],
                            )
                          : loading
                          ? const Padding(
                              padding: EdgeInsets.fromLTRB(
                                AppSpacing.base,
                                AppSpacing.xs,
                                AppSpacing.base,
                                0,
                              ),
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: MenuLoadingCard(),
                              ),
                            )
                          : PageView.builder(
                              key: ValueKey(
                                '${_cursor.year}-${_cursor.month}',
                              ),
                              controller: _pageController,
                              onPageChanged: _onPageChanged,
                              itemCount: _daysInMonth,
                              itemBuilder: (context, i) {
                                final date = DateTime(
                                  _cursor.year,
                                  _cursor.month,
                                  i + 1,
                                );
                                return ListView(
                                  padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.base,
                                    AppSpacing.xs,
                                    AppSpacing.base,
                                    AppSpacing.xl,
                                  ),
                                  children: [
                                    DayMenuCard(
                                      menu:
                                          _recordFor(date, list) ??
                                          DailyMenu.empty(date),
                                      title:
                                          '${AppDateUtils.dayMonth(date)} • '
                                          '${AppDateUtils.weekdayName(date.weekday)}',
                                    ),
                                  ],
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  DailyMenu? _recordFor(DateTime day, List<DailyMenu> list) {
    for (final menu in list) {
      if (AppDateUtils.isSameDay(menu.date, day)) return menu;
    }
    return null;
  }
}

/// "Bugün" kısayol çipi (başlığın sağında).
class _TodayChip extends StatelessWidget {
  const _TodayChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.today_rounded, size: 14, color: AppColors.primary),
            AppSpacing.gapH4,
            Text(
              'Bugün',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ay çubuğu — oklar + ortada aya dokununca açılan takvim tetikleyicisi.
class _MonthBar extends StatelessWidget {
  const _MonthBar({
    required this.label,
    required this.calendarOpen,
    required this.onPrev,
    required this.onNext,
    required this.onToggleCalendar,
  });

  final String label;
  final bool calendarOpen;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToggleCalendar;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        RoundNavButton(icon: Icons.chevron_left_rounded, onTap: onPrev),
        Expanded(
          child: Pressable(
            onTap: onToggleCalendar,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: calendarOpen ? AppColors.primarySoft : Colors.transparent,
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: calendarOpen
                          ? AppColors.primary
                          : AppColors.textStrong,
                    ),
                  ),
                  AppSpacing.gapH4,
                  AnimatedRotation(
                    turns: calendarOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: calendarOpen
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        RoundNavButton(icon: Icons.chevron_right_rounded, onTap: onNext),
      ],
    );
  }
}

/// Gün şeridi çipi — hafta günü + gün numarası + menü noktası.
class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.date,
    required this.selected,
    required this.hasMenu,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final bool hasMenu;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final bool isToday = AppDateUtils.isSameDay(date, now);
    final bool isWeekend = date.weekday >= DateTime.saturday;

    final Color labelColor = selected
        ? AppColors.white.withValues(alpha: 0.85)
        : isToday
        ? AppColors.primary
        : AppColors.textMuted;

    final Color dayColor = selected
        ? AppColors.white
        : isToday
        ? AppColors.primary
        : isWeekend
        ? AppColors.textMuted
        : AppColors.textStrong;

    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: 54,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          color: selected ? null : AppColors.white,
          borderRadius: AppSpacing.borderRadiusLg,
          border: selected
              ? null
              : Border.all(
                  color: isToday ? AppColors.primary : AppColors.divider,
                  width: isToday ? 1.4 : 1,
                ),
          boxShadow: selected ? AppSpacing.shadowPrimary : AppSpacing.shadowSm,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppDateUtils.weekdayShort(date.weekday),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.1,
                color: dayColor,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: hasMenu
                    ? (selected ? AppColors.white : AppColors.primary)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Açılır kompakt takvim ızgarası — uzak günlere tek dokunuşla atlama.
class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.cursor,
    required this.selectedDay,
    required this.menuDays,
    required this.onSelect,
  });

  final DateTime cursor;
  final int selectedDay;
  final Set<int> menuDays;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final leading = DateTime(cursor.year, cursor.month).weekday - 1;
    final daysInMonth = DateTime(cursor.year, cursor.month + 1, 0).day;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        14,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: AppSpacing.borderRadiusXl,
        boxShadow: AppSpacing.shadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Text(
                    AppDateUtils.weekdayShort(i + 1),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      color: i >= 5
                          ? AppColors.primary.withValues(alpha: 0.65)
                          : AppColors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
          AppSpacing.gapV8,
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.xs,
            crossAxisSpacing: AppSpacing.xs,
            childAspectRatio: 1.2,
            children: [
              for (var i = 0; i < leading; i++) const SizedBox.shrink(),
              for (var day = 1; day <= daysInMonth; day++)
                _GridCell(
                  day: day,
                  isToday: AppDateUtils.isSameDay(
                    DateTime(cursor.year, cursor.month, day),
                    now,
                  ),
                  isSelected: day == selectedDay,
                  isWeekend:
                      DateTime(cursor.year, cursor.month, day).weekday >=
                      DateTime.saturday,
                  hasMenu: menuDays.contains(day),
                  onTap: () => onSelect(day),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GridCell extends StatelessWidget {
  const _GridCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.isWeekend,
    required this.hasMenu,
    required this.onTap,
  });

  final int day;
  final bool isToday;
  final bool isSelected;
  final bool isWeekend;
  final bool hasMenu;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Renk önceliği: seçili > bugün > menülü > normal.
    final Color bg = isSelected
        ? AppColors.primary
        : isToday || hasMenu
        ? AppColors.primarySoft
        : Colors.transparent;

    final Color fg = isSelected
        ? AppColors.white
        : isToday
        ? AppColors.primary
        : isWeekend
        ? AppColors.textMuted
        : AppColors.text;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppSpacing.borderRadiusMd,
          border: isToday && !isSelected
              ? Border.all(color: AppColors.primary, width: 1.5)
              : null,
          boxShadow: isSelected ? AppSpacing.shadowPrimary : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 13,
                fontWeight: (isToday || isSelected || hasMenu)
                    ? FontWeight.w800
                    : FontWeight.w500,
                color: fg,
              ),
            ),
            if (hasMenu)
              Positioned(
                bottom: 3,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.white : AppColors.primary,
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
