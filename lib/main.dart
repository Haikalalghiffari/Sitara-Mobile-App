import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/login/pages/login_page.dart';

void main() {
  runApp(const SitaraApp());
}

class SitaraApp extends StatelessWidget {
  const SitaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SITARA Health',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const LoginPage(),
    );
  }
}
