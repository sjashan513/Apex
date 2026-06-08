/// Single source of truth for all typography tokens defined in Design Contract v1.0.
/// Two weights only: 400 regular, 500 medium. Never 600 or 700.
/// Playfair Display is used exclusively for MEDIA archetype hero titles.
library;

import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTypography {
  // ── Base style ──────────────────────────────────────────────────────────────

  static const String _inter = 'Inter';
  static const String _playfair = 'Playfair Display';

  // ── Scale ───────────────────────────────────────────────────────────────────

  /// 26px · Inter 500 · lh 1.2 — Idle screen H1.
  static const TextStyle heroTitle = TextStyle(
    fontFamily: _inter,
    fontSize: 26,
    fontWeight: FontWeight.w500,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  /// 22px · Inter 500 · lh 1.25 — State 5/6 message title.
  static const TextStyle screenTitle = TextStyle(
    fontFamily: _inter,
    fontSize: 22,
    fontWeight: FontWeight.w500,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  /// 18px · Inter 500 · lh 1.3 — Topbar query label on dashboard.
  static const TextStyle dashboardTitle = TextStyle(
    fontFamily: _inter,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  /// 13px · Inter 500 · lh 1.4 — Thin card item name.
  static const TextStyle cardTitle = TextStyle(
    fontFamily: _inter,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  /// 13px · Inter 400 · lh 1.5 — Subtitles, descriptions, metadata.
  static const TextStyle body = TextStyle(
    fontFamily: _inter,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  /// 10px · Inter 500 · ls 0.09em — Section eyebrows. Always uppercase at call site.
  static const TextStyle eyebrow = TextStyle(
    fontFamily: _inter,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.09 * 10, // 0.09em × 10px
    color: AppColors.textGhost,
  );

  /// 16px · Inter 500 — Card rank score label.
  static const TextStyle cardScore = TextStyle(
    fontFamily: _inter,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  /// 22px · Playfair Display 400 · lh 1.3 — MEDIA archetype hero title only.
  static const TextStyle mediaHeroTitle = TextStyle(
    fontFamily: _playfair,
    fontSize: 22,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  // ── Utility ─────────────────────────────────────────────────────────────────

  /// Returns [cardScore] with the correct rank color applied.
  /// Rank 1 → amber · Rank 2 → silver · Rank 3 → bronze · Rank 4+ → secondary.
  static TextStyle scoreForRank(int rank) {
    final color = switch (rank) {
      1 => AppColors.rankOneScore,
      2 => AppColors.rankTwoScore,
      3 => AppColors.rankThreeScore,
      _ => AppColors.rankDefaultScore,
    };
    return cardScore.copyWith(color: color);
  }
}
