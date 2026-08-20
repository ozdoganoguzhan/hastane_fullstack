import 'package:flutter/widgets.dart';

import 'package:hastane_menu/core/constants/app_colors.dart';

/// Boşluk, padding, köşe yarıçapı ve gölge sabitleri. Magic number YASAKTIR.
sealed class AppSpacing {
  // === BASE ===
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  // === PADDING PRESETS ===
  static const EdgeInsets paddingAllSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingAllMd = EdgeInsets.all(md);
  static const EdgeInsets paddingAllBase = EdgeInsets.all(base);
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: base);

  // === GAP WIDGETS ===
  static const SizedBox gapH4 = SizedBox(width: xs);
  static const SizedBox gapH8 = SizedBox(width: sm);
  static const SizedBox gapH12 = SizedBox(width: md);
  static const SizedBox gapH16 = SizedBox(width: base);

  static const SizedBox gapV4 = SizedBox(height: xs);
  static const SizedBox gapV8 = SizedBox(height: sm);
  static const SizedBox gapV12 = SizedBox(height: md);
  static const SizedBox gapV16 = SizedBox(height: base);
  static const SizedBox gapV20 = SizedBox(height: lg);
  static const SizedBox gapV24 = SizedBox(height: xl);
  static const SizedBox gapV32 = SizedBox(height: xxl);

  // === BORDER RADIUS ===
  static const double radiusSm = 10;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusXxl = 24;
  static const double radiusHero = 32;
  static const double radiusRound = 100;

  static const BorderRadius borderRadiusSm = BorderRadius.all(
    Radius.circular(radiusSm),
  );
  static const BorderRadius borderRadiusMd = BorderRadius.all(
    Radius.circular(radiusMd),
  );
  static const BorderRadius borderRadiusLg = BorderRadius.all(
    Radius.circular(radiusLg),
  );
  static const BorderRadius borderRadiusXl = BorderRadius.all(
    Radius.circular(radiusXl),
  );
  static const BorderRadius borderRadiusXxl = BorderRadius.all(
    Radius.circular(radiusXxl),
  );

  // === SHADOWS — katmanlı, yumuşak (premium görünümün bel kemiği) ===

  /// İnce ayrım gölgesi (küçük butonlar, çipler).
  static const List<BoxShadow> shadowSm = [
    BoxShadow(color: Color(0x0A0F172A), blurRadius: 4, offset: Offset(0, 1)),
  ];

  /// Standart kart gölgesi — iki katman: yakın temas + yumuşak yayılım.
  static const List<BoxShadow> shadow = [
    BoxShadow(color: Color(0x060F172A), blurRadius: 3, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0D1E293B), blurRadius: 18, offset: Offset(0, 6)),
  ];

  /// Vurgulu kart / açılır öğe gölgesi.
  static const List<BoxShadow> shadowLg = [
    BoxShadow(color: Color(0x080F172A), blurRadius: 6, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x141E293B), blurRadius: 36, offset: Offset(0, 14)),
  ];

  /// Lacivert degrade yüzeyler için renkli parlama gölgesi.
  static const List<BoxShadow> shadowPrimary = [
    BoxShadow(
      color: Color(0x5919227D),
      blurRadius: 24,
      offset: Offset(0, 10),
      spreadRadius: -6,
    ),
  ];

  /// Alt navigasyon çubuğunun yukarı doğru yumuşak gölgesi.
  static const List<BoxShadow> shadowNav = [
    BoxShadow(color: Color(0x120F172A), blurRadius: 24, offset: Offset(0, -6)),
  ];

  /// Hero (lacivert degrade başlık) altına düşen renkli gölge.
  static List<BoxShadow> get shadowHero => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.28),
      blurRadius: 28,
      offset: const Offset(0, 12),
      spreadRadius: -10,
    ),
  ];
}
