/// Architectural role: State 4 — Item Detail.
/// Modal screen displaying full enriched metadata for a selected ranking item.
/// Triggers Trip 2 API call on mount — fetches per-item deep metadata.
/// Single layout handles all archetypes — no three-way switch in the UI layer.
/// No particles — content screen per Design Contract §11.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../design_system/components/hybrid_fallback_tile.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_typography.dart';
import '../../../domain/models/ranking_model.dart';
import '../../../domain/providers/ranking_providers.dart';
import '../../notifiers/ranking_notifier.dart';

// ── Detail provider ────────────────────────────────────────────────────────

/// Trip 2 provider. AutoDispose — cleaned up when the detail screen exits.
/// Family parameter: (itemIndex, archetype) — identifies exactly which item to enrich.
final itemDetailProvider = FutureProvider.autoDispose
    .family<RankingItemDetail, (int, String)>((ref, params) async {
  final (index, archetype) = params;

  final rankingState = ref.read(rankingNotifierProvider);
  final item = rankingState.maybeWhen(
    data: (state) {
      if (state is! RankingResultState) return null;
      if (index >= state.model.items.length) return null;
      return state.model.items[index];
    },
    orElse: () => null,
  );

  if (item == null) throw Exception('Item not found at index $index');

  final repository = ref.read(rankingRepositoryProvider);
  return repository.getItemDetail(item, archetype);
});

// ── Screen ─────────────────────────────────────────────────────────────────

class ItemDetailScreen extends ConsumerWidget {
  const ItemDetailScreen({super.key, required this.itemId});
  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingState = ref.watch(rankingNotifierProvider);

    // Resolve list item and archetype from Trip 1 state — always instant.
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

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.goNamed('ranking'),
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Detail',
                    style: AppTypography.dashboardTitle
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

            // Content — scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Static header from Trip 1 — always visible immediately
                    _DetailHeader(
                      item: item,
                      archetype: archetype,
                      accentColor: accentColor,
                    ),

                    const SizedBox(height: 24),

                    // Trip 2 enriched content
                    detailAsync.when(
                      loading: () => const _DetailSkeleton(),
                      error: (_, __) => _DetailErrorView(
                        onRetry: () => ref.invalidate(
                          itemDetailProvider((index, archetype)),
                        ),
                      ),
                      data: (detail) => _DetailContent(
                        detail: detail,
                        accentColor: accentColor,
                      ),
                    ),

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Static header (Trip 1 data — renders instantly) ────────────────────────

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.item,
    required this.archetype,
    required this.accentColor,
  });

  final RankingItem item;
  final String archetype;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            HybridFallbackTile(
              archetype: archetype,
              primaryColorHex: item.primaryColorHex,
              secondaryColorHex: item.secondaryColorHex,
              imageUrl: item.imageUrl,
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Text(
                '#${item.rank}',
                style: AppTypography.eyebrow.copyWith(color: accentColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(item.title, style: AppTypography.screenTitle),
        const SizedBox(height: 8),
        Text(item.description, style: AppTypography.body),
        const SizedBox(height: 24),
        Container(height: 0.5, color: AppColors.border),
      ],
    );
  }
}

// ── Unified detail content (Trip 2 data — single widget, all archetypes) ──

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.detail, required this.accentColor});

  final RankingItemDetail detail;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overview
        _SectionLabel('Overview'),
        Text(detail.overview, style: AppTypography.body),

        const SizedBox(height: 28),

        // Spec grid — model-generated, contextually appropriate
        _SectionLabel('Details'),
        _SpecGrid(specs: detail.specs),

        const SizedBox(height: 28),

        // Highlights
        _SectionLabel('Highlights'),
        _ChipList(items: detail.highlights, accentColor: accentColor),

        const SizedBox(height: 28),

        // Pros & Cons
        _SectionLabel('Pros & Cons'),
        _ProsConsRow(
          pros: detail.pros,
          cons: detail.cons,
          accentColor: accentColor,
        ),

        const SizedBox(height: 28),

        // Best For
        _SectionLabel('Best For'),
        _ChipList(items: detail.bestFor, accentColor: accentColor),
      ],
    );
  }
}

// ── Skeleton loader ────────────────────────────────────────────────────────

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SkeletonBlock(width: 80, height: 10),
        const SizedBox(height: 12),
        _SkeletonBlock(height: 72),
        const SizedBox(height: 28),
        _SkeletonBlock(width: 60, height: 10),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _SkeletonBlock(height: 64)),
          const SizedBox(width: 12),
          Expanded(child: _SkeletonBlock(height: 64)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _SkeletonBlock(height: 64)),
          const SizedBox(width: 12),
          Expanded(child: _SkeletonBlock(height: 64)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _SkeletonBlock(height: 64)),
          const SizedBox(width: 12),
          Expanded(child: _SkeletonBlock(height: 64)),
        ]),
        const SizedBox(height: 28),
        _SkeletonBlock(width: 80, height: 10),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              List.generate(3, (_) => _SkeletonBlock(width: 90, height: 32)),
        ),
        const SizedBox(height: 28),
        _SkeletonBlock(width: 80, height: 10),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _SkeletonBlock(height: 100)),
          const SizedBox(width: 12),
          Expanded(child: _SkeletonBlock(height: 100)),
        ]),
      ],
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({this.width, required this.height});
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

// ── Error state ────────────────────────────────────────────────────────────

class _DetailErrorView extends StatelessWidget {
  const _DetailErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Could not load full details.',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('Try again', style: AppTypography.body),
          ),
        ),
      ],
    );
  }
}

// ── Sub-components ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(label.toUpperCase(), style: AppTypography.eyebrow),
    );
  }
}

/// Renders the model-generated spec array as a 2-column grid.
/// Label in eyebrow style, value in body style. No hardcoded field names.
class _SpecGrid extends StatelessWidget {
  const _SpecGrid({required this.specs});
  final List<SpecEntry> specs;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < specs.length; i += 2) {
      final left = specs[i];
      final right = i + 1 < specs.length ? specs[i + 1] : null;
      rows.add(Row(
        children: [
          Expanded(child: _SpecCell(label: left.label, value: left.value)),
          const SizedBox(width: 12),
          Expanded(
            child: right != null
                ? _SpecCell(label: right.label, value: right.value)
                : const SizedBox.shrink(),
          ),
        ],
      ));
      if (i + 2 < specs.length) rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
  }
}

class _SpecCell extends StatelessWidget {
  const _SpecCell({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppTypography.eyebrow),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.cardTitle.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProsConsRow extends StatelessWidget {
  const _ProsConsRow({
    required this.pros,
    required this.cons,
    required this.accentColor,
  });
  final List<String> pros;
  final List<String> cons;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _ProsConsPanel(
            label: 'PROS',
            items: pros,
            labelColor: accentColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ProsConsPanel(
            label: 'CONS',
            items: cons,
            labelColor: AppColors.error,
          ),
        ),
      ],
    );
  }
}

class _ProsConsPanel extends StatelessWidget {
  const _ProsConsPanel({
    required this.label,
    required this.items,
    required this.labelColor,
  });
  final String label;
  final List<String> items;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.eyebrow.copyWith(color: labelColor),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(item, style: AppTypography.body),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipList extends StatelessWidget {
  const _ChipList({required this.items, required this.accentColor});
  final List<String> items;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Text(item, style: AppTypography.body),
            ),
          )
          .toList(),
    );
  }
}
