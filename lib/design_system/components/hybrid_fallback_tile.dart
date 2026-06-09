/// Architectural role: Shared design system component.
/// Implements the three-layer image fallback strategy from Design Contract §07.
/// Layer 1: CachedNetworkImage. Layer 2: LLM gradient. Layer 3: Archetype anchor.
/// Transitions between layers via 300ms easeOutCubic crossfade.
library;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';

// ── Hex parser ─────────────────────────────────────────────────────────────

/// Safely parses a hex color string into a Flutter [Color].
/// Returns null on any malformed input — never throws.
Color? _parseHex(String? hex) {
  if (hex == null) return null;
  final cleaned = hex.replaceAll('#', '').trim();
  if (cleaned.length != 6) return null;
  final value = int.tryParse(cleaned, radix: 16);
  if (value == null) return null;
  return Color(0xFF000000 | value);
}

/// Returns the archetype anchor color for Layer 3 fallback.
Color _archetypeAnchor(String archetype) {
  return switch (archetype.toUpperCase()) {
    'MEDIA' => AppColors.accentMedia,
    'GEOGRAPHIC' => AppColors.accentGeographic,
    _ => AppColors.accentTechnical,
  };
}

/// Returns the archetype icon for Layer 3 fallback.
IconData _archetypeIcon(String archetype) {
  return switch (archetype.toUpperCase()) {
    'MEDIA' => Icons.book_outlined,
    'GEOGRAPHIC' => Icons.location_on_outlined,
    _ => Icons.memory_outlined,
  };
}

// ── Component ──────────────────────────────────────────────────────────────

/// Three-layer image tile for ranking cards.
/// Size is fixed at 36×36dp per Design Contract §06.
class HybridFallbackTile extends StatelessWidget {
  const HybridFallbackTile({
    super.key,
    required this.archetype,
    required this.primaryColorHex,
    required this.secondaryColorHex,
    this.imageUrl,
    this.size = 36,
    this.borderRadius = 10,
  });

  final String archetype;
  final String primaryColorHex;
  final String secondaryColorHex;
  final String? imageUrl;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final url = imageUrl;

    // Layer 1 — attempt network image
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 300),
        // On error → crossfade to Layer 2 or 3
        errorWidget: (_, __, ___) => _buildGradientTile(),
        placeholder: (_, __) => _buildGradientTile(),
      );
    }

    // No URL provided — go straight to Layer 2 or 3
    return _buildGradientTile();
  }

  /// Layer 2 — LLM-generated gradient tile.
  /// Falls back to Layer 3 if hex values are invalid.
  Widget _buildGradientTile() {
    final primary = _parseHex(primaryColorHex);
    final secondary = _parseHex(secondaryColorHex);

    // Both colors must be valid for Layer 2
    if (primary != null && secondary != null) {
      return _GradientTile(
        primary: primary,
        secondary: secondary,
        archetype: archetype,
      );
    }

    // Layer 3 — archetype anchor color + ghost icon
    return _AnchorTile(archetype: archetype);
  }
}

// ── Layer 2 — Gradient tile ────────────────────────────────────────────────

class _GradientTile extends StatelessWidget {
  const _GradientTile({
    required this.primary,
    required this.secondary,
    required this.archetype,
  });

  final Color primary;
  final Color secondary;
  final String archetype;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, secondary],
        ),
      ),
      child: Center(
        child: Icon(
          _archetypeIcon(archetype),
          // ghost icon — white at 20% opacity per Design Contract §07
          color: AppColors.tileIconGhost,
          size: 24, // Design Contract §07
        ),
      ),
    );
  }
}

// ── Layer 3 — Anchor tile ──────────────────────────────────────────────────

class _AnchorTile extends StatelessWidget {
  const _AnchorTile({required this.archetype});

  final String archetype;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _archetypeAnchor(archetype),
      child: Center(
        child: Icon(
          _archetypeIcon(archetype),
          color: AppColors.tileIconGhost,
          size: 24,
        ),
      ),
    );
  }
}
