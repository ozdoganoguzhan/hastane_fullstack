import 'package:hastane_menu/core/network/wifi_guard.dart';
import 'package:hastane_menu/core/state/session_state.dart';
import 'package:hastane_menu/core/state/state_manager.dart';
import 'package:hastane_menu/data/announcement_repository.dart';
import 'package:hastane_menu/data/announcement_service.dart';
import 'package:hastane_menu/data/auth_service.dart';
import 'package:hastane_menu/data/hospital_info_repository.dart';
import 'package:hastane_menu/data/hospital_info_service.dart';
import 'package:hastane_menu/data/menu_repository.dart';
import 'package:hastane_menu/data/menu_service.dart';

/// Tüm servisleri uygulama başlangıcında kayıt eder. `main.dart`'tan çağrılır.
void setupServiceLocator() {
  // Ağ kapısı servisi — uygulama içeriğini saran NetworkGate bunu dinler.
  SM.register<WifiGuard>(WifiGuard());

  // Giriş (2FA) akışı.
  SM.register<AuthService>(AuthService());
  SM.register<SessionState>(SessionState());

  // Menü erişimi — dummy + kendi REST API'miz (remote). Aktif kaynağı
  // MenuService oturuma/config'e göre seçer (bkz. §15).
  SM.register<MenuService>(
    MenuService(
      dummy: const DummyMenuRepository(),
      remote: RemoteMenuRepository(),
    ),
  );

  // Duyurular — menü ile aynı desen (dummy + remote, kaynağı servis seçer).
  SM.register<AnnouncementService>(
    AnnouncementService(
      dummy: const DummyAnnouncementRepository(),
      remote: RemoteAnnouncementRepository(),
    ),
  );

  // Hastane bilgisi (Bilgi sayfası) — dummy (AppConfig) + remote.
  SM.register<HospitalInfoService>(
    HospitalInfoService(
      dummy: const DummyHospitalInfoRepository(),
      remote: RemoteHospitalInfoRepository(),
    ),
  );
}
