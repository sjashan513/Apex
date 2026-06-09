/// Architectural role: Detail screen sub-widgets (State 4).
/// Loading skeleton and inline error view shown while Trip 2 data resolves.
/// Both are detail-specific — they have no value as global design primitives.
library;

import 'package:flutter/material.dart';
import '../../../../../../design_system/theme/app_colors.dart';
import '../../../../../../design_system/theme/app_typography.dart';

// ── Skeleton loader ────────────────────────────────────────────────────────

class DetailSkeleton extends StatelessWidget {
  const DetailSkeleton({super.key});

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

// ── Inline error view ──────────────────────────────────────────────────────

class DetailErrorView extends StatelessWidget {
  const DetailErrorView({super.key, required this.onRetry});
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
