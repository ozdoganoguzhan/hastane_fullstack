import 'package:flutter/material.dart';
import 'package:hastane_menu/components/app_header.dart';
import 'package:hastane_menu/components/async_status.dart';
import 'package:hastane_menu/components/day_menu_card.dart';
import 'package:hastane_menu/components/login_sheet.dart';
import 'package:hastane_menu/components/pressable.dart';
import 'package:hastane_menu/components/section_header.dart';
import 'package:hastane_menu/core/constants/app_colors.dart';
import 'package:hastane_menu/core/constants/app_spacing.dart';
import 'package:hastane_menu/core/state/state_manager.dart';
import 'package:hastane_menu/data/menu_service.dart';
import 'package:hastane_menu/models/menu_models.dart';

/// Ana sayfa: kurumsal hero + hero'ya bindirilmiş bugünün menüsü kartı +
/// hızlı erişim kısayolları. Bölümler yumuşak bir giriş animasyonuyla gelir.
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.onNavigate});

  /// Alt sekmeye geçiş için ([1]=Menü, [2]=Bilgi).
  final ValueChanged<int> onNavigate;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Menü kartının hero üzerine bindirilme miktarı.
  static const double _overlap = 34;

  final MenuService _menuService = $get<MenuService>();
  final DateTime _today = DateTime.now();

  late Future<DailyMenu> _todayFuture = _menuService.day(_today);

  void _reloadMenu() {
    // Kullanıcı "tekrar dene" derse önbelleği atlayıp HBYS'den taze çek.
    _menuService.clearCache();
    setState(() => _todayFuture = _menuService.day(_today));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        AppHeader(date: _today, bottomOverlap: _overlap),
        // İçerik hero'nun alt kenarına biner — katmanlı premium görünüm.
        Transform.translate(
          offset: const Offset(0, -_overlap + AppSpacing.sm),
          child: Padding(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Entrance(
                  delayMs: 0,
                  child: FutureBuilder<DailyMenu>(
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
                        title: 'Bugünün Menüsü',
                      );
                    },
                  ),
                ),
                AppSpacing.gapV24,
                _Entrance(
                  delayMs: 120,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: 'Hızlı Erişim',
                        linkLabel: 'Menü Takvimi',
                        onLinkTap: () => widget.onNavigate(1),
                      ),
                      Row(
                        children: [
                          _QuickAction(
                            icon: Icons.calendar_month_rounded,
                            gradient: AppColors.primaryGradient,
                            label: 'Menü\nTakvimi',
                            onTap: () => widget.onNavigate(1),
                          ),
                          AppSpacing.gapH12,
                          _QuickAction(
                            icon: Icons.qr_code_2_rounded,
                            gradient: AppColors.accentGradient,
                            label: 'Personel\nKartım',
                            onTap: () => LoginSheet.show(context),
                          ),
                          AppSpacing.gapH12,
                          _QuickAction(
                            icon: Icons.info_rounded,
                            gradient: _QuickAction.indigoGradient,
                            label: 'Yemekhane\nBilgileri',
                            onTap: () => widget.onNavigate(2),
                          ),
                        ],
                      ),
                    ],
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

/// Hızlı erişim kısayol kartı — degrade ikon rozeti + etiket.
class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.gradient,
    required this.label,
    required this.onTap,
  });

  /// Üçüncü kısayol için indigo→lacivert degrade.
  static const LinearGradient indigoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.dinner, AppColors.accentDark],
  );

  final IconData icon;
  final Gradient gradient;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: AppSpacing.borderRadiusLg,
            boxShadow: AppSpacing.shadow,
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(AppSpacing.radiusMd + 2),
                  ),
                  boxShadow: AppSpacing.shadowSm,
                ),
                child: Icon(icon, size: 22, color: AppColors.white),
              ),
              AppSpacing.gapV8,
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tek seferlik yumuşak giriş animasyonu (aşağıdan kayarak belirme).
class _Entrance extends StatelessWidget {
  const _Entrance({required this.delayMs, required this.child});

  final int delayMs;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final int totalMs = 460 + delayMs;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: totalMs),
      curve: Interval(delayMs / totalMs, 1, curve: Curves.easeOutCubic),
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - t)),
          child: child,
        ),
      ),
    );
  }
}
