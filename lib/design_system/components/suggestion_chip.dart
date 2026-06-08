/// Architectural role: Shared design system component.
/// Query shortcut chip used on State 1 (Idle) and State 5 (Humor Fallback).
/// Stateless — parent owns active/disabled state.
/// Tap target enforced at 48×48dp minimum per Design Contract §03.
library;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class ApexSuggestionChip extends StatelessWidget {
  const ApexSuggestionChip({
    super.key,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.isDisabled = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final bool isDisabled;

  // Design Contract §03 — minimum tap target
  static const double _minTapTarget = 48;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _minTapTarget),
      child: GestureDetector(
        onTap: isDisabled ? null : onTap,
        child: AnimatedContainer(
          // duration.fast — 150ms per Design Contract §05
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8, // spacing.sm per Design Contract §03
          ),
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(8), // radius.sm
            border: Border.all(
              color: _borderColor,
              width: 0.5, // Design Contract §01
            ),
          ),
          child: Text(
            label,
            style: AppTypography.body.copyWith(
              color: _textColor,
            ),
          ),
        ),
      ),
    );
  }

  Color get _backgroundColor {
    if (isDisabled) return AppColors.surfaceRaised.withValues(alpha: 0.5);
    if (isActive) return AppColors.accentGlobal.withValues(alpha: 0.08);
    return AppColors.surfaceRaised;
  }

  Color get _borderColor {
    if (isDisabled) return AppColors.border.withValues(alpha: 0.3);
    if (isActive) return AppColors.accentGlobal.withValues(alpha: 0.4);
    return AppColors.border;
  }

  Color get _textColor {
    if (isDisabled) return AppColors.textGhost;
    if (isActive) return AppColors.textPrimary;
    return AppColors.textSecondary;
  }
}
