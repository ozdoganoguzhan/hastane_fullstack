import 'package:flutter/material.dart';

/// Hastane menü uygulamasının renk paleti.
///
/// T.C. Sağlık Bakanlığı kurumsal kırmızısı + lacivert + yumuşak nötr zemin.
/// Hardcoded renk YASAKTIR -> her zaman buradan.
sealed class AppColors {
  // === PRIMARY (Kırmızı / T.C. Sağlık Bakanlığı) ===
  static const Color red = Color(0xFFC8102E);
  static const Color redLight = Color(0xFFE8253F);
  static const Color redDark = Color(0xFFA00D24);
  static const Color redDeep = Color(0xFF7E0A1E);

  /// Kırmızının çok açık zemin tonu (rozet/çip arka planları).
  static const Color redSoft = Color(0xFFFDECEF);
  static const Color redSoftBorder = Color(0xFFF6D3DA);

  // === SECONDARY (Lacivert / Mavi) ===
  static const Color blue = Color(0xFF1A5CAD);
  static const Color blueLight = Color(0xFF2E7BD6);
  static const Color blueDark = Color(0xFF134A8A);
  static const Color blueSoft = Color(0xFFEAF2FB);

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
  static const Color info = Color(0xFF1A5CAD);
  static const Color infoLight = Color(0xFFDBEAFE);

  // === ÖĞÜN AKSAN RENKLERİ (Kahvaltı / Öğle / Akşam) ===
  static const Color breakfast = Color(0xFFD97706);
  static const Color breakfastSoft = Color(0xFFFDF1DC);
  static const Color lunch = Color(0xFFC8102E);
  static const Color lunchSoft = Color(0xFFFDECEF);
  static const Color dinner = Color(0xFF4F46E5);
  static const Color dinnerSoft = Color(0xFFEAE9FC);

  // === GRADIENTS ===
  static const LinearGradient redGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [red, redDark],
  );

  static const LinearGradient redGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [redLight, red],
  );

  /// Hero başlık degradesi — üstte canlı, altta derin kurumsal kırmızı.
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [redLight, red, redDeep],
    stops: [0.0, 0.45, 1.0],
  );

  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blueLight, blueDark],
  );
}
