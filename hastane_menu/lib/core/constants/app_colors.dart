import 'package:flutter/material.dart';

/// Hastane menü uygulamasının renk paleti.
///
/// Referans HTML mockup'taki kırmızı (T.C. Sağlık Bakanlığı) + lacivert
/// kurumsal tema baz alınmıştır. Hardcoded renk YASAKTIR -> her zaman buradan.
sealed class AppColors {
  // === PRIMARY (Kırmızı / Bakanlık) ===
  static const Color red = Color(0xFFC8102E);
  static const Color redLight = Color(0xFFE8253F);
  static const Color redDark = Color(0xFFA00D24);

  // === SECONDARY (Lacivert / Mavi) ===
  static const Color blue = Color(0xFF1A5CAD);
  static const Color blueLight = Color(0xFF2E7BD6);
  static const Color blueDark = Color(0xFF134A8A);

  // === SURFACE & BACKGROUND ===
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF2F4F7);
  static const Color card = Color(0xFFFFFFFF);

  // === TEXT ===
  static const Color text = Color(0xFF1E293B);
  static const Color textLight = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // === BORDER & DIVIDER ===
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFE2E8F0);

  // === SEMANTIC ===
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF1A5CAD);
  static const Color infoLight = Color(0xFFDBEAFE);

  // === KATEGORİ İKON ARKA PLANLARI (mockup birebir) ===
  static const Color catSoup = Color(0xFFFEF2F2);
  static const Color catMain = Color(0xFFFEE2E2);
  static const Color catSide = Color(0xFFECFDF5);
  static const Color catSalad = Color(0xFFF0FDF4);
  static const Color catDessert = Color(0xFFFDF4FF);
  static const Color catDrink = Color(0xFFEFF6FF);

  // === GRADIENTS ===
  static const LinearGradient redGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [red, redDark],
  );

  static const LinearGradient redGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [red, redLight],
  );
}
