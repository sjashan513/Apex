/// Architectural role: State 4 — Item Detail.
/// Modal screen displaying full enriched metadata for a selected ranking item.
/// Triggers Trip 2 API call on mount — fetches per-item deep metadata.
/// Hero gradient uses LLM-generated primaryColorHex + secondaryColorHex from Trip 1.
/// No particles — content screen per Design Contract §11.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_typography.dart';
import '../../../domain/models/ranking_model.dart';
import '../../../domain/providers/ranking_providers.dart';
import '../../notifiers/ranking_notifier.dart';

// ── Hex parser (duplicated from HybridFallbackTile — keep local) ───────────

Color? _parseHex(String? hex) {
  if (hex == null) return null;
  final cleaned = hex.replaceAll('#', '').trim();
  if (cleaned.length != 6) return null;
  final value = int.tryParse(cleaned, radix: 16);
  if (value == null) return null;
  return Color(0xFF000000 | value);
}

// ── Detail provider ────────────────────────────────────────────────────────

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

    // Parse LLM gradient colors for hero banner
    final primary =
        _parseHex(item.primaryColorHex) ?? accentColor.withValues(alpha: 0.4);
    final secondary = _parseHex(item.secondaryColorHex) ?? AppColors.canvas;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Column(
        children: [
          // ── Hero banner ──────────────────────────────────────────────
          _HeroBanner(
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
                  // Title row + score pill
                  _TitleRow(
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

// ── Hero banner ────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.item,
    required this.archetype,
    required this.accentColor,
    required this.primaryColor,
    required this.secondaryColor,
    required this.onDismiss,
  });

  final RankingItem item;
  final String archetype;
  final Color accentColor;
  final Color primaryColor;
  final Color secondaryColor;
  final VoidCallback onDismiss;

  IconData get _archetypeIcon => switch (archetype) {
        'MEDIA' => Icons.book_outlined,
        'GEOGRAPHIC' => Icons.location_on_outlined,
        _ => Icons.memory_outlined,
      };

  Color get _rankBorderColor => switch (item.rank) {
        1 => AppColors.rankOneBorder,
        2 => AppColors.rankTwoBorder,
        3 => AppColors.rankThreeBorder,
        _ => AppColors.border,
      };

  Color get _rankTextColor => switch (item.rank) {
        1 => AppColors.rankOneScore,
        2 => AppColors.rankTwoScore,
        3 => AppColors.rankThreeScore,
        _ => AppColors.rankDefaultScore,
      };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180 + MediaQuery.of(context).padding.top,
      child: Stack(
        children: [
          // Gradient background from LLM colors
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor.withValues(alpha: 0.6),
                    secondaryColor.withValues(alpha: 0.3),
                    AppColors.canvas,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Ghost icon centered
          Center(
            child: Icon(
              _archetypeIcon,
              size: 80,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),

          // Bottom fade to canvas
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 80,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.canvas,
                  ],
                ),
              ),
            ),
          ),

          // Rank badge — top left
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: _rankBorderColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _rankBorderColor,
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.military_tech_rounded,
                    size: 12,
                    color: _rankTextColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Rank #${item.rank}',
                    style: AppTypography.eyebrow.copyWith(
                      color: _rankTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Dismiss button — top right
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 20,
            child: GestureDetector(
              onTap: onDismiss,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Title row ──────────────────────────────────────────────────────────────

class _TitleRow extends StatelessWidget {
  const _TitleRow({
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
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
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
                        color: accentColor.withValues(alpha: 0.2),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      archetype[0] + archetype.substring(1).toLowerCase(),
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
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
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

// ── Detail content ─────────────────────────────────────────────────────────

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.detail,
    required this.accentColor,
    this.performanceScore,
  });

  final RankingItemDetail detail;
  final Color accentColor;
  final double? performanceScore;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Specs grid
        const _SectionLabel('Specifications'),
        _SpecGrid(specs: detail.specs),

        const SizedBox(height: 24),
        Container(height: 0.5, color: AppColors.border),
        const SizedBox(height: 24),

        // Performance bars — shown when performanceScore is available
        if (performanceScore != null) ...[
          const _SectionLabel('Performance benchmarks'),
          _PerformanceBars(
            score: performanceScore!,
            accentColor: accentColor,
          ),
          const SizedBox(height: 24),
          Container(height: 0.5, color: AppColors.border),
          const SizedBox(height: 24),
        ],

        // Overview
        const _SectionLabel('Overview'),
        Text(detail.overview, style: AppTypography.body),

        const SizedBox(height: 24),
        Container(height: 0.5, color: AppColors.border),
        const SizedBox(height: 24),

        // Pros & Cons
        const _SectionLabel('Pros & Cons'),
        _ProsConsRow(
          pros: detail.pros,
          cons: detail.cons,
        ),

        const SizedBox(height: 24),
        Container(height: 0.5, color: AppColors.border),
        const SizedBox(height: 24),

        // Best For
        const _SectionLabel('Best For'),
        _BestForTags(items: detail.bestFor),
      ],
    );
  }
}

