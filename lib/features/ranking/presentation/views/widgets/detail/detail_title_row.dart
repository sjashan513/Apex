/// Architectural role: Detail screen sub-widget (State 4).
/// Title row rendered below the hero banner.
/// Displays item name, subtitle, archetype badge, and optional score pill.
/// Subtitle and score are derived from the sealed RankingItem type via
/// exhaustive switch — adding a new archetype here is a compiler error.
library;

import 'package:flutter/material.dart';
import '../../../../../../design_system/theme/app_colors.dart';
import '../../../../../../design_system/theme/app_typography.dart';
import '../../../../domain/models/ranking_model.dart';

class DetailTitleRow extends StatelessWidget {
  const DetailTitleRow({
    super.key,
    required this.item,
    required this.archetype,
    required this.accentColor,
  });

  final RankingItem item;
  final String archetype;
  final Color accentColor;

  String get _subtitle => switch (item) {
        TechnicalItem() => 'Technical',
        MediaItem() => (item as MediaItem).creator,
        GeographicItem() => (item as GeographicItem).priceIndex,
      };

  double? get _score => switch (item) {
        TechnicalItem() => (item as TechnicalItem).performanceScore,
        MediaItem() => (item as MediaItem).rating * 10,
        GeographicItem() => null,
      };

  @override
  Widget build(BuildContext context) {
    final score = _score;
    final archetypeLabel = archetype[0] + archetype.substring(1).toLowerCase();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title + subtitle + archetype badge
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: AppTypography.screenTitle),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    _subtitle,
                    style: AppTypography.body
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.2),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      archetypeLabel,
                      style: AppTypography.eyebrow.copyWith(
                        color: accentColor,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Score pill — only when score is available
        if (score != null) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            child: Column(
              children: [
                Text(
                  score.toStringAsFixed(1),
                  style: AppTypography.screenTitle.copyWith(
                    color: accentColor,
                    fontSize: 20,
                  ),
                ),
                Text(
                  'SCORE',
                  style: AppTypography.eyebrow.copyWith(
                    color: AppColors.textGhost,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
