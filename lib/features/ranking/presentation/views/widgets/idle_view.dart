/// Architectural role: State 1 — Idle UI.
/// Renders the hero title, search input, and suggestion chips.
/// Receives onSubmit callback from HomeScreen — owns zero state.
library;

import 'package:flutter/material.dart';
import '../../../../../design_system/components/search_input.dart';
import '../../../../../design_system/components/suggestion_chip.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_typography.dart';

const List<String> _suggestions = [
  'Top 10 sci-fi novels of all time',
  'Top 10 specialty cafes in Tokyo',
  'Top 10 GPUs for machine learning',
  'Top 10 indie games on Switch',
  'Top 10 beaches in Southeast Asia',
  'Top 10 programming languages 2024',
];

class IdleView extends StatelessWidget {
  const IdleView({super.key, required this.onSubmit});
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 18),
          _LogoMark(),
          const Spacer(),
          const Text(
            "What's worth\nranking today?",
            style: AppTypography.heroTitle,
          ),
          const SizedBox(height: 24),
          SearchInput(onSubmit: onSubmit),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) => ApexSuggestionChip(
                label: _suggestions[index],
                onTap: () => onSubmit(_suggestions[index]),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGlobal.withValues(alpha: 0.15),
            blurRadius: 30,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.asset(
          'assets/images/logo.png',
          width: 44,
          height: 44,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
