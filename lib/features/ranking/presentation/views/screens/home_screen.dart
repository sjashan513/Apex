/// Architectural role: State 1 coordinator screen.
/// Watches rankingNotifierProvider and delegates rendering to view widgets.
/// Contains zero UI of its own — pure state router.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../design_system/components/particle_canvas.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../domain/providers/ranking_providers.dart';
import '../../notifiers/ranking_notifier.dart';
import '../widgets/idle_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/humor_fallback_view.dart';
import '../widgets/error_fallback_view.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static String _lastQuery = '';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingState = ref.watch(rankingNotifierProvider);
    final archetype = ref.watch(detectedArchetypeProvider);
    final accentColor = AppColors.accentForArchetype(archetype);

    ref.listen(rankingNotifierProvider, (_, next) {
      next.whenData((state) {
        if (state is RankingResultState) {
          context.goNamed('ranking');
        }
      });
    });

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: [
          ParticleCanvas(
            isError: rankingState is AsyncError,
          ),
          SafeArea(
            child: rankingState.when(
              loading: () => LoadingView(accentColor: accentColor),
              error: (error, _) => ErrorFallbackView(
                error: error,
                onRetry: () => ref
                    .read(rankingNotifierProvider.notifier)
                    .retry(_lastQuery),
                onClear: () =>
                    ref.read(rankingNotifierProvider.notifier).reset(),
              ),
              data: (state) => switch (state) {
                IdleState() => IdleView(
                    onSubmit: (query) {
                      _lastQuery = query;
                      ref
                          .read(rankingNotifierProvider.notifier)
                          .submitQuery(query);
                    },
                  ),
                HumorState() => HumorFallbackView(
                    state: state,
                    onChipTap: (suggestion) {
                      _lastQuery = suggestion;
                      ref
                          .read(rankingNotifierProvider.notifier)
                          .submitQuery(suggestion);
                    },
                    onClear: () =>
                        ref.read(rankingNotifierProvider.notifier).reset(),
                  ),
                RankingResultState() => const SizedBox.shrink(),
              },
            ),
          ),
        ],
      ),
    );
  }
}
