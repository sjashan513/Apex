/// Architectural role: MEDIA archetype ranking card.
/// Thin variant — 56dp. Uses Playfair Display for title per Design Contract §02.
/// Displays rank, gradient tile, item name, creator, and rating.
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
                archetype: 'MEDIA',
                primaryColorHex: item.primaryColorHex,
                secondaryColorHex: item.secondaryColorHex,
                imageUrl: item.imageUrl,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTypography.mediaHeroTitle.copyWith(
                        fontSize: 13,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
              Text(
                '${item.rating.toStringAsFixed(1)}★',
                style: AppTypography.eyebrow.copyWith(
                  color: AppColors.accentMedia,
                  fontSize: 10,
                ),
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
