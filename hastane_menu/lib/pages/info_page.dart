import 'package:flutter/material.dart';

import 'package:hastane_menu/components/app_button.dart';
import 'package:hastane_menu/components/brand_logo.dart';
import 'package:hastane_menu/components/page_header.dart';
import 'package:hastane_menu/core/constants/app_colors.dart';
import 'package:hastane_menu/core/constants/app_spacing.dart';
import 'package:hastane_menu/core/constants/app_typography.dart';
import 'package:hastane_menu/core/state/session_state.dart';
import 'package:hastane_menu/core/state/state_manager.dart';
import 'package:hastane_menu/models/brand_info.dart';

/// Yemekhane bilgileri sayfası (çalışma saatleri, konum, iletişim).
///
/// Veri kaynağı [AppConfig]'tir: Turkcell HBYS dokümanında hastane bilgisi ucu
/// yoktur ve yönetici paneli kaldırılmıştır → tek merkez config'tir.
class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: AppSpacing.paddingAllBase,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: PageHeader(
              title: 'Yemekhane Bilgileri',
              subtitle: 'Çalışma saatleri, konum ve iletişim',
            ),
          ),
          _InfoCard(info: BrandInfo.fromConfig()),
          AppSpacing.gapV16,
          const _SessionCard(),
          AppSpacing.gapV24,
          const _BrandFooter(),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.info});

  final BrandInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: AppSpacing.borderRadiusXl,
        boxShadow: AppSpacing.shadow,
      ),
      child: Column(
        children: [
          BrandLogo(height: 38),
          AppSpacing.gapV12,
          Text(info.subtitle, style: AppTypography.bodySmall),
          AppSpacing.gapV16,
          // Açıklama — yumuşak zeminli alıntı kutusu.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: Text(
              info.description,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall,
            ),
          ),
          AppSpacing.gapV16,
          _InfoRow(
            icon: Icons.access_time_rounded,
            iconColor: AppColors.accent,
            iconBackground: AppColors.accentSoft,
            title: 'Çalışma Saatleri',
            value: info.workingHours,
          ),
          AppSpacing.gapV8,
          _InfoRow(
            icon: Icons.place_rounded,
            iconColor: AppColors.primary,
            iconBackground: AppColors.primarySoft,
            title: 'Konum',
            value: info.location,
          ),
          AppSpacing.gapV8,
          _InfoRow(
            icon: Icons.phone_rounded,
            iconColor: AppColors.success,
            iconBackground: AppColors.successLight,
            title: 'İletişim',
            value: info.contact,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    this.iconColor = AppColors.accent,
    this.iconBackground = AppColors.accentSoft,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color iconColor;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          AppSpacing.gapH12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textStrong,
                  ),
                ),
                const SizedBox(height: 1),
                Text(value, style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sayfa sonundaki kurumsal imza.
class _BrandFooter extends StatelessWidget {
  const _BrandFooter();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const BrandLogo(height: 16),
      ],
    );
  }
}

/// Açık oturumu gösterip **çıkış** imkânı veren kart.
///
/// Çıkış eskiden yalnızca QR sheet'inin içindeydi; kullanıcının çıkmak için
/// önce QR kodunu açması gerekiyordu. Buraya taşındı (bkz. AGENTS.md §14).
/// Oturum yoksa hiç render edilmez — `AuthGate` zaten girişe döndürür.
class _SessionCard extends StatelessWidget {
  const _SessionCard();

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Çıkış yapılsın mı?'),
        content: const Text(
          'Oturumunuz kapatılacak ve yemekhane QR kodunuz görüntülenemeyecek. '
          'Tekrar giriş yapmanız gerekir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Çıkış Yap',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );

    if (confirmed ?? false) $get<SessionState>().logout();
  }

  @override
  Widget build(BuildContext context) {
    return $get<SessionState>().session.builder((session) {
      if (session == null) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: AppSpacing.borderRadiusXl,
          boxShadow: AppSpacing.shadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.white,
                    size: 22,
                  ),
                ),
                AppSpacing.gapH12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.fullName,
                        style: AppTypography.headingMedium,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        session.isDemo
                            ? 'Yönetici oturumu'
                            : '${session.title} • ${session.maskedPhone}',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AppSpacing.gapV16,
            AppButton(
              label: 'Çıkış Yap',
              icon: Icons.logout_rounded,
              variant: AppButtonVariant.soft,
              onPressed: () => _confirmLogout(context),
            ),
          ],
        ),
      );
    });
  }
}
