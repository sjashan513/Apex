/// Architectural role: Detail screen sub-widget (State 4).
/// Scrollable body content rendered below the title row.
/// Consolidates all content sub-sections: specs grid, performance bars,
/// overview text, pros/cons panel, and best-for tags.
/// All private sub-widgets (_SpecGrid, _ProsConsRow, etc.) live in this
/// file — they are only ever used here and have no value being exported.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../../../design_system/components/section_label.dart';
import '../../../../../../design_system/theme/app_colors.dart';
import '../../../../../../design_system/theme/app_typography.dart';
import '../../../../domain/models/ranking_model.dart';

// ── Public surface ─────────────────────────────────────────────────────────

class DetailContent extends StatelessWidget {
  const DetailContent({
    super.key,
    required this.detail,
    required this.accentColor,
    this.performanceScore,
  });

  final RankingItemDetail detail;
  final Color accentColor;

  /// Only provided for TechnicalItem — drives the performance bars section.
  final double? performanceScore;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Specs grid
        const SectionLabel('Specifications'),
        _SpecGrid(specs: detail.specs),

        const SizedBox(height: 24),
        _Divider(),
        const SizedBox(height: 24),

        // Performance bars — technical archetype only
        if (performanceScore != null) ...[
          const SectionLabel('Performance benchmarks'),
          _PerformanceBars(
            score: performanceScore!,
            accentColor: accentColor,
          ),
          const SizedBox(height: 24),
          _Divider(),
          const SizedBox(height: 24),
        ],

        // Overview
        const SectionLabel('Overview'),
        Text(detail.overview, style: AppTypography.body),

        const SizedBox(height: 24),
        _Divider(),
        const SizedBox(height: 24),

        // Pros & Cons
        const SectionLabel('Pros & Cons'),
        _ProsConsRow(pros: detail.pros, cons: detail.cons),

        const SizedBox(height: 24),
        _Divider(),
        const SizedBox(height: 24),

        // Best For
        const SectionLabel('Best For'),
        _BestForTags(items: detail.bestFor),
      ],
    );
  }
}

// ── Internal divider ───────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(height: 0.5, color: AppColors.border);
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
