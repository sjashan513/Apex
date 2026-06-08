/// Architectural role: Application root.
/// Configures MaterialApp, injects the global theme, and owns the router.
/// No business logic lives here — routing and theme only.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'design_system/theme/app_colors.dart';
import 'design_system/theme/app_typography.dart';

class ApexApp extends StatelessWidget {
  const ApexApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Lock orientation to portrait — mobile-first product decision
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // Force dark status bar icons against our dark canvas
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return MaterialApp(
      title: 'Apex',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      // Temporary home — GoRouter replaces this in the next step
      home: const Scaffold(
        backgroundColor: AppColors.canvas,
        body: Center(
          child: Text(
            'Apex',
            style: AppTypography.heroTitle,
          ),
        ),
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.canvas,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surface,
        primary: AppColors.accentGlobal,
        error: AppColors.error,
      ),
      fontFamily: 'Inter',
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }
}
