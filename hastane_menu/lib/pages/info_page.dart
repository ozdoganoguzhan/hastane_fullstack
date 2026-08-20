import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'package:hastane_menu/components/app_button.dart';
import 'package:hastane_menu/components/async_status.dart';
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
          // AppSpacing.gapV16,
          // const _NetworkDebugCard(),
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

/// TEST/DEBUG: `network_info_plus`'ın okuyabildiği tüm ağ bilgilerini gösterir
/// (WiFi adı, BSSID, IP, gateway, subnet vb.). Yalnızca tanılama amaçlıdır;
/// canlıya çıkmadan kaldırılabilir.
class _NetworkDebugCard extends StatefulWidget {
  const _NetworkDebugCard();

  @override
  State<_NetworkDebugCard> createState() => _NetworkDebugCardState();
}

class _NetworkDebugCardState extends State<_NetworkDebugCard> {
  final NetworkInfo _netInfo = NetworkInfo();
  late Future<Map<String, String?>> _future = _load();

  Future<Map<String, String?>> _load() async {
    // Her bir okuma birbirinden bağımsız; biri patlasa diğerleri görünsün diye
    // hepsini tek tek best-effort topluyoruz.
    Future<String?> safe(Future<String?> Function() fn) async {
      try {
        return await fn();
      } catch (e) {
        return 'HATA: $e';
      }
    }

    return {
      'WiFi Adı (SSID)': await safe(_netInfo.getWifiName),
      'BSSID': await safe(_netInfo.getWifiBSSID),
      'IP Adresi (IPv4)': await safe(_netInfo.getWifiIP),
      'IP Adresi (IPv6)': await safe(_netInfo.getWifiIPv6),
      'Subnet Mask': await safe(_netInfo.getWifiSubmask),
      'Broadcast': await safe(_netInfo.getWifiBroadcast),
      'Gateway IP': await safe(_netInfo.getWifiGatewayIP),
    };
  }

  void _reload() => setState(() => _future = _load());

  void _copy(Map<String, String?> data) {
    final text = data.entries
        .map((e) => '${e.key}: ${e.value ?? "—"}')
        .join('\n');
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ağ bilgileri panoya kopyalandı')),
      );
    }
  }

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: const Icon(
                  Icons.wifi_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              AppSpacing.gapH12,
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ağ Bilgileri', style: AppTypography.headingMedium),
                    SizedBox(height: 1),
                    Text('Tanılama (test)', style: AppTypography.bodySmall),
                  ],
                ),
              ),
              FutureBuilder<Map<String, String?>>(
                future: _future,
                builder: (context, snapshot) => IconButton(
                  tooltip: 'Kopyala',
                  icon: const Icon(
                    Icons.copy_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  onPressed: snapshot.hasData
                      ? () => _copy(snapshot.data!)
                      : null,
                ),
              ),
              IconButton(
                tooltip: 'Yenile',
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                onPressed: _reload,
              ),
            ],
          ),
          AppSpacing.gapV12,
          FutureBuilder<Map<String, String?>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const MenuLoadingCard(height: 160);
              }
              final data = snapshot.data ?? const {};
              return Column(
                children: [
                  for (final entry in data.entries) ...[
                    _InfoRow(
                      icon: Icons.lan_rounded,
                      title: entry.key,
                      value: (entry.value == null || entry.value!.isEmpty)
                          ? '—'
                          : entry.value!,
                    ),
                    AppSpacing.gapV8,
                  ],
                ],
              );
            },
          ),
        ],
      ),
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
                            ? 'Test oturumu — örnek veriler'
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
