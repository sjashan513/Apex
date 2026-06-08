/// Architectural role: State 6 — Error UI.
/// Renders contextual error message with retry and clear actions.
/// Stateless — error object and callbacks passed from HomeScreen coordinator.
library;

import 'package:flutter/material.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_typography.dart';
import '../../../../../core/exceptions/domain_exceptions.dart';

class ErrorFallbackView extends StatelessWidget {
  const ErrorFallbackView({
    super.key,
    required this.error,
    required this.onRetry,
    required this.onClear,
  });

  final Object error;
  final VoidCallback onRetry;
  final VoidCallback onClear;

  String get _message {
    if (error is DomainException) {
      return (error as DomainException).message;
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_message, style: AppTypography.screenTitle),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.accentGlobal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Try again',
                style: AppTypography.body.copyWith(
                  color: AppColors.canvas,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onClear,
            child: Text(
              'Start over',
              style: AppTypography.body.copyWith(
                color: AppColors.textGhost,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.textGhost,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
