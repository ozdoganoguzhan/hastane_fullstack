import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'package:hastane_menu/components/async_status.dart';
import 'package:hastane_menu/core/constants/app_colors.dart';
import 'package:hastane_menu/core/constants/app_spacing.dart';
import 'package:hastane_menu/core/constants/app_typography.dart';
import 'package:hastane_menu/core/state/state_manager.dart';
import 'package:hastane_menu/data/hospital_info_service.dart';
import 'package:hastane_menu/models/hospital_info.dart';

/// Yemekhane bilgileri sayfası (çalışma saatleri, konum, iletişim).
/// Veri kaynağı [HospitalInfoService] (dummy/remote).
class InfoPage extends StatefulWidget {
  const InfoPage({super.key});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  final HospitalInfoService _service = $get<HospitalInfoService>();
  late Future<HospitalInfo> _future = _service.get();

  void _reload() {
    setState(() => _future = _service.get(forceRefresh: true));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'ℹ️ Yemekhane Bilgileri',
              style: AppTypography.headingLarge,
            ),
          ),
          FutureBuilder<HospitalInfo>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const MenuLoadingCard(height: 220);
              }
              if (snapshot.hasError) {
                return MenuErrorCard(
                  title: 'Bilgiler yüklenemedi',
                  message: '${snapshot.error}',
                  onRetry: _reload,
                );
              }
              return _InfoCard(info: snapshot.data ?? HospitalInfo.fromConfig());
            },
          ),
          AppSpacing.gapV16,
          const _NetworkDebugCard(),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.info});

  final HospitalInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppSpacing.shadow,
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              gradient: AppColors.redGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_hospital_rounded,
              color: AppColors.white,
              size: 30,
            ),
          ),
          AppSpacing.gapV12,
          Text(
            info.hospitalName,
            textAlign: TextAlign.center,
            style: AppTypography.headingMedium,
          ),
          const SizedBox(height: 2),
          Text(info.subtitle, style: AppTypography.bodySmall),
          AppSpacing.gapV16,
          Text(
            info.description,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall,
          ),
          AppSpacing.gapV16,
          _InfoRow(
            icon: Icons.access_time_rounded,
            title: 'Çalışma Saatleri',
            value: info.workingHours,
          ),
          AppSpacing.gapV8,
          _InfoRow(
            icon: Icons.place_rounded,
            title: 'Konum',
            value: info.location,
          ),
          AppSpacing.gapV8,
          _InfoRow(
            icon: Icons.phone_rounded,
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
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.red, size: 22),
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
                    color: AppColors.text,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppSpacing.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wifi_rounded, color: AppColors.red, size: 22),
              AppSpacing.gapH12,
              const Expanded(
                child: Text('🔧 Ağ Bilgileri (Test)',
                    style: AppTypography.headingMedium),
              ),
              FutureBuilder<Map<String, String?>>(
                future: _future,
                builder: (context, snapshot) => IconButton(
                  tooltip: 'Kopyala',
                  icon: const Icon(Icons.copy_rounded,
                      color: AppColors.red, size: 20),
                  onPressed: snapshot.hasData
                      ? () => _copy(snapshot.data!)
                      : null,
                ),
              ),
              IconButton(
                tooltip: 'Yenile',
                icon: const Icon(Icons.refresh_rounded,
                    color: AppColors.red, size: 20),
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
