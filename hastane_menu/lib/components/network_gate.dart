import 'package:flutter/material.dart';
import 'package:hastane_menu/components/brand_logo.dart';
import 'package:hastane_menu/components/wifi_blocked_screen.dart';
import 'package:hastane_menu/core/constants/app_colors.dart';
import 'package:hastane_menu/core/constants/app_config.dart';
import 'package:hastane_menu/core/constants/app_spacing.dart';
import 'package:hastane_menu/core/network/wifi_guard.dart';
import 'package:hastane_menu/core/state/session_state.dart';
import 'package:hastane_menu/core/state/state_manager.dart';
import 'package:hastane_menu/pages/login_page.dart';

/// Uygulamayı saran ağ kapısı.
///
/// Yalnızca [WifiGuardStatus.onAllowedWifi] iken [child] (gerçek uygulama)
/// render edilir. Diğer tüm durumlarda tam ekran engelleme gösterilir.
/// Connectivity değiştikçe [WifiGuard] durumu otomatik günceller.
///
/// **Tek istisna — demo oturumu:** [AppConfig.demoBypassesNetworkGate] açıkken
/// engelleme ekranından test girişi yapılabilir ve bu oturum ağ kapısını atlar.
/// Demo oturumu HBYS'ye hiç bağlanmaz (dummy içerik), dolayısıyla asıl kapı
/// olan intranet-only veri erişimi delinmez (bkz. AGENTS.md §4.0).
class NetworkGate extends StatefulWidget {
  const NetworkGate({super.key, required this.child});

  final Widget child;

  @override
  State<NetworkGate> createState() => _NetworkGateState();
}

class _NetworkGateState extends State<NetworkGate> {
  final WifiGuard _guard = $get<WifiGuard>();
  final SessionState _session = $get<SessionState>();

  /// Engelleme ekranından "test girişi" istendi mi?
  bool _demoLoginOpen = false;

  @override
  void initState() {
    super.initState();
    _guard.start();
  }

  bool get _demoBypassAvailable =>
      AppConfig.demoLoginEnabled && AppConfig.demoBypassesNetworkGate;

  @override
  Widget build(BuildContext context) {
    return _session.session.builder((session) {
      // Demo oturumu açıksa ağ durumu ne olursa olsun uygulama gezilebilir.
      if (_demoBypassAvailable && session?.isDemo == true) {
        return widget.child;
      }

      return _guard.status.builder((status) {
        switch (status) {
          case WifiGuardStatus.onAllowedWifi:
            return widget.child;
          case WifiGuardStatus.checking:
          case null:
            return const _CheckingScreen();
          case WifiGuardStatus.notWifi:
          case WifiGuardStatus.wrongWifi:
          case WifiGuardStatus.wrongAccessPoint:
          case WifiGuardStatus.permissionDenied:
          case WifiGuardStatus.locationOff:
          case WifiGuardStatus.ssidUnavailable:
            if (_demoLoginOpen) {
              return LoginPage(
                demoOnly: true,
                onBack: () => setState(() => _demoLoginOpen = false),
              );
            }
            return WifiBlockedScreen(
              status: status,
              currentSsid: _guard.currentSsid,
              onRetry: _guard.refresh,
              // İzin verildiği anda kapı yeniden değerlendirilir; kullanıcının
              // ayrıca "Tekrar Dene"ye basması gerekmez.
              onRequestPermission: _guard.requestPermission,
              onDemoLogin: _demoBypassAvailable
                  ? () => setState(() => _demoLoginOpen = true)
                  : null,
            );
        }
      });
    });
  }
}

/// Markalı açılış/kontrol ekranı — logo + kurum adı + ilerleme göstergesi.
class _CheckingScreen extends StatelessWidget {
  const _CheckingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BrandLogoTile(size: 96, circular: true),
                    AppSpacing.gapV20,
                    const Text(
                      AppConfig.hospitalName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textStrong,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      AppConfig.appSubtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textLight,
                      ),
                    ),
                    AppSpacing.gapV32,
                    const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        color: AppColors.red,
                      ),
                    ),
                    AppSpacing.gapV16,
                    const Text(
                      'Ağ bağlantısı kontrol ediliyor…',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const BrandLogo(size: 14),
                  AppSpacing.gapH8,
                  const Text(
                    'T.C. Sağlık Bakanlığı',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
