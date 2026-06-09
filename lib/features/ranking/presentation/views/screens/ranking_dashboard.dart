/// Architectural role: State 3 — Ranking Dashboard.
/// Reads the current RankingResultState and renders the archetype-specific list.
/// No particles — content screen per Design Contract §11.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_typography.dart';
import '../../../domain/models/ranking_model.dart';
import '../../../domain/providers/ranking_providers.dart';
import '../../notifiers/ranking_notifier.dart';
import '../widgets/technical_layout_card.dart';
import '../widgets/media_layout_card.dart';
import '../widgets/geographic_layout_card.dart';

class RankingDashboard extends ConsumerWidget {
  const RankingDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingState = ref.watch(rankingNotifierProvider);
    final archetype = ref.watch(detectedArchetypeProvider);

    ref.listen(rankingNotifierProvider, (_, next) {
      next.whenData((state) {
        if (state is IdleState) context.goNamed('home');
      });
    });

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: rankingState.maybeWhen(
        data: (state) {
          if (state is RankingResultState) {
            return _buildDashboard(context, ref, state.model, archetype);
          }
          return const SizedBox.shrink();
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    WidgetRef ref,
    RankingModel model,
    String archetype,
  ) {
    final accentColor = AppColors.accentForArchetype(archetype);
    final archetypeLabel = archetype[0] + archetype.substring(1).toLowerCase();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top bar ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0x0DFFFFFF), // white 5%
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                // Back button
                GestureDetector(
                  onTap: () =>
                      ref.read(rankingNotifierProvider.notifier).reset(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 0.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Center — query + meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.title,
                        style: AppTypography.cardTitle.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          // Archetype badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.25),
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
                          const SizedBox(width: 6),
                          Text(
                            '${model.items.length} results',
                            style: AppTypography.eyebrow.copyWith(
                              color: AppColors.textGhost,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Options button
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 0.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.more_horiz_rounded,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),

          // ── Ranking list ───────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: model.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 9),
              itemBuilder: (context, index) {
                final item = model.items[index];
                final delay = Duration(milliseconds: index * 40);

                return switch (item) {
                  TechnicalItem() => TechnicalLayoutCard(
                      item: item,
                      animationDelay: delay,
                      onTap: () => context.goNamed(
                        'detail',
                        pathParameters: {'itemId': '$index'},
                      ),
                    ),
                  MediaItem() => MediaLayoutCard(
                      item: item,
                      animationDelay: delay,
                      onTap: () => context.goNamed(
                        'detail',
                        pathParameters: {'itemId': '$index'},
                      ),
                    ),
                  GeographicItem() => GeographicLayoutCard(
                      item: item,
                      animationDelay: delay,
                      onTap: () => context.goNamed(
                        'detail',
                        pathParameters: {'itemId': '$index'},
                      ),
                    ),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}
