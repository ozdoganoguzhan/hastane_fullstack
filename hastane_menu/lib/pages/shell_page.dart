import 'package:flutter/material.dart';
import 'package:hastane_menu/components/bottom_nav_bar.dart';
import 'package:hastane_menu/components/login_sheet.dart';
import 'package:hastane_menu/core/constants/app_colors.dart';
import 'package:hastane_menu/core/state/session_state.dart';
import 'package:hastane_menu/core/state/state_manager.dart';
import 'package:hastane_menu/pages/announcements_page.dart';
import 'package:hastane_menu/pages/home_page.dart';
import 'package:hastane_menu/pages/info_page.dart';
import 'package:hastane_menu/pages/menu_page.dart';

/// Alt navigasyonlu ana iskelet. 4 sayfayı IndexedStack ile barındırır.
class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  final SessionState _session = $get<SessionState>();
  int _index = 0;

  static const _tabs = [
    NavTab(icon: Icons.home_rounded, label: 'Ana Sayfa'),
    NavTab(icon: Icons.calendar_month_rounded, label: 'Menü'),
    NavTab(icon: Icons.campaign_rounded, label: 'Duyurular'),
    NavTab(icon: Icons.info_rounded, label: 'Bilgi'),
  ];

  void _goTo(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _index,
        children: [
          HomePage(onNavigate: _goTo),
          const MenuPage(),
          const AnnouncementsPage(),
          const InfoPage(),
        ],
      ),
      bottomNavigationBar: _session.session.builder((session) {
        final loggedIn = session != null;
        return BottomNavBar(
          tabs: _tabs,
          currentIndex: _index,
          onTap: _goTo,
          center: CenterNavButton(
            icon: Icons.qr_code_2_rounded,
            label: loggedIn ? 'QR Kod' : 'Giriş',
            onTap: () => LoginSheet.show(context),
          ),
        );
      }),
    );
  }
}
