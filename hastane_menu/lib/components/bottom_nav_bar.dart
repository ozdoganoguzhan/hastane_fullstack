import 'package:flutter/material.dart';
import 'package:hastane_menu/components/pressable.dart';
import 'package:hastane_menu/core/constants/app_colors.dart';
import 'package:hastane_menu/core/constants/app_spacing.dart';

/// Alt navigasyon sekmesi tanımı.
class NavTab {
  const NavTab({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

/// QR eylem butonu tanımı (Giriş / QR).
class CenterNavButton {
  const CenterNavButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

/// Yüzen alt navigasyon çubuğu — **4 eşit slot**, tam simetrik:
///
/// `[Ana Sayfa] [Menü] [QR] [Bilgi]`
///
/// QR bir sekme değil eylemdir; degrade daire rozetiyle vurgulanır ama diğer
/// slotlarla aynı ritimde hizalanır. Bar, kenarlardan boşluklu "yüzen hap"
/// biçimindedir.
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
    required this.center,
  });

  final List<NavTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final CenterNavButton center;

  /// İkon alanlarının ortak yüksekliği — etiketler tek hizada durur.
  static const double _iconZone = 36;

  @override
  Widget build(BuildContext context) {
    assert(tabs.length == 3, 'BottomNavBar tam 3 sekme bekler.');
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: Container(
          height: 68,
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.all(
              Radius.circular(AppSpacing.radiusXxl),
            ),
            border: Border.fromBorderSide(
              BorderSide(color: AppColors.divider),
            ),
            boxShadow: AppSpacing.shadowLg,
          ),
          child: Row(
            children: [
              _tab(0),
              _tab(1),
              Expanded(child: _QrItem(config: center)),
              _tab(2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(int i) => Expanded(
    child: _NavItem(
      tab: tabs[i],
      selected: i == currentIndex,
      onTap: () => onTap(i),
    ),
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final NavTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = selected ? AppColors.red : AppColors.textMuted;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Aktif sekmede ikonun arkasında yumuşak kırmızı hap belirir.
          SizedBox(
            height: BottomNavBar._iconZone,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: selected ? AppColors.redSoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
                ),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  scale: selected ? 1.05 : 1,
                  child: Icon(tab.icon, size: 22, color: color),
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: color,
              letterSpacing: 0.1,
            ),
            child: Text(tab.label),
          ),
        ],
      ),
    );
  }
}

/// QR eylem slotu — degrade daire rozet, sekmelerle aynı dikey ritimde.
class _QrItem extends StatelessWidget {
  const _QrItem({required this.config});
  final CenterNavButton config;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: config.onTap,
      pressedScale: 0.92,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: BottomNavBar._iconZone,
            child: Center(
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  gradient: AppColors.redGradient,
                  shape: BoxShape.circle,
                  boxShadow: AppSpacing.shadowRed,
                ),
                child: Icon(config.icon, color: AppColors.white, size: 20),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            config.label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.red,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
