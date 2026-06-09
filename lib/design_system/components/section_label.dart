/// Architectural role: Shared design system primitive.
/// An uppercase section eyebrow label with bottom spacing.
/// Extracted from item_detail_screen where it appeared repeatedly as a
/// private class. Suitable for any content screen that structures data
/// into named sections (States 3 and 4).
library;

import 'package:flutter/material.dart';
import '../theme/app_typography.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.label, {super.key});

  /// The section heading text. Will be uppercased internally per Design Contract §02.
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.eyebrow,
      ),
    );
  }
}
