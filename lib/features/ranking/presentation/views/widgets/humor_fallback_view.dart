/// Architectural role: State 5 — Humor Fallback UI.
/// Renders the witty rejection message and redirect suggestion chips.
/// Stateless — state and callbacks passed from HomeScreen coordinator.
library;

import 'package:flutter/material.dart';
import '../../../../../design_system/components/suggestion_chip.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_typography.dart';
import '../../notifiers/ranking_notifier.dart';

class HumorFallbackView extends StatelessWidget {
  const HumorFallbackView({
    super.key,
    required this.state,
    required this.onChipTap,
    required this.onClear,
  });

  final HumorState state;
  final ValueChanged<String> onChipTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.payload.message,
            style: AppTypography.screenTitle,
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state.payload.suggestions
                .map((s) => ApexSuggestionChip(
                      label: s,
                      onTap: () => onChipTap(s),
                    ))
                .toList(),
          ),
          const SizedBox(height: 32),
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
