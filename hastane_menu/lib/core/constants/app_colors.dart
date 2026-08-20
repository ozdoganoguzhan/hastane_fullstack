import 'package:flutter/material.dart';

/// Kapari Hazır Yemek uygulamasının renk paleti.
///
/// Kurumsal lacivert (`assets/kapari.png` logosundan örneklendi: #19227D) +
/// logodaki camgöbeği aksan (#05A1E6) + yumuşak nötr zemin.
/// Hardcoded renk YASAKTIR -> her zaman buradan.
sealed class AppColors {
  // === PRIMARY (Kurumsal lacivert — Kapari) ===
  static const Color primary = Color(0xFF19227D);
  static const Color primaryLight = Color(0xFF2E3AA6);
  static const Color primaryDark = Color(0xFF121A5E);
  static const Color primaryDeep = Color(0xFF0B1140);

  /// Lacivertin çok açık zemin tonu (rozet/çip arka planları).
  static const Color primarySoft = Color(0xFFEDEFF9);
  static const Color primarySoftBorder = Color(0xFFD5DAF0);

  // === ACCENT (Logodaki camgöbeği) ===
  static const Color accent = Color(0xFF05A1E6);
  static const Color accentLight = Color(0xFF3CBAF0);
  static const Color accentDark = Color(0xFF0277B8);
  static const Color accentSoft = Color(0xFFE4F4FD);

  // === SURFACE & BACKGROUND ===
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF4F6FA);
  static const Color card = Color(0xFFFFFFFF);

  /// Kart içi ikincil zemin (satır/rozet zeminleri).
  static const Color surfaceTint = Color(0xFFF7F8FC);

  // === TEXT ===
  static const Color textStrong = Color(0xFF0F172A);
  static const Color text = Color(0xFF1E293B);
  static const Color textLight = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // === BORDER & DIVIDER ===
  static const Color border = Color(0xFFE4E8F1);
  static const Color divider = Color(0xFFEDF0F6);

  // === SEMANTIC ===
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFE5F8EE);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0277B8);
  static const Color infoLight = Color(0xFFE4F4FD);

  // === ÖĞÜN AKSAN RENKLERİ (Kahvaltı / Öğle / Akşam) ===
  // Lacivert kurumsal zeminde birbirinden ayrılabilen üç ton: sıcak amber,
  // camgöbeği (marka aksanı) ve mor. Öğle artık kırmızı DEĞİLDİR.
  static const Color breakfast = Color(0xFFD97706);
  static const Color breakfastSoft = Color(0xFFFDF1DC);
  static const Color lunch = Color(0xFF0277B8);
  static const Color lunchSoft = Color(0xFFE4F4FD);
  static const Color dinner = Color(0xFF6D28D9);
  static const Color dinnerSoft = Color(0xFFEFE9FC);

  // === GRADIENTS ===
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient primaryGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary],
  );

  /// Hero başlık degradesi — üstte canlı lacivert, altta derin gece mavisi.
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary, primaryDeep],
    stops: [0.0, 0.45, 1.0],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentLight, accentDark],
  );
}
