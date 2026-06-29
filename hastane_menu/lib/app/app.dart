import 'package:flutter/material.dart';
import 'package:hastane_menu/app/app_theme.dart';
import 'package:hastane_menu/components/auth_gate.dart';
import 'package:hastane_menu/components/network_gate.dart';
import 'package:hastane_menu/pages/shell_page.dart';

/// Uygulamanın kök widget'ı.
///
/// İçerik iki kapı ile sarılır (bkz. AGENTS.md §4, §14):
///  1. [NetworkGate] — uygulama YALNIZCA izinli hastane WiFi ağındayken çalışır.
///  2. [AuthGate]    — ağ geçildikten sonra giriş yapılmadan içeriğe erişilemez.
class HastaneMenuApp extends StatelessWidget {
  const HastaneMenuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hastane Menü',
      debugShowCheckedModeBanner: false,
      theme: HospitalTheme.light(),
      home: const NetworkGate(child: AuthGate(child: ShellPage())),
    );
  }
}
