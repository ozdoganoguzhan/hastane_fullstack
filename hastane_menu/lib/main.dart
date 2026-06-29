import 'package:flutter/material.dart';
import 'package:hastane_menu/app/app.dart';
import 'package:hastane_menu/app/service_locator.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupServiceLocator();
  runApp(const HastaneMenuApp());
}
