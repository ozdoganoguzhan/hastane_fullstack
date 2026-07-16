import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:hastane_menu/core/constants/app_colors.dart';
import 'package:hastane_menu/core/constants/app_config.dart';
import 'package:hastane_menu/core/constants/app_spacing.dart';
import 'package:hastane_menu/core/network/wifi_guard.dart';

/// Cihaz izinli hastane WiFi'ında değilken gösterilen tam ekran engelleme.
///
/// Geri tuşu / app bar yoktur — kapatılamaz. Durum'a göre mesaj ve ikincil
/// aksiyon (WiFi ayarları / konum / izin) değişir.
class WifiBlockedScreen extends StatelessWidget {
  const WifiBlockedScreen({
    super.key,
    required this.status,
    required this.onRetry,
    required this.onRequestPermission,
  });

  final WifiGuardStatus status;
  final VoidCallback onRetry;
  final Future<void> Function() onRequestPermission;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: AppColors.errorLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_icon, size: 48, color: AppColors.red),
                ),
                AppSpacing.gapV24,
                Text(
                  _title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                AppSpacing.gapV12,
                Text(
                  _body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textLight,
                  ),
                ),
                AppSpacing.gapV24,
                _ExpectedNetworkChip(name: AppConfig.displayNetworkName),
                AppSpacing.gapV32,
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 20),
                    label: const Text('Tekrar Dene'),
                  ),
                ),
                if (_secondaryAction != null) ...[
                  AppSpacing.gapV8,
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _secondaryAction!.onPressed,
                      child: Text(_secondaryAction!.label),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData get _icon => switch (status) {
    WifiGuardStatus.locationOff => Icons.location_off,
    WifiGuardStatus.permissionDenied => Icons.lock_outline,
    _ => Icons.wifi_off,
  };

  String get _title => switch (status) {
    WifiGuardStatus.notWifi => 'Hastane Wi-Fi ağına bağlı değilsiniz',
    WifiGuardStatus.wrongWifi => 'Yanlış Wi-Fi ağındasınız',
    WifiGuardStatus.wrongAccessPoint => 'Hastane erişim noktasında değilsiniz',
    WifiGuardStatus.permissionDenied => 'Konum izni gerekiyor',
    WifiGuardStatus.locationOff => 'Konum servisleri kapalı',
    _ => 'Bağlantı kontrol ediliyor',
  };

  String get _body => switch (status) {
    WifiGuardStatus.notWifi =>
      'Menüyü görüntülemek için lütfen hastanenin Wi-Fi ağına bağlanın. '
          'Şu anda mobil veri kullanıyor olabilirsiniz.',
    WifiGuardStatus.wrongWifi =>
      'Bu uygulama yalnızca hastane Wi-Fi ağına bağlıyken çalışır. '
          'Lütfen doğru ağa bağlandığınızdan emin olun.',
    WifiGuardStatus.wrongAccessPoint =>
      'Ağ adı doğru görünüyor ancak bağlı olduğunuz erişim noktası hastaneye '
          'ait değil. Lütfen hastane içindeki resmi Wi-Fi noktasına bağlanın.',
    WifiGuardStatus.permissionDenied =>
      'Bağlı olduğunuz ağın adını doğrulayabilmemiz için konum iznine '
          'ihtiyacımız var. Lütfen izni verin.',
    WifiGuardStatus.locationOff =>
      'Bağlı olduğunuz ağın adını doğrulayabilmemiz için cihazınızın '
          'konum servislerini açın.',
    _ => '',
  };

  _SecondaryAction? get _secondaryAction => switch (status) {
    WifiGuardStatus.notWifi ||
    WifiGuardStatus.wrongWifi ||
    WifiGuardStatus.wrongAccessPoint => _SecondaryAction(
      label: 'Wi-Fi ayarlarını aç',
      onPressed: () => AppSettings.openAppSettings(type: AppSettingsType.wifi),
    ),
    WifiGuardStatus.locationOff => _SecondaryAction(
      label: 'Konum servislerini aç',
      onPressed: () =>
          AppSettings.openAppSettings(type: AppSettingsType.location),
    ),
    WifiGuardStatus.permissionDenied => _SecondaryAction(
      label: 'İzin Ver',
      onPressed: onRequestPermission,
    ),
    _ => null,
  };
}

class _SecondaryAction {
  const _SecondaryAction({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;
}

class _ExpectedNetworkChip extends StatelessWidget {
  const _ExpectedNetworkChip({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: AppSpacing.borderRadiusSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi, size: 16, color: AppColors.blue),
          AppSpacing.gapH8,
          Text(
            'Beklenen ağ: $name',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.blueDark,
            ),
          ),
        ],
      ),
    );
  }
}
