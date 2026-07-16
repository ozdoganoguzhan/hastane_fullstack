import 'package:flutter/material.dart';
import 'package:hastane_menu/core/constants/app_colors.dart';

/// Alt navigasyon sekmesi tanımı.
class NavTab {
  const NavTab({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

/// Ortadaki yükseltilmiş eylem butonu tanımı (Giriş / QR).
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

/// Alt navigasyon çubuğu — 3 sekme + ortada vurgulu bir eylem butonu.
///
/// Dizilim: tab0 · tab1 · [orta buton] · tab2
/// Orta butonun tam ortada (%50) kalması için sağdaki sekmeye çift genişlik
/// verilir: flex 1 + 1 + 1(boşluk) + 2 → boşluğun merkezi %50'dir.
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

  @override
  Widget build(BuildContext context) {
    assert(tabs.length == 3, 'BottomNavBar tam 3 sekme bekler.');
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _tab(0),
                  _tab(1),
                  // Orta butonun oturduğu boşluk (merkezi %50).
                  const Expanded(child: SizedBox.shrink()),
                  _tab(2, flex: 2),
                ],
              ),
              // Orta buton bar'ın üstüne taşar — "yapıştırılmış" görünüm.
              Positioned(
                top: -26,
                child: _CenterButton(config: center),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(int i, {int flex = 1}) => Expanded(
    flex: flex,
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
    final color = selected ? AppColors.red : AppColors.textMuted;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(tab.icon, size: 22, color: color),
          const SizedBox(height: 3),
          Text(
            tab.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterButton extends StatelessWidget {
  const _CenterButton({required this.config});
  final CenterNavButton config;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: config.onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: AppColors.redGradient,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: AppColors.red.withValues(alpha: 0.45),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(config.icon, color: AppColors.white, size: 27),
          ),
          const SizedBox(height: 3),
          Text(
            config.label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.red,
            ),
          ),
        ],
      ),
    );
  }
}
