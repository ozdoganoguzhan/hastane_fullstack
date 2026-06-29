import 'package:flutter/material.dart';
import 'package:hastane_menu/components/announcement_card.dart';
import 'package:hastane_menu/components/app_header.dart';
import 'package:hastane_menu/components/async_status.dart';
import 'package:hastane_menu/components/day_menu_card.dart';
import 'package:hastane_menu/components/section_header.dart';
import 'package:hastane_menu/core/constants/app_spacing.dart';
import 'package:hastane_menu/core/state/state_manager.dart';
import 'package:hastane_menu/data/announcement_service.dart';
import 'package:hastane_menu/data/menu_service.dart';
import 'package:hastane_menu/models/announcement.dart';
import 'package:hastane_menu/models/menu_models.dart';

/// Ana sayfa: üst başlık + bugünün menüsü + duyuru önizlemesi.
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.onNavigate});

  /// Alt sekmeye geçiş için ([1]=Menü, [2]=Duyurular).
  final ValueChanged<int> onNavigate;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MenuService _menuService = $get<MenuService>();
  final AnnouncementService _announcementService = $get<AnnouncementService>();
  final DateTime _today = DateTime.now();

  late Future<DailyMenu> _todayFuture = _menuService.day(_today);
  late Future<List<Announcement>> _announcementsFuture = _announcementService.all();

  void _reloadMenu() {
    setState(() => _todayFuture = _menuService.day(_today));
  }

  void _reloadAnnouncements() {
    setState(() => _announcementsFuture = _announcementService.all(forceRefresh: true));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        AppHeader(date: _today),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: '🍴 Bugünün Menüsü',
                linkLabel: 'Tümünü Gör →',
                onLinkTap: () => widget.onNavigate(1),
              ),
              FutureBuilder<DailyMenu>(
                future: _todayFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const MenuLoadingCard();
                  }
                  if (snapshot.hasError) {
                    return MenuErrorCard(
                      message: '${snapshot.error}',
                      onRetry: _reloadMenu,
                    );
                  }
                  return DayMenuCard(
                    menu: snapshot.data ?? DailyMenu.empty(_today),
                    title: 'Günün Öğünleri',
                  );
                },
              ),
              AppSpacing.gapV24,
              SectionHeader(
                title: '📢 Duyurular',
                linkLabel: 'Tümü →',
                onLinkTap: () => widget.onNavigate(2),
              ),
              FutureBuilder<List<Announcement>>(
                future: _announcementsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const MenuLoadingCard(height: 110);
                  }
                  if (snapshot.hasError) {
                    return MenuErrorCard(
                      title: 'Duyurular yüklenemedi',
                      message: '${snapshot.error}',
                      onRetry: _reloadAnnouncements,
                    );
                  }
                  final items = (snapshot.data ?? const <Announcement>[]).take(2);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final a in items) AnnouncementCard(announcement: a),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
