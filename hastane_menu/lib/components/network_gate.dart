import 'package:flutter/material.dart';
import 'package:hastane_menu/components/wifi_blocked_screen.dart';
import 'package:hastane_menu/core/constants/app_colors.dart';
import 'package:hastane_menu/core/network/wifi_guard.dart';
import 'package:hastane_menu/core/state/state_manager.dart';

/// Uygulamayı saran ağ kapısı.
///
/// Yalnızca [WifiGuardStatus.onAllowedWifi] iken [child] (gerçek uygulama)
/// render edilir. Diğer tüm durumlarda tam ekran engelleme gösterilir.
/// Connectivity değiştikçe [WifiGuard] durumu otomatik günceller.
class NetworkGate extends StatefulWidget {
  const NetworkGate({super.key, required this.child});

  final Widget child;

  @override
  State<NetworkGate> createState() => _NetworkGateState();
}

class _NetworkGateState extends State<NetworkGate> {
  final WifiGuard _guard = $get<WifiGuard>();

  @override
  void initState() {
    super.initState();
    _guard.start();
  }

  @override
  Widget build(BuildContext context) {
    return _guard.status.builder((status) {
      switch (status) {
        case WifiGuardStatus.onAllowedWifi:
          return widget.child;
        case WifiGuardStatus.checking:
        case null:
          return const _CheckingScreen();
        case WifiGuardStatus.notWifi:
        case WifiGuardStatus.wrongWifi:
        case WifiGuardStatus.permissionDenied:
        case WifiGuardStatus.locationOff:
          return WifiBlockedScreen(
            status: status,
            onRetry: _guard.refresh,
            onRequestPermission: _guard.requestPermission,
          );
      }
    });
  }
}

class _CheckingScreen extends StatelessWidget {
  const _CheckingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.red),
            SizedBox(height: 16),
            Text(
              'Ağ bağlantısı kontrol ediliyor…',
              style: TextStyle(color: AppColors.textLight, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