// ── Performance bars ───────────────────────────────────────────────────────

class _PerformanceBars extends StatelessWidget {
  const _PerformanceBars({
    required this.score,
    required this.accentColor,
  });

  final double score;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    // Generate contextual benchmark rows from the overall score
    final bars = [
      ('Primary use', math.min(score / 100, 1.0), true),
      ('Efficiency', math.min((score * 0.92) / 100, 1.0), true),
      ('Value ratio', math.min((score * 0.88) / 100, 1.0), false),
      ('Versatility', math.min((score * 0.75) / 100, 1.0), false),
    ];

    return Column(
      children: bars.map((bar) {
        final (label, value, isAccent) = bar;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(
                width: 88,
                child: Text(
                  label,
                  style: AppTypography.body.copyWith(fontSize: 11),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Stack(
                    children: [
                      Container(
                        height: 4,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                      FractionallySizedBox(
                        widthFactor: value,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: isAccent
                                ? accentColor
                                : AppColors.textSecondary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 36,
                child: Text(
                  '${(value * 100).toInt()}%',
                  style: AppTypography.body.copyWith(fontSize: 11),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Spec grid ──────────────────────────────────────────────────────────────

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
          const SizedBox(width: 8),
          Expanded(
            child: right != null
                ? _SpecCell(label: right.label, value: right.value)
                : const SizedBox.shrink(),
          ),
        ],
      ));
      if (i + 2 < specs.length) rows.add(const SizedBox(height: 8));
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppTypography.eyebrow),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.cardTitle.copyWith(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pros & Cons ────────────────────────────────────────────────────────────

class _ProsConsRow extends StatelessWidget {
  const _ProsConsRow({required this.pros, required this.cons});
  final List<String> pros;
  final List<String> cons;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
            child: _ProsConsPanel(label: 'PROS', items: pros, isPros: true)),
        const SizedBox(width: 8),
        Expanded(
            child: _ProsConsPanel(label: 'CONS', items: cons, isPros: false)),
      ],
    );
  }
}

class _ProsConsPanel extends StatelessWidget {
  const _ProsConsPanel({
    required this.label,
    required this.items,
    required this.isPros,
  });

  final String label;
  final List<String> items;
  final bool isPros;

  @override
  Widget build(BuildContext context) {
    final color = isPros ? AppColors.price : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPros
                    ? Icons.check_circle_outline_rounded
                    : Icons.cancel_outlined,
                size: 12,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTypography.eyebrow.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isPros ? Icons.check_rounded : Icons.close_rounded,
                    size: 12,
                    color: color,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTypography.body.copyWith(fontSize: 11),
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

// ── Best For tags ──────────────────────────────────────────────────────────

class _BestForTags extends StatelessWidget {
  const _BestForTags({required this.items});
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.07),
                  width: 0.5,
                ),
              ),
              child: Text(
                item,
                style: AppTypography.body.copyWith(fontSize: 11),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ── Section label ──────────────────────────────────────────────────────────

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

// ── Skeleton loader ────────────────────────────────────────────────────────

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(children: [
          Expanded(child: _SkeletonBlock(height: 64)),
          SizedBox(width: 8),
          Expanded(child: _SkeletonBlock(height: 64)),
        ]),
        const SizedBox(height: 8),
        const Row(children: [
          Expanded(child: _SkeletonBlock(height: 64)),
          SizedBox(width: 8),
          Expanded(child: _SkeletonBlock(height: 64)),
        ]),
        const SizedBox(height: 8),
        const Row(children: [
          Expanded(child: _SkeletonBlock(height: 64)),
          SizedBox(width: 8),
          Expanded(child: _SkeletonBlock(height: 64)),
        ]),
        const SizedBox(height: 28),
        const _SkeletonBlock(width: 80, height: 10),
        const SizedBox(height: 12),
        const _SkeletonBlock(height: 80),
        const SizedBox(height: 28),
        const _SkeletonBlock(width: 80, height: 10),
        const SizedBox(height: 12),
        const Row(children: [
          Expanded(child: _SkeletonBlock(height: 120)),
          SizedBox(width: 8),
          Expanded(child: _SkeletonBlock(height: 120)),
        ]),
        const SizedBox(height: 28),
        const _SkeletonBlock(width: 80, height: 10),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            4,
            (_) => const _SkeletonBlock(width: 100, height: 32),
          ),
        ),
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
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Try again', style: AppTypography.body),
          ),
        ),
      ],
    );
  }
}
