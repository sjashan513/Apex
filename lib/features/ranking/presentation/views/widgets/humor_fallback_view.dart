/// Architectural role: State 5 — Humor Fallback UI.
/// Renders witty rejection with logo, eyebrow, open search, and archetype chips.
/// Logo is top-left. Message block is centered. Chips grouped by archetype.
library;

import 'package:apex/features/ranking/domain/models/ranking_model.dart';
import 'package:flutter/material.dart';
import '../../../../../design_system/components/search_input.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_typography.dart';
import '../../notifiers/ranking_notifier.dart';

// ── Static archetype chip data ─────────────────────────────────────────────

// ── Component ──────────────────────────────────────────────────────────────

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top section ──────────────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 18),

                // Logo — top left
                _LogoMark(),

                const Spacer(),

                // Message block — centered
                Center(
                  child: Column(
                    children: [
                      // Eyebrow with divider lines
                      const _EyebrowDivider(
                        label: 'not a ranking question',
                      ),

                      const SizedBox(height: 14),

                      // Title
                      const Text(
                        "Apex ranks things.\nThat wasn't one of them.",
                        style: AppTypography.screenTitle,
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 10),

                      // Humor message from API — quoted
                      Text(
                        state.payload.message,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textGhost,
                          height: 1.65,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 28),

                      // Open search input — lets user retry immediately
                      SearchInput(onSubmit: onChipTap),
                    ],
                  ),
                ),

                const Spacer(),
              ],
            ),
          ),
        ),

        // ── Bottom section — archetype chips ─────────────────────────────
        // ── Bottom section — dynamic API suggestions ──────────────────────────────
        Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.05),
                width: 0.5,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'START WITH ONE OF THESE',
                style: AppTypography.eyebrow,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: state.payload.suggestions
                    .map((suggestion) => _SuggestionChip(
                          suggestion: suggestion,
                          onTap: () => onChipTap(suggestion.query),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Archetype chip ─────────────────────────────────────────────────────────

// ── Dynamic suggestion chip ────────────────────────────────────────────────

class _SuggestionChip extends StatelessWidget {
  static String toHealthyTitle(String query) {
    if (query.trim().isEmpty) return '';

    return query.split(' ').map((word) {
      if (word.isEmpty) return '';
      // Capitalize first letter, keep the rest as-is
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  const _SuggestionChip({
    required this.suggestion,
    required this.onTap,
  });

  final SuggestedQuery suggestion;
  final VoidCallback onTap;

  Color get _accentColor => switch (suggestion.archetype) {
        'MEDIA' => AppColors.accentMedia,
        'GEOGRAPHIC' => AppColors.accentGeographic,
        _ => AppColors.accentTechnical,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: _accentColor.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _accentColor.withValues(alpha: 0.18),
            width: 0.5,
          ),
        ),
        child: Text(
          _SuggestionChip.toHealthyTitle(suggestion.query),
          style: AppTypography.body.copyWith(
            color: _accentColor.withValues(alpha: 0.85),
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
// ── Logo mark ──────────────────────────────────────────────────────────────

class _LogoMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGlobal.withValues(alpha: 0.05),
            blurRadius: 12,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.asset(
          'assets/images/logo.png',
          width: 44,
          height: 44,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

// ── Eyebrow with divider lines ─────────────────────────────────────────────

class _EyebrowDivider extends StatelessWidget {
  const _EyebrowDivider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 0.5,
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            label.toUpperCase(),
            style: AppTypography.eyebrow.copyWith(
              color: AppColors.border,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 0.5,
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ],
    );
  }
}
