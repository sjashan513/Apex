/// Architectural role: State 4 — Item Detail.
/// Modal screen displaying full metadata for a selected ranking item.
/// Inherits archetype from parent RankingResultState.
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

class ItemDetailScreen extends ConsumerWidget {
  const ItemDetailScreen({super.key, required this.itemId});
  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingState = ref.watch(rankingNotifierProvider);

    final item = rankingState.maybeWhen(
      data: (state) {
        if (state is! RankingResultState) return null;
        final index = int.tryParse(itemId);
        if (index == null || index >= state.model.items.length) return null;
        return state.model.items[index];
      },
      orElse: () => null,
    );

    // Item not found — go back
    if (item == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.goNamed('ranking');
      });
      return const Scaffold(backgroundColor: AppColors.canvas);
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar — dismiss button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 18,
              ),
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
                    style: AppTypography.dashboardTitle.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Content — scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildContent(item),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(RankingItem item) {
    return switch (item) {
      MediaItem() => _MediaDetail(item: item),
      GeographicItem() => _GeographicDetail(item: item),
      TechnicalItem() => _TechnicalDetail(item: item),
    };
  }
}

// ── Shared header ──────────────────────────────────────────────────────────

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.item,
    required this.archetype,
    required this.accentColor,
    this.subtitle,
  });

  final RankingItem item;
  final String archetype;
  final Color accentColor;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rank badge + tile
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
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
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
                style: AppTypography.eyebrow.copyWith(
                  color: accentColor,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Title
        Text(
          item.title,
          style: AppTypography.screenTitle,
        ),

        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: AppTypography.body),
        ],

        const SizedBox(height: 12),

        // Description
        Text(
          item.description,
          style: AppTypography.body,
        ),

        const SizedBox(height: 24),

        // Divider
        Container(
          height: 0.5,
          color: AppColors.border,
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Metadata row ───────────────────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label.toUpperCase(),
              style: AppTypography.eyebrow,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.body.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── MEDIA detail ───────────────────────────────────────────────────────────

class _MediaDetail extends StatelessWidget {
  const _MediaDetail({required this.item});
  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailHeader(
          item: item,
          archetype: 'MEDIA',
          accentColor: AppColors.accentMedia,
          subtitle: item.creator,
        ),
        _MetaRow(label: 'Creator', value: item.creator),
        _MetaRow(label: 'Year', value: '${item.releaseYear}'),
        _MetaRow(label: 'Duration', value: item.duration),
        _MetaRow(
          label: 'Rating',
          value: '${item.rating.toStringAsFixed(1)} / 10',
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ── GEOGRAPHIC detail ──────────────────────────────────────────────────────

class _GeographicDetail extends StatelessWidget {
  const _GeographicDetail({required this.item});
  final GeographicItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailHeader(
          item: item,
          archetype: 'GEOGRAPHIC',
          accentColor: AppColors.accentGeographic,
        ),
        _MetaRow(label: 'Price', value: item.priceIndex),
        _MetaRow(label: 'Access', value: item.accessibility),
        _MetaRow(
          label: 'Coordinates',
          value: '${item.latitude.toStringAsFixed(4)}, '
              '${item.longitude.toStringAsFixed(4)}',
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ── TECHNICAL detail ───────────────────────────────────────────────────────

class _TechnicalDetail extends StatelessWidget {
  const _TechnicalDetail({required this.item});
  final TechnicalItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailHeader(
          item: item,
          archetype: 'TECHNICAL',
          accentColor: AppColors.accentTechnical,
        ),
        _MetaRow(
          label: 'Performance',
          value: '${item.performanceScore.toStringAsFixed(1)} / 100',
        ),
        _MetaRow(label: 'VRAM', value: item.vram),
        _MetaRow(label: 'TDP', value: item.tdpWattage),
        _MetaRow(label: 'Price', value: item.price),
        const SizedBox(height: 32),
      ],
    );
  }
}
