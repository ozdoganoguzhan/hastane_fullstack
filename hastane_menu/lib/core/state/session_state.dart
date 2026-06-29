import 'package:hastane_menu/core/state/state_manager.dart';
import 'package:hastane_menu/models/staff_session.dart';

/// Giriş yapan personelin oturumunu tutan reaktif servis.
///
/// Şimdilik bellek içidir (uygulama kapanınca sıfırlanır). Kalıcılık istenirse
/// ileride güvenli depolama eklenebilir.
class SessionState {
  final ReactiveState<StaffSession?> session = ReactiveState<StaffSession?>(
    null,
  );

  StaffSession? get current => session.value;
  bool get isLoggedIn => session.value != null;

  void setSession(StaffSession value) => session.value = value;
  void logout() => session.value = null;
}
