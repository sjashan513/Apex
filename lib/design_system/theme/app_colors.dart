/// Single source of truth for all color tokens defined in Design Contract v1.0.
/// No raw hex values anywhere else in the codebase — always reference these constants.
library;

import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Base (zinc dark-first system) ──────────────────────────────────────────

  /// `#09090B` — App background, particle layer.
  static const Color canvas = Color(0xFF09090B);

  /// `#18181B` — Cards, modals, search input.
  static const Color surface = Color(0xFF18181B);

  /// `#27272A` — Chip backgrounds, secondary surfaces.
  static const Color surfaceRaised = Color(0xFF27272A);

  /// `#3F3F46` — All borders at 0.5px.
  static const Color border = Color(0xFF3F3F46);

  /// `#FFFFFF` — Headings, primary labels.
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// `#A1A1AA` — Metadata, subtitles.
  static const Color textSecondary = Color(0xFFA1A1AA);

  /// `#52525B` — Placeholders, hints, section labels, chip icons.
  static const Color textGhost = Color(0xFF52525B);

  // ── Accent ─────────────────────────────────────────────────────────────────

  /// `#FFFFFF` — Shell CTAs, logo mark, submit button. Archetype-neutral.
  static const Color accentGlobal = Color(0xFFFFFFFF);

  /// `#EF9F27` — TECHNICAL dashboard + cards only. Never bleeds into global identity.
  static const Color accentTechnical = Color(0xFFEF9F27);

  /// `#7F77DD` — MEDIA dashboard + cards only.
  static const Color accentMedia = Color(0xFF7F77DD);

  /// `#1D9E75` — GEOGRAPHIC dashboard + cards only.
  static const Color accentGeographic = Color(0xFF1D9E75);

  /// `#412402` — Text rendered on amber fills.
  static const Color accentText = Color(0xFF412402);

  /// `#EF4444` — State 6 error semantic. Particle color in error state.
  static const Color error = Color(0xFFEF4444);

  /// `#4ade80` — Price chip green glow. Only colored chip element.
  static const Color price = Color(0xFF4ade80);

  // ── Card rank borders ───────────────────────────────────────────────────────

  /// Rank 1 card border — amber tint at 35% opacity.
  static const Color rankOneBorder = Color(0x59EF9F27);

  /// Rank 2 card border — silver tint at 25% opacity.
  static const Color rankTwoBorder = Color(0x40A1A1AA);

  /// Rank 3 card border — bronze tint at 25% opacity.
  static const Color rankThreeBorder = Color(0x40B4783C);

  // ── Card rank score colors ──────────────────────────────────────────────────

  /// Rank 1 score label color.
  static const Color rankOneScore = Color(0xFFEF9F27);

  /// Rank 2 score label color.
  static const Color rankTwoScore = Color(0xFFA1A1AA);

  /// Rank 3 score label color.
  static const Color rankThreeScore = Color(0xFFCD853F);

  /// Rank 4+ score label color — same as secondary text.
  static const Color rankDefaultScore = Color(0xFFA1A1AA);

  // ── Utility ─────────────────────────────────────────────────────────────────

  /// Ghost icon overlay on hybrid fallback tiles — white at 20% opacity.
  static const Color tileIconGhost = Color(0x33FFFFFF);

  /// Particle connection lines — white at max 10% opacity.
  static const Color particleConnection = Color(0x1AFFFFFF);

  // ── Helper ──────────────────────────────────────────────────────────────────

  /// Returns the accent color for a given archetype string.
  /// Defaults to [accentTechnical] for unrecognised values.
  static Color accentForArchetype(String archetype) {
    return switch (archetype.toUpperCase()) {
      'MEDIA' => accentMedia,
      'GEOGRAPHIC' => accentGeographic,
      'TECHNICAL' => accentTechnical,
      _ => accentTechnical,
    };
  }
}
