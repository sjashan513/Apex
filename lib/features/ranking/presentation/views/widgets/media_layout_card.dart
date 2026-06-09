/// Architectural role: MEDIA archetype ranking card.
/// Expanded variant — tile 48×48dp, rating score pill right.
library;

import 'package:flutter/material.dart';
import '../../../../../design_system/components/hybrid_fallback_tile.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_typography.dart';
import '../../../domain/models/ranking_model.dart';
import 'animated_card.dart';

class MediaLayoutCard extends StatelessWidget {
  const MediaLayoutCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.animationDelay,
  });

  final MediaItem item;
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
                  archetype: 'MEDIA',
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
                      style: AppTypography.mediaHeroTitle.copyWith(
                        fontSize: 14,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.creator,
                      style: AppTypography.body.copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Rating score pill
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.rating.toStringAsFixed(1),
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
