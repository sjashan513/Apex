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

    // If state is no longer a ranking result — go back to home
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
            return _buildDashboard(ref, state.model);
          }
          return const SizedBox.shrink();
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildDashboard(WidgetRef ref, RankingModel model) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 18,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    model.title,
                    style: AppTypography.dashboardTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () =>
                      ref.read(rankingNotifierProvider.notifier).reset(),
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Ranking list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 8,
              ),
              itemCount: model.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = model.items[index];
                // 40ms stagger per card — Design Contract §05
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
