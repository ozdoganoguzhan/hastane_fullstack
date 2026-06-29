import 'package:flutter/material.dart';
import 'package:hastane_menu/components/async_status.dart';
import 'package:hastane_menu/components/day_card.dart';
import 'package:hastane_menu/components/round_nav_button.dart';
import 'package:hastane_menu/core/constants/app_colors.dart';
import 'package:hastane_menu/core/state/state_manager.dart';
import 'package:hastane_menu/core/utils/date_utils.dart';
import 'package:hastane_menu/data/menu_service.dart';
import 'package:hastane_menu/models/menu_models.dart';

/// Haftalık menü görünümü: hafta seçici + Pzt-Cuma gün kartları.
class WeeklyView extends StatefulWidget {
  const WeeklyView({super.key});

  @override
  State<WeeklyView> createState() => _WeeklyViewState();
}

class _WeeklyViewState extends State<WeeklyView> {
  final MenuService _menuService = $get<MenuService>();
  final DateTime _now = DateTime.now();

  int _weekOffset = 0;
  late Future<List<DailyMenu>> _future = _load();

  DateTime get _monday => AppDateUtils.startOfWeek(
    _now,
  ).add(Duration(days: _weekOffset * 7));

  Future<List<DailyMenu>> _load() => _menuService.week(_monday);

  void _shiftWeek(int delta) {
    setState(() {
      _weekOffset += delta;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final monday = _monday;
    final friday = monday.add(const Duration(days: 4));

    return Column(
      children: [
        _WeekSelector(
          label:
              '${AppDateUtils.dayMonth(monday)} - '
              '${AppDateUtils.dayMonth(friday)}',
          onPrev: () => _shiftWeek(-1),
          onNext: () => _shiftWeek(1),
        ),
        Expanded(
          child: FutureBuilder<List<DailyMenu>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: MenuLoadingCard(height: 220),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: MenuErrorCard(
                    message: '${snapshot.error}',
                    onRetry: () => setState(() => _future = _load()),
                  ),
                );
              }
              final menus = snapshot.data ?? const [];
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  for (final menu in menus)
                    DayCard(
                      menu: menu,
                      isToday: AppDateUtils.isSameDay(_now, menu.date),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WeekSelector extends StatelessWidget {
  const _WeekSelector({
    required this.label,
    required this.onPrev,
    required this.onNext,
  });

  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RoundNavButton(icon: Icons.chevron_left, onTap: onPrev),
          SizedBox(
            width: 160,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ),
          RoundNavButton(icon: Icons.chevron_right, onTap: onNext),
        ],
      ),
    );
  }
}
