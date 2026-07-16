import 'package:hastane_menu/core/network/hbys_client.dart';
import 'package:hastane_menu/core/network/wifi_guard.dart';
import 'package:hastane_menu/core/state/session_state.dart';
import 'package:hastane_menu/core/state/state_manager.dart';
import 'package:hastane_menu/data/auth_service.dart';
import 'package:hastane_menu/data/menu_service.dart';

/// Tüm servisleri uygulama başlangıcında kayıt eder. `main.dart`'tan çağrılır.
void setupServiceLocator() {
  // Ağ kapısı servisi — uygulama içeriğini saran NetworkGate bunu dinler.
  SM.register<WifiGuard>(WifiGuard());

  // ⭐ Turkcell HBYS'ye DOĞRUDAN bağlanan istemci (araya bizim API'miz girmez).
  // Token'ı kendi yönetir; host'lar AppConfig.useMockHbys ile seçilir.
  final hbys = HbysClient();
  SM.register<HbysClient>(hbys);

  // Giriş akışı — personel kartı HBYS'den çekilir.
  SM.register<AuthService>(AuthService(client: hbys));
  SM.register<SessionState>(SessionState());

  // Menü — HBYS + 10 dk kayan süreli bellek önbelleği.
  SM.register<MenuService>(MenuService(client: hbys));
}
