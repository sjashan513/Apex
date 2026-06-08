/// Architectural role: TECHNICAL archetype ranking card.
/// Thin variant — 56dp height per Design Contract §06.
/// Displays rank, gradient tile, item name, and spec chips (VRAM, TDP, Price).
library;

import 'package:flutter/material.dart';
import '../../../../../design_system/components/hybrid_fallback_tile.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_typography.dart';
import '../../../domain/models/ranking_model.dart';
import 'animated_card.dart';

class TechnicalLayoutCard extends StatelessWidget {
  const TechnicalLayoutCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.animationDelay,
  });

  final TechnicalItem item;
  final VoidCallback onTap;
  final Duration animationDelay;

  @override
  Widget build(BuildContext context) {
    return AnimatedRankingCard(
      delay: animationDelay,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _borderColor,
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '${item.rank}',
                  style: AppTypography.scoreForRank(item.rank),
                ),
              ),
              const SizedBox(width: 10),
              HybridFallbackTile(
                archetype: 'TECHNICAL',
                primaryColorHex: item.primaryColorHex,
                secondaryColorHex: item.secondaryColorHex,
                imageUrl: item.imageUrl,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.title,
                  style: AppTypography.cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.vram.isNotEmpty) _SpecChip(label: item.vram),
                  if (item.vram.isNotEmpty) const SizedBox(width: 4),
                  if (item.tdpWattage.isNotEmpty)
                    _SpecChip(label: item.tdpWattage),
                  if (item.tdpWattage.isNotEmpty) const SizedBox(width: 4),
                  if (item.price.isNotEmpty)
                    _SpecChip(label: item.price, isPrice: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color get _borderColor => switch (item.rank) {
        1 => AppColors.rankOneBorder,
        2 => AppColors.rankTwoBorder,
        3 => AppColors.rankThreeBorder,
        _ => AppColors.border,
      };
}

// ── Spec chip ──────────────────────────────────────────────────────────────

class _SpecChip extends StatelessWidget {
  const _SpecChip({
    required this.label,
    this.isPrice = false,
  });

  final String label;
  final bool isPrice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isPrice
              ? AppColors.price.withValues(alpha: 0.3)
              : AppColors.border,
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.eyebrow.copyWith(
          color: isPrice ? AppColors.price : AppColors.textGhost,
          fontSize: 9,
        ),
      ),
    );
  }
}
