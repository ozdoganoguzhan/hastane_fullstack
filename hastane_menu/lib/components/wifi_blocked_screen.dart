import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:hastane_menu/components/app_button.dart';
import 'package:hastane_menu/components/brand_logo.dart';
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
    this.currentSsid,
    this.onDemoLogin,
  });

  final WifiGuardStatus status;
  final VoidCallback onRetry;
  final Future<void> Function() onRequestPermission;

  /// Okunabildiyse cihazın ŞU AN bağlı olduğu ağ adı — kullanıcıya neden
  /// engellendiğini somut olarak göstermek için.
  final String? currentSsid;

  /// Ağ dışında test/demo girişine geçiş. `null` ise buton gösterilmez.
  final VoidCallback? onDemoLogin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Üstte kurumsal marka satırı.
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const BrandLogo(size: 22),
                  AppSpacing.gapH8,
                  const Text(
                    AppConfig.hospitalName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textLight,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Katmanlı ikon — yumuşak halkalar içinde durum ikonu.
                      Container(
                        width: 108,
                        height: 108,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                          width: 82,
                          height: 82,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.errorLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_icon, size: 38, color: AppColors.red),
                        ),
                      ),
                      AppSpacing.gapV24,
                      Text(
                        _title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textStrong,
                          letterSpacing: -0.4,
                          height: 1.25,
                        ),
                      ),
                      AppSpacing.gapV12,
                      Text(
                        _body,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.55,
                          color: AppColors.textLight,
                        ),
                      ),
                      AppSpacing.gapV24,
                      _NetworkChips(
                        expected: AppConfig.displayNetworkName,
                        current: currentSsid,
                      ),
                      AppSpacing.gapV32,
                      AppButton(
                        label: 'Tekrar Dene',
                        icon: Icons.refresh_rounded,
                        onPressed: onRetry,
                      ),
                      if (_secondaryAction != null) ...[
                        AppSpacing.gapV8,
                        TextButton(
                          onPressed: _secondaryAction!.onPressed,
                          child: Text(_secondaryAction!.label),
                        ),
                      ],
                      // Ağ dışındayken tek çıkış yolu: test/demo oturumu.
                      if (onDemoLogin != null) ...[
                        AppSpacing.gapV16,
                        const Divider(color: AppColors.divider, height: 1),
                        AppSpacing.gapV12,
                        TextButton.icon(
                          onPressed: onDemoLogin,
                          icon: const Icon(Icons.science_rounded, size: 18),
                          label: const Text('Test girişi ile devam et'),
                        ),
                        AppSpacing.gapV4,
                        const Text(
                          'Test oturumunda gerçek hastane verisi değil, '
                          'örnek içerik gösterilir.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.45,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData get _icon => switch (status) {
    WifiGuardStatus.locationOff => Icons.location_off_rounded,
    WifiGuardStatus.permissionDenied => Icons.lock_outline_rounded,
    WifiGuardStatus.ssidUnavailable => Icons.help_outline_rounded,
    _ => Icons.wifi_off_rounded,
  };

  String get _title => switch (status) {
    WifiGuardStatus.notWifi => 'Hastane Wi-Fi ağına bağlı değilsiniz',
    WifiGuardStatus.wrongWifi => 'Yanlış Wi-Fi ağındasınız',
    WifiGuardStatus.wrongAccessPoint => 'Hastane erişim noktasında değilsiniz',
    WifiGuardStatus.permissionDenied => 'Konum izni gerekiyor',
    WifiGuardStatus.locationOff => 'Konum servisleri kapalı',
    WifiGuardStatus.ssidUnavailable => 'Ağ adı doğrulanamıyor',
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
      'Hangi Wi-Fi ağına bağlı olduğunuzu okuyabilmemiz için Android konum '
          'izni istiyor. İzin verilmeden ağ adı görülemez.',
    WifiGuardStatus.locationOff =>
      'İzin verilmiş olsa bile, konum servisleri kapalıyken Android ağ adını '
          'gizler. Lütfen cihazınızın konum servislerini açın.',
    // ⚠️ İzin VAR, konum AÇIK ama OS yine de vermiyor → kullanıcıdan
    // isteyebileceğimiz bir şey kalmadı; dürüst ol ve çıkış yolu sun.
    WifiGuardStatus.ssidUnavailable =>
      'Gerekli izinler verilmiş olmasına rağmen cihazınız bağlı olduğunuz ağın '
          'adını paylaşmıyor. Hastane ağındaysanız tekrar deneyin; sorun '
          'sürerse yemekhane ile iletişime geçin.',
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
    WifiGuardStatus.ssidUnavailable => _SecondaryAction(
      label: 'Uygulama ayarlarını aç',
      onPressed: () => AppSettings.openAppSettings(),
    ),
    _ => null,
  };
}

class _SecondaryAction {
  const _SecondaryAction({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;
}

/// Beklenen ağ + (okunabildiyse) şu an bağlı olunan ağ.
///
/// Ağ adı okunamadığında ikinci çip gösterilmez — "bilmiyorum"u "yanlış
/// ağdasın" gibi sunmamak için.
class _NetworkChips extends StatelessWidget {
  const _NetworkChips({required this.expected, this.current});

  final String expected;
  final String? current;

  @override
  Widget build(BuildContext context) {
    final showCurrent = current != null && current!.trim().isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Chip(
          icon: Icons.wifi_rounded,
          label: 'Beklenen ağ: $expected',
          background: AppColors.blueSoft,
          border: AppColors.blue,
          foreground: AppColors.blueDark,
        ),
        if (showCurrent) ...[
          AppSpacing.gapV8,
          _Chip(
            icon: Icons.wifi_tethering_error_rounded,
            label: 'Bağlı olduğunuz ağ: ${current!}',
            background: AppColors.redSoft,
            border: AppColors.red,
            foreground: AppColors.redDark,
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.background,
    required this.border,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color border;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
        border: Border.all(color: border.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: border),
          AppSpacing.gapH8,
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
