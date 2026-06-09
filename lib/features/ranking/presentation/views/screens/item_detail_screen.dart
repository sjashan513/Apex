/// Architectural role: State 4 — Item Detail coordinator screen.
/// Pure orchestration: resolves the item from notifier state, resolves the
/// archetype, computes derived colors, and assembles the layout from
/// extracted sub-widgets. Zero widget definitions live here.
/// No particles — content screen per Design Contract §11.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../domain/models/ranking_model.dart';
import '../../../domain/providers/item_detail_provider.dart';
import '../../../domain/providers/ranking_providers.dart';
import '../../notifiers/ranking_notifier.dart';
import '../widgets/detail/detail_hero_banner.dart';
import '../widgets/detail/detail_title_row.dart';
import '../widgets/detail/detail_content.dart';
import '../widgets/detail/detail_loading_error.dart';

class ItemDetailScreen extends ConsumerWidget {
  const ItemDetailScreen({super.key, required this.itemId});
  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingState = ref.watch(rankingNotifierProvider);

    // Resolve item + archetype from current notifier state.
    // If state is gone (e.g. deep-link with no prior session), guard-navigate back.
    final resolved = rankingState.maybeWhen(
      data: (state) {
        if (state is! RankingResultState) return null;
        final index = int.tryParse(itemId);
        if (index == null || index >= state.model.items.length) return null;
        final archetype = switch (state.model) {
          MediaRanking() => 'MEDIA',
          GeographicRanking() => 'GEOGRAPHIC',
          TechnicalRanking() => 'TECHNICAL',
        };
        return (state.model.items[index], archetype);
      },
      orElse: () => null,
    );

    if (resolved == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.goNamed('ranking');
      });
      return const Scaffold(backgroundColor: AppColors.canvas);
    }

    final (item, archetype) = resolved;
    final index = int.parse(itemId);
    final accentColor = AppColors.accentForArchetype(archetype);
    final detailAsync = ref.watch(itemDetailProvider((index, archetype)));

    // Derive hero gradient colors from LLM-generated hex strings.
    final primary =
        parseHex(item.primaryColorHex) ?? accentColor.withValues(alpha: 0.4);
    final secondary = parseHex(item.secondaryColorHex) ?? AppColors.canvas;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Column(
        children: [
          // ── Hero banner ──────────────────────────────────────────────
          DetailHeroBanner(
            item: item,
            archetype: archetype,
            accentColor: accentColor,
            primaryColor: primary,
            secondaryColor: secondary,
            onDismiss: () => context.goNamed('ranking'),
          ),

          // ── Scrollable content ───────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DetailTitleRow(
                    item: item,
                    archetype: archetype,
                    accentColor: accentColor,
                  ),
                  const SizedBox(height: 24),
                  detailAsync.when(
                    loading: () => const DetailSkeleton(),
                    error: (_, __) => DetailErrorView(
                      onRetry: () => ref.invalidate(
                        itemDetailProvider((index, archetype)),
                      ),
                    ),
                    data: (detail) => DetailContent(
                      detail: detail,
                      accentColor: accentColor,
                      performanceScore:
                          item is TechnicalItem ? item.performanceScore : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
