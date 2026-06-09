/// Architectural role: Detail screen sub-widget (State 4).
/// Hero banner at the top of the item detail screen.
/// Renders the LLM-generated gradient background, ghost archetype icon,
/// rank badge, and dismiss button.
/// Hex parsing lives here — it is the only consumer of raw color strings
/// from the domain model at this level.
library;

import 'package:flutter/material.dart';
import '../../../../../../design_system/theme/app_colors.dart';
import '../../../../../../design_system/theme/app_typography.dart';
import '../../../../domain/models/ranking_model.dart';

// ── Hex parser ─────────────────────────────────────────────────────────────

/// Parses a nullable hex string (with or without leading #) to a [Color].
/// Returns null on invalid input — callers provide their own fallback.
Color? parseHex(String? hex) {
  if (hex == null) return null;
  final cleaned = hex.replaceAll('#', '').trim();
  if (cleaned.length != 6) return null;
  final value = int.tryParse(cleaned, radix: 16);
  if (value == null) return null;
  return Color(0xFF000000 | value);
}

// ── Widget ─────────────────────────────────────────────────────────────────

class DetailHeroBanner extends StatelessWidget {
  const DetailHeroBanner({
    super.key,
    required this.item,
    required this.archetype,
    required this.accentColor,
    required this.primaryColor,
    required this.secondaryColor,
    required this.onDismiss,
  });

  final RankingItem item;
  final String archetype;
  final Color accentColor;
  final Color primaryColor;
  final Color secondaryColor;
  final VoidCallback onDismiss;

  IconData get _archetypeIcon => switch (archetype) {
        'MEDIA' => Icons.book_outlined,
        'GEOGRAPHIC' => Icons.location_on_outlined,
        _ => Icons.memory_outlined,
      };

  Color get _rankBorderColor => switch (item.rank) {
        1 => AppColors.rankOneBorder,
        2 => AppColors.rankTwoBorder,
        3 => AppColors.rankThreeBorder,
        _ => AppColors.border,
      };

  Color get _rankTextColor => switch (item.rank) {
        1 => AppColors.rankOneScore,
        2 => AppColors.rankTwoScore,
        3 => AppColors.rankThreeScore,
        _ => AppColors.rankDefaultScore,
      };

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: 180 + topPad,
      child: Stack(
        children: [
          // LLM gradient background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor.withValues(alpha: 0.6),
                    secondaryColor.withValues(alpha: 0.3),
                    AppColors.canvas,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Ghost archetype icon — centered
          Center(
            child: Icon(
              _archetypeIcon,
              size: 80,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),

          // Bottom fade to canvas
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 80,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppColors.canvas],
                ),
              ),
            ),
          ),

          // Rank badge — top left
          Positioned(
            top: topPad + 16,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _rankBorderColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _rankBorderColor, width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.military_tech_rounded,
                    size: 12,
                    color: _rankTextColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Rank #${item.rank}',
                    style:
                        AppTypography.eyebrow.copyWith(color: _rankTextColor),
                  ),
                ],
              ),
            ),
          ),

          // Dismiss button — top right
          Positioned(
            top: topPad + 16,
            right: 20,
            child: GestureDetector(
              onTap: onDismiss,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
