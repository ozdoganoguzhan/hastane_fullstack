import 'package:flutter/material.dart';
import 'package:hastane_menu/components/brand_logo.dart';
import 'package:hastane_menu/core/constants/app_colors.dart';
import 'package:hastane_menu/core/constants/app_config.dart';
import 'package:hastane_menu/core/constants/app_spacing.dart';
import 'package:hastane_menu/core/utils/date_utils.dart';

/// Ana sayfa hero başlığı — kurumsal lacivert degrade, Kapari logosu
/// filigranı, kişisel selamlama, tarih ve servis durumu çipi.
class AppHeader extends StatelessWidget {
  const AppHeader({super.key, this.date, this.bottomOverlap = 0});

  /// Gösterilecek tarih (varsayılan: bugün).
  final DateTime? date;

  /// Hero'nun altına bindirilecek içerik için ek alt boşluk
  /// (kart, `Transform.translate` ile bu alana çekilir).
  final double bottomOverlap;

  /// Saate göre selamlama.
  static String greeting(int hour) {
    if (hour >= 6 && hour < 12) return 'Günaydın';
    if (hour >= 12 && hour < 18) return 'İyi günler';
    if (hour >= 18 && hour < 23) return 'İyi akşamlar';
    return 'İyi geceler';
  }

  /// Saate göre aktif/sıradaki yemekhane servisi.
  static ({String emoji, String label}) service(int hour) {
    if (hour >= 6 && hour < 11) return (emoji: '🌅', label: 'Kahvaltı servisi');
    if (hour >= 11 && hour < 15) return (emoji: '☀️', label: 'Öğle servisi');
    if (hour >= 15 && hour < 21) return (emoji: '🌙', label: 'Akşam servisi');
    return (emoji: '🌟', label: 'Servis saatleri dışı');
  }

  @override
  Widget build(BuildContext context) {
    final DateTime today = date ?? DateTime.now();
    final serviceInfo = service(today.hour);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppSpacing.radiusHero),
        ),
        boxShadow: AppSpacing.shadowHero,
      ),
      child: Stack(
        children: [
          // Kapari wordmark filigranı — kurumsal doku.
          Positioned(
            right: -60,
            bottom: -40,
            child: BrandLogo(
              height: 132,
              color: AppColors.white.withValues(alpha: 0.07),
            ),
          ),
          Positioned(top: -80, left: -50, child: _circle(200, 0.05)),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              MediaQuery.of(context).padding.top + AppSpacing.base,
              AppSpacing.lg,
              AppSpacing.xl + bottomOverlap,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Marka kimliği ────────────────────────────────────────
                // Wordmark markanın adını zaten taşır; yanına "Kapari Hazır
                // Yemek" yazmak tekrar olurdu → yalnızca alt başlık.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BrandLogo(height: 30, color: AppColors.white),
                    const SizedBox(height: 6),
                    Text(
                      AppConfig.appSubtitle,
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.75),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapV24,
                // ── Selamlama + tarih (kişisel bilgi GÖSTERİLMEZ) ────────
                Text(
                  '${greeting(today.hour)} 👋',
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppDateUtils.longDate(today),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    height: 1.2,
                  ),
                ),
                AppSpacing.gapV12,
                // ── Servis durumu çipi ───────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        serviceInfo.emoji,
                        style: const TextStyle(fontSize: 12),
                      ),
                      AppSpacing.gapH8,
                      Text(
                        serviceInfo.label,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, double opacity) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: AppColors.white.withValues(alpha: opacity),
      shape: BoxShape.circle,
    ),
  );
}
