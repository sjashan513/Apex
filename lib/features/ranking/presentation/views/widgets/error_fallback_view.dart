/// Architectural role: State 6 — Error UI.
/// Renders contextual error with icon, diagnostic detail card, and actions.
/// Three subcategories: Timeout · Validation · Quota — each has distinct copy.
/// Red particle canvas is handled by ParticleCanvas(isError: true) in HomeScreen.
library;

import 'package:flutter/material.dart';
import '../../../../../core/exceptions/domain_exceptions.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_typography.dart';
import '../../../../../design_system/components/eyebrow_divider.dart';

// ── Error type definitions ─────────────────────────────────────────────────

class _ErrorContent {
  const _ErrorContent({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.primaryDetail,
    required this.primaryDetailDesc,
    required this.secondaryDetail,
    required this.secondaryDetailDesc,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final String primaryDetail;
  final String primaryDetailDesc;
  final String secondaryDetail;
  final String secondaryDetailDesc;
}

_ErrorContent _contentForError(Object error) {
  if (error is QuotaException) {
    return const _ErrorContent(
      eyebrow: 'engine out of gas',
      title: 'API quota reached\nor key invalid.',
      subtitle:
          'The ranking engine has no fuel left.\nVerify your API key configuration.',
      icon: Icons.key_off_rounded,
      primaryDetail: 'API key error',
      primaryDetailDesc:
          'The OpenAI key is either invalid, expired, or has exceeded its quota for this billing period.',
      secondaryDetail: 'What to do',
      secondaryDetailDesc:
          'Open your OpenAI dashboard, verify your key, and ensure billing is active. Then restart the app.',
    );
  }

  if (error is ValidationException) {
    return const _ErrorContent(
      eyebrow: 'schema error',
      title: 'The engine returned\nunstructured data.',
      subtitle:
          'Response failed schema validation.\nAttempting to restructure automatically.',
      icon: Icons.file_copy_outlined,
      primaryDetail: 'Schema validation failed',
      primaryDetailDesc:
          'The API returned a response that did not match the expected ranking structure. This is usually transient.',
      secondaryDetail: 'Auto-retry available',
      secondaryDetailDesc:
          'Apex will resubmit the exact payload with a stricter schema constraint on retry.',
    );
  }

  // Default — TimeoutException
  return const _ErrorContent(
    eyebrow: 'connection lost',
    title: 'The ranking engine\nis unreachable.',
    subtitle:
        'Connection timed out after 30 seconds.\nCheck your network and try again.',
    icon: Icons.wifi_off_rounded,
    primaryDetail: 'Request timed out',
    primaryDetailDesc:
        'The OpenAI API did not respond within the 30-second window. The connection was automatically aborted.',
    secondaryDetail: 'Possible causes',
    secondaryDetailDesc:
        'Slow network, high API load, or an unstable connection. No data was lost.',
  );
}

// ── Component ──────────────────────────────────────────────────────────────

class ErrorFallbackView extends StatelessWidget {
  const ErrorFallbackView({
    super.key,
    required this.error,
    required this.onRetry,
    required this.onClear,
  });

  final Object error;
  final VoidCallback onRetry;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final content = _contentForError(error);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),

          const SizedBox(height: 32),

          // Error icon with red glow
          _ErrorIconBadge(icon: content.icon),

          const SizedBox(height: 20),

          // Eyebrow with divider lines
          EyebrowDivider(label: content.eyebrow),

          const SizedBox(height: 14),

          // Title
          Text(
            content.title,
            style: AppTypography.screenTitle,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 10),

          // Subtitle
          Text(
            content.subtitle,
            style: AppTypography.body.copyWith(
              color: AppColors.textGhost,
              height: 1.65,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Detail card
          _DetailCard(content: content),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              // Retry — white primary
              Expanded(
                child: GestureDetector(
                  onTap: onRetry,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.accentGlobal,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.refresh_rounded,
                          color: AppColors.canvas,
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Retry query',
                          style: AppTypography.body.copyWith(
                            color: AppColors.canvas,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Home — ghost secondary
              Expanded(
                child: GestureDetector(
                  onTap: onClear,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.home_rounded,
                          color: AppColors.textSecondary,
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Home',
                          style: AppTypography.body.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Error icon badge ───────────────────────────────────────────────────────

class _ErrorIconBadge extends StatelessWidget {
  const _ErrorIconBadge({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.2),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withValues(alpha: 0.12),
            blurRadius: 20,
            spreadRadius: 8,
          ),
        ],
      ),
      child: Icon(
        icon,
        color: AppColors.error.withValues(alpha: 0.8),
        size: 32,
      ),
    );
  }
}

// ── Detail card ────────────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.content});
  final _ErrorContent content;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.access_time_rounded,
            label: content.primaryDetail,
            desc: content.primaryDetailDesc,
          ),
          const SizedBox(height: 10),
          Container(
              height: 0.5, color: AppColors.border.withValues(alpha: 0.3)),
          const SizedBox(height: 10),
          _DetailRow(
            icon: Icons.info_outline_rounded,
            label: content.secondaryDetail,
            desc: content.secondaryDetailDesc,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.desc,
  });

  final IconData icon;
  final String label;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon badge
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.error.withValues(alpha: 0.7),
            size: 14,
          ),
        ),

        const SizedBox(width: 10),

        // Text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: AppTypography.body.copyWith(
                  color: AppColors.textGhost,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
