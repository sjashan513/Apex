/// Architectural role: State 1 — Idle UI.
/// Renders the hero title, search input, and suggestion chips.
/// Receives onSubmit callback from HomeScreen — owns zero state.
library;

import 'package:flutter/material.dart';
import '../../../../../design_system/components/search_input.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_typography.dart';

// ── Suggestion data ────────────────────────────────────────────────────────

class _SuggestionItem {
  const _SuggestionItem({
    required this.label,
    required this.query,
    required this.icon,
    required this.archetype,
  });
  final String label;
  final String query;
  final IconData icon;
  final String archetype;
}

const List<_SuggestionItem> _suggestions = [
  _SuggestionItem(
    label: 'Sci-fi novels of all time',
    query: 'Top 10 sci-fi novels of all time',
    icon: Icons.book_outlined,
    archetype: 'MEDIA',
  ),
  _SuggestionItem(
    label: 'Indie games on Switch',
    query: 'Top 10 indie games on Switch',
    icon: Icons.sports_esports_outlined,
    archetype: 'MEDIA',
  ),
  _SuggestionItem(
    label: 'Specialty cafes in Tokyo',
    query: 'Top 10 specialty cafes in Tokyo',
    icon: Icons.location_on_outlined,
    archetype: 'GEOGRAPHIC',
  ),
  _SuggestionItem(
    label: 'Beaches in Southeast Asia',
    query: 'Top 10 beaches in Southeast Asia',
    icon: Icons.location_on_outlined,
    archetype: 'GEOGRAPHIC',
  ),
  _SuggestionItem(
    label: 'GPUs for machine learning',
    query: 'Top 10 GPUs for machine learning',
    icon: Icons.memory_outlined,
    archetype: 'TECHNICAL',
  ),
  _SuggestionItem(
    label: 'Programming languages 2024',
    query: 'Top 10 programming languages 2024',
    icon: Icons.memory_outlined,
    archetype: 'TECHNICAL',
  ),
];

Color _accentForArchetype(String archetype) => switch (archetype) {
      'MEDIA' => AppColors.accentMedia,
      'GEOGRAPHIC' => AppColors.accentGeographic,
      _ => AppColors.accentTechnical,
    };

// ── Component ──────────────────────────────────────────────────────────────

class IdleView extends StatelessWidget {
  const IdleView({super.key, required this.onSubmit});
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // Scrolls up when keyboard appears — no overflow
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 18),

          // ── Logo + app name — top left ────────────────────────────
          Row(
            children: [
              _LogoMark(),
              const SizedBox(width: 10),
              const Text(
                'Apex',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),

          const SizedBox(height: 96),

          // ── Hero title — centered ─────────────────────────────────
          const Center(
            child: Text(
              "What's worth\nranking today?",
              style: AppTypography.heroTitle,
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 32),

          // ── Search bar ────────────────────────────────────────────
          SearchInput(onSubmit: onSubmit),

          const SizedBox(height: 20),

          // ── Suggestions floating card ─────────────────────────────
          // ── Suggestions floating card ─────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.07),
                width: 0.5,
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'TRY ONE OF THESE',
                    style: AppTypography.eyebrow,
                  ),
                ),

                // Height sized to exactly 3 rows — 52dp per row
                SizedBox(
                  height: 52 * 3,
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _suggestions.length,
                    itemBuilder: (_, index) => SizedBox(
                      height: 52,
                      child: _SuggestionRow(
                        item: _suggestions[index],
                        onTap: () => onSubmit(_suggestions[index].query),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Suggestion row ─────────────────────────────────────────────────────────

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
    required this.item,
    required this.onTap,
  });

  final _SuggestionItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _accentForArchetype(item.archetype);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            // Archetype icon badge
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: accent.withValues(alpha: 0.15),
                  width: 0.5,
                ),
              ),
              child: Icon(
                item.icon,
                size: 15,
                color: accent.withValues(alpha: 0.8),
              ),
            ),

            const SizedBox(width: 12),

            // Label
            Expanded(
              child: Text(
                item.label,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),

            // Chevron
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 10,
              color: AppColors.textGhost,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Logo mark ──────────────────────────────────────────────────────────────

class _LogoMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGlobal.withValues(alpha: 0.12),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          'assets/images/logo.png',
          width: 36,
          height: 36,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
