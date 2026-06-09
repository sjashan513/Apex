/// Architectural role: Shared design system primitive.
/// A labelled horizontal divider with flanking hairlines.
/// Used on shell fallback screens (States 5 and 6) to contextualise the
/// primary message block. Replaces two identical private _EyebrowDivider
/// classes previously copy-pasted across humor_fallback_view and
/// error_fallback_view.
library;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class EyebrowDivider extends StatelessWidget {
  const EyebrowDivider({
    super.key,
    required this.label,
  });

  /// The label text. Will be uppercased internally per Design Contract §02.
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 0.5,
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            label.toUpperCase(),
            style: AppTypography.eyebrow.copyWith(
              color: AppColors.border,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 0.5,
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ],
    );
  }
}
