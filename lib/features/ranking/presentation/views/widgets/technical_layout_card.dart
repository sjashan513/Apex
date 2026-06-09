/// Architectural role: TECHNICAL archetype ranking card.
/// Expanded variant — matches State 3 mockup v2.
/// Tile 48×48dp · score pill right · spec chips row.
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
          padding: const EdgeInsets.all(14),
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
              // Rank number
              SizedBox(
                width: 24,
                child: Text(
                  '${item.rank}',
                  style: AppTypography.scoreForRank(item.rank).copyWith(
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(width: 12),

              // Tile — 48×48dp
              SizedBox(
                width: 48,
                height: 48,
                child: HybridFallbackTile(
                  archetype: 'TECHNICAL',
                  primaryColorHex: item.primaryColorHex,
                  secondaryColorHex: item.secondaryColorHex,
                  imageUrl: item.imageUrl,
                  size: 48,
                  borderRadius: 12,
                ),
              ),

              const SizedBox(width: 12),

              // Info — name + chips
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTypography.cardTitle.copyWith(
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (item.price.isNotEmpty)
                          _SpecChip(label: item.price, isPrice: true),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Score pill
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.performanceScore.toStringAsFixed(1),
                    style: AppTypography.scoreForRank(item.rank).copyWith(
                      fontSize: 20,
                      height: 1,
                    ),
                  ),
                  Text(
                    'score',
                    style: AppTypography.eyebrow.copyWith(
                      color: AppColors.textGhost,
                      fontSize: 9,
                    ),
                  ),
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
        _ => Colors.white.withValues(alpha: 0.06),
      };
}

// ── Spec chip ──────────────────────────────────────────────────────────────

class _SpecChip extends StatelessWidget {
  const _SpecChip({required this.label, this.isPrice = false});
  final String label;
  final bool isPrice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isPrice
              ? AppColors.price.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.07),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.eyebrow.copyWith(
          color: isPrice ? AppColors.price : AppColors.textSecondary,
          fontSize: 10,
        ),
      ),
    );
  }
}
