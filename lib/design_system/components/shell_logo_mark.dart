/// Architectural role: Shared design system primitive.
/// The Apex logo mark rendered as a contained asset widget.
/// Used on all shell screens (States 1, 2, 5, 6) — never on content screens.
/// Replaces three identical private _LogoMark classes previously copy-pasted
/// across idle_view, humor_fallback_view, and error_fallback_view.
library;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Sizes the logo mark can be rendered at.
enum LogoMarkSize { small, standard }

class ShellLogoMark extends StatelessWidget {
  const ShellLogoMark({
    super.key,
    this.size = LogoMarkSize.standard,
  });

  final LogoMarkSize size;

  double get _dimension => switch (size) {
        LogoMarkSize.small => 36,
        LogoMarkSize.standard => 44,
      };

  double get _radius => switch (size) {
        LogoMarkSize.small => 10,
        LogoMarkSize.standard => 14,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _dimension,
      height: _dimension,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGlobal.withValues(alpha: 0.08),
            blurRadius: 12,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: Image.asset(
          'assets/images/logo.png',
          width: _dimension,
          height: _dimension,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
