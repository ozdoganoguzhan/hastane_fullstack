import 'package:flutter/material.dart';
import 'package:hastane_menu/core/state/session_state.dart';
import 'package:hastane_menu/core/state/state_manager.dart';
import 'package:hastane_menu/pages/login_page.dart';

/// Oturum kapısı — uygulamaya **yalnızca giriş yapıldıktan sonra** erişilir.
///
/// [SessionState]'i dinler; oturum yoksa tam ekran [LoginPage] gösterir, oturum
/// açıldığında [child]'ı (uygulama iskeleti) render eder. `NetworkGate` ile
/// birlikte kullanılır: önce ağ kapısı, sonra oturum kapısı (bkz. AGENTS.md §4,
/// §14).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final session = $get<SessionState>();
    return session.session.builder(
      (value) => value == null ? const LoginPage() : child,
    );
  }
}
