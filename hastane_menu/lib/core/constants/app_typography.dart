import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Metin stilleri — kurumsal, sıkı ve hiyerarşisi net bir ölçek.
///
/// Not: Özel font paketlenmemiştir; sistem fontu kullanılır. Başlıklarda hafif
/// negatif letter-spacing, etiketlerde geniş tracking ile "premium" doku verilir.
sealed class AppTypography {
  /// Sayısal değerlerin (kalori, saat) zıplamadan hizalanması için.
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  static const TextStyle displayLarge = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: AppColors.textStrong,
    height: 1.15,
    letterSpacing: -0.6,
  );

  static const TextStyle headingLarge = TextStyle(
    fontSize: 21,
    fontWeight: FontWeight.w800,
    color: AppColors.textStrong,
    height: 1.2,
    letterSpacing: -0.4,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textStrong,
    height: 1.3,
    letterSpacing: -0.2,
  );

  static const TextStyle title = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    height: 1.3,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textLight,
    height: 1.5,
  );

  static const TextStyle label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
    height: 1.4,
  );

  static const TextStyle labelStrong = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColors.textMuted,
    letterSpacing: 0.4,
  );

  /// Bölüm üstü küçük büyük-harf etiket ("BUGÜN", "PERSONEL KARTI").
  static const TextStyle overline = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w800,
    color: AppColors.textMuted,
    letterSpacing: 1.4,
    height: 1.3,
  );

  /// Sayısal istatistik (kalori vb.) — tabular rakamlar.
  static const TextStyle stat = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.textLight,
    fontFeatures: _tabular,
  );
}
