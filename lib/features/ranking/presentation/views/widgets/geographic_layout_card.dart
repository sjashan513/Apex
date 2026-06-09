/// Architectural role: GEOGRAPHIC archetype ranking card.
/// Expanded variant — tile 48×48dp, price index + accessibility row.
library;

import 'package:flutter/material.dart';
import '../../../../../design_system/components/hybrid_fallback_tile.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_typography.dart';
import '../../../domain/models/ranking_model.dart';
import 'animated_card.dart';

class GeographicLayoutCard extends StatelessWidget {
  const GeographicLayoutCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.animationDelay,
  });

  final GeographicItem item;
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
            border: Border.all(color: _borderColor, width: 0.5),
          ),
          child: Row(
            children: [
              // Rank
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
                  archetype: 'GEOGRAPHIC',
                  primaryColorHex: item.primaryColorHex,
                  secondaryColorHex: item.secondaryColorHex,
                  imageUrl: item.imageUrl,
                  size: 48,
                  borderRadius: 12,
                ),
              ),

              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTypography.cardTitle.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.accessibility,
                      style: AppTypography.body.copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Price index pill
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.priceIndex,
                    style: AppTypography.scoreForRank(item.rank).copyWith(
                      fontSize: 18,
                      height: 1,
                    ),
                  ),
                  Text(
                    'price',
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
